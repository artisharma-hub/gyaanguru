import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/sound_tap.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = '';
  int _navIndex = 0;
  Map<String, int> _questionCounts = {};

  static const _categories = [
    'cricket', 'bollywood', 'gk', 'math', 'science', 'hindi',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService().getCategories();
      final counts = <String, int>{};
      for (final c in cats) {
        counts[c['key'] as String] = (c['count'] as num).toInt();
      }
      if (mounted) setState(() => _questionCounts = counts);
    } catch (_) {}
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    context.go('/matchmaking?category=$_selectedCategory');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Stack(
        children: [
          // ── Radial gradient background ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.30),
                radius: 1.25,
                colors: [
                  Color(0xFFB06CFF), // light purple center glow
                  Color(0xFF7B4DFF), // purple mid
                  Color(0xFF3D2C8D), // deep blue-purple
                  Color(0xFF0A0616), // dark outer edge
                ],
                stops: [0.0, 0.30, 0.62, 1.0],
              ),
            ),
          ),

          // ── Soft accent orb — top-right pink tint ──────────────────
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6CAB).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Soft accent orb — bottom-left purple tint ──────────────
          Positioned(
            bottom: 80,
            left: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                if (user != null) _HomeHeader(user: user),

                // ── Stats row ─────────────────────────────────────────
                if (user != null) _StatsBar(user: user),

              // ── Section label ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Row(
                  children: [
                    const Text(
                      "Let's play",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          '1 selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ).animate().fadeIn(duration: 180.ms),
                  ],
                ),
              ),

              // ── Category grid ────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AlignedGridView.count(
                    physics: const BouncingScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      return CategoryCard(
                        categoryKey: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () {
                          SoundService().click();
                          setState(() => _selectedCategory = cat);
                        },
                        questionCount: _questionCounts[cat],
                      )
                          .animate(delay: (i * 50).ms)
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
                    },
                  ),
                ),
              ),

              // ── CTA Buttons ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    _FindOpponentButton(
                      enabled: _selectedCategory.isNotEmpty,
                      onTap: _findOpponent,
                    ),
                    const SizedBox(height: 10),
                    _ChallengeButton(onTap: () => context.go('/challenge/create')),
                    const SizedBox(height: 80),
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

// ── Header ──────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final dynamic user;
  const _HomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.name.split(' ').first} ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Text(
                  user.winStreak > 0
                      ? ' ${user.winStreak}-game win streak!'
                      : "Ready to battle? Pick a category!",
                  style: TextStyle(
                    color: user.winStreak > 0
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.60),
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SoundTap(
            onTap: () => context.go('/profile'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ── Stats bar ────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final dynamic user;
  const _StatsBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.emoji_events_rounded,
              gradientColors: const [AppColors.goldDark, AppColors.gold],
              label: 'Wins',
              value: '${user.wins}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              icon: Icons.stars_rounded,
              gradientColors: const [AppColors.primaryDark, AppColors.primaryLight],
              label: 'Points',
              value: '${user.coins}',
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 300.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.gradientColors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.40),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Find Opponent Button ─────────────────────────────────────────────────────
class _FindOpponentButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _FindOpponentButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoundTap(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(26),
          border: enabled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.25),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Find Opponent',
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.25),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Challenge a Friend Button ─────────────────────────────────────────────────
class _ChallengeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChallengeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoundTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, color: Colors.white.withValues(alpha: 0.70), size: 18),
            const SizedBox(width: 8),
            Text(
              'Challenge a Friend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
