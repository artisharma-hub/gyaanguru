import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/coin_display.dart';
import '../widgets/vs_card.dart';
import '../widgets/app_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = '';
  int _navIndex = 0;

  static const _categories = [
    'cricket', 'bollywood', 'gk', 'math', 'science', 'hindi',
  ];

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 1: context.go('/daily');       break;
      case 2: context.go('/leaderboard'); break;
      case 3: context.go('/profile');     break;
    }
  }

  void _findOpponent() {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pick a category first!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    context.go('/matchmaking?category=$_selectedCategory');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final ac   = context.ac;

    return Scaffold(
      backgroundColor: ac.background,
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Stack(
        children: [
          // Background glow top-right
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: context.isDark ? 0.18 : 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Background glow bottom-left
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: context.isDark ? 0.10 : 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ───────────────────────────────────────────
                if (user != null) _HomeHeader(user: user),

                // ── Stats bar ─────────────────────────────────────────────
                if (user != null)
                  _StatsBar(user: user),

                // ── Section label ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Category',
                            style: TextStyle(
                              color: ac.textPrimary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Pick your battlefield',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_selectedCategory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            '1 selected',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Category grid ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final ratio = (constraints.maxWidth / 2 - 10) /
                          ((constraints.maxHeight - 36) / 3).clamp(100.0, 200.0);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: ratio.clamp(0.78, 1.1),
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          return CategoryCard(
                            categoryKey: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () => setState(() => _selectedCategory = cat),
                          )
                              .animate(delay: (i * 55).ms)
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: 0.15, end: 0);
                        },
                      );
                    }),
                  ),
                ),

                // ── CTA buttons ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      // Find Opponent — gradient with bounce
                      _FindOpponentButton(
                        enabled: _selectedCategory.isNotEmpty,
                        onTap: _findOpponent,
                      ),
                      const SizedBox(height: 10),

                      // Challenge a Friend — outline
                      OutlinedButton.icon(
                        onPressed: () => context.go('/challenge/create'),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text(
                          'Challenge a Friend',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 84), // nav bar clearance
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final dynamic user;
  const _HomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ac.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
                alpha: context.isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: AvatarWidget(
              name: user.name,
              avatarColor: user.avatarColor,
              imagePath: user.avatarImagePath,
              radius: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.name.split(' ').first}! 👋',
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.sp(context, 16),
                  ),
                ),
                if (user.winStreak > 0)
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${user.winStreak} Win Streak',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Ready to battle?',
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          CoinDisplay(coins: user.coins, fontSize: 16),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final dynamic user;
  const _StatsBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final winRate = user.totalMatches > 0
        ? (user.wins / user.totalMatches * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: ac.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            icon: Icons.sports_esports_rounded,
            label: 'Matches',
            value: '${user.totalMatches}',
            color: AppColors.accent,
          ),
          Container(width: 1, height: 28, color: ac.border),
          _MiniStat(
            icon: Icons.emoji_events_rounded,
            label: 'Wins',
            value: '${user.wins}',
            color: AppColors.gold,
          ),
          Container(width: 1, height: 28, color: ac.border),
          _MiniStat(
            icon: Icons.show_chart_rounded,
            label: 'Win Rate',
            value: '$winRate%',
            color: AppColors.correctGreen,
          ),
          Container(width: 1, height: 28, color: ac.border),
          _MiniStat(
            icon: Icons.local_fire_department_rounded,
            label: 'Best Streak',
            value: '${user.bestStreak}',
            color: AppColors.highlight,
          ),
        ],
      ),
    )
        .animate(delay: 150.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: ac.textMuted,
              fontFamily: 'Poppins',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Find Opponent Button ──────────────────────────────────────────────────────
class _FindOpponentButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _FindOpponentButton({required this.enabled, required this.onTap});

  @override
  State<_FindOpponentButton> createState() => _FindOpponentButtonState();
}

class _FindOpponentButtonState extends State<_FindOpponentButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) {
        setState(() => _pressed = false);
        widget.onTap();
      } : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: widget.enabled
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: widget.enabled ? null : ac.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: _pressed ? 0.25 : 0.45),
                    blurRadius: _pressed ? 8 : 20,
                    offset: Offset(0, _pressed ? 2 : 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: widget.enabled ? Colors.white : ac.textMuted,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Find Opponent',
              style: TextStyle(
                color: widget.enabled ? Colors.white : ac.textMuted,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
