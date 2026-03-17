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
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Background glow top-right — primary
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.20),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Background glow bottom-left — accent
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Background glow center-bottom — subtle purple
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      AppColors.primaryDark.withValues(alpha: 0.14),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ─────────────────────────────────────────
                  if (user != null) _HomeHeader(user: user),

                  // ── Stats row ───────────────────────────────────────────
                  if (user != null) _StatsBar(user: user),

                  // ── Section label ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Category',
                              style: TextStyle(
                                color: ac.textPrimary,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: AppSizes.sp(context, 20),
                              ),
                            ),
                            Text(
                              'Pick your battlefield',
                              style: TextStyle(
                                color: ac.textSecondary,
                                fontFamily: 'Nunito',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_selectedCategory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Text(
                              '1 selected',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.85, end: 1.0, curve: Curves.elasticOut),
                      ],
                    ),
                  ),

                  // ── Category grid ────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final ratio = (constraints.maxWidth / 2 - 10) /
                            ((constraints.maxHeight - 36) / 3).clamp(100.0, 200.0);
                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: ratio.clamp(0.78, 1.1),
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            return _CategoryCardWrapper(
                              categoryKey: cat,
                              isSelected: _selectedCategory == cat,
                              onTap: () => setState(() => _selectedCategory = cat),
                            )
                                .animate(delay: (i * 60).ms)
                                .fadeIn(duration: 320.ms)
                                .slideY(begin: 0.18, end: 0, curve: Curves.easeOut);
                          },
                        );
                      }),
                    ),
                  ),

                  // ── CTA buttons ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        // Find Opponent — gradient with glow
                        _FindOpponentButton(
                          enabled: _selectedCategory.isNotEmpty,
                          onTap: _findOpponent,
                        ),
                        const SizedBox(height: 10),

                        // Challenge a Friend — neon outline
                        _ChallengeButton(
                          onTap: () => context.go('/challenge/create'),
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
      ),
    );
  }
}

// ── Category card wrapper with scale-bounce selection ─────────────────────────
class _CategoryCardWrapper extends StatefulWidget {
  final String categoryKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCardWrapper({
    required this.categoryKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryCardWrapper> createState() => _CategoryCardWrapperState();
}

class _CategoryCardWrapperState extends State<_CategoryCardWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  static const _categoryColors = {
    'cricket':   AppColors.cricket,
    'bollywood': AppColors.bollywood,
    'gk':        AppColors.gk,
    'math':      AppColors.math,
    'science':   AppColors.science,
    'hindi':     AppColors.hindi,
  };

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.91), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.91, end: 1.06)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 70),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(_CategoryCardWrapper old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColors[widget.categoryKey] ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _bounceAnim.value : 1.0,
          child: child,
        );
      },
      child: Stack(
        children: [
          CategoryCard(
            categoryKey: widget.categoryKey,
            isSelected: widget.isSelected,
            onTap: () {
              widget.onTap();
            },
          ),
          // Glow ring when selected
          if (widget.isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.75),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.40),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.20),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
            ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final dynamic user;
  const _HomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: AvatarWidget(
              name: user.name,
              avatarColor: user.avatarColor,
              imagePath: user.avatarImagePath,
              radius: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Greeting + streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, ${user.name.split(' ').first}! 👋',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.sp(context, 22),
                  ),
                ),
                const SizedBox(height: 2),
                if (user.winStreak > 0)
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${user.winStreak} Win Streak',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontFamily: 'Nunito',
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
                      fontFamily: 'Nunito',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Coin display — gold accent
          CoinDisplay(coins: user.coins, fontSize: 16),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: -0.12, end: 0, curve: Curves.easeOut);
  }
}

// ── Stats bar ──────────────────────────────────────────────────────────────────
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
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: ac.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border2,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            icon: Icons.sports_esports_rounded,
            label: 'Matches',
            value: '${user.totalMatches}',
            color: AppColors.accent,
          ),
          _Divider(),
          _StatTile(
            icon: Icons.emoji_events_rounded,
            label: 'Wins',
            value: '${user.wins}',
            color: AppColors.gold,
          ),
          _Divider(),
          _StatTile(
            icon: Icons.show_chart_rounded,
            label: 'Win Rate',
            value: '$winRate%',
            color: AppColors.correctGreen,
          ),
          _Divider(),
          _StatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Best Streak',
            value: '${user.bestStreak}',
            color: AppColors.highlight,
          ),
        ],
      ),
    )
        .animate(delay: 160.ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border2,
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: ac.textMuted,
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Find Opponent Button ───────────────────────────────────────────────────────
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
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : ac.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _pressed ? 0.25 : 0.45),
                      blurRadius: _pressed ? 10 : 22,
                      offset: Offset(0, _pressed ? 2 : 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: _pressed ? 20 : 40,
                      offset: Offset(0, _pressed ? 4 : 12),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: widget.enabled
                    ? Colors.white
                    : ac.textMuted,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Find Opponent',
                style: TextStyle(
                  color: widget.enabled ? Colors.white : ac.textMuted,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Challenge a Friend button ─────────────────────────────────────────────────
class _ChallengeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChallengeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.share_rounded, size: 18),
      label: const Text(
        'Challenge a Friend',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      ),
    );
  }
}
