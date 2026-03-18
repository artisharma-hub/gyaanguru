import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/vs_card.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/sound_tap.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';

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
                              questionCount: _questionCounts[cat],
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
  final int? questionCount;

  const _CategoryCardWrapper({
    required this.categoryKey,
    required this.isSelected,
    required this.onTap,
    this.questionCount,
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
              SoundService().click();
              widget.onTap();
            },
            questionCount: widget.questionCount,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.name.split(' ').first}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: AppSizes.sp(context, 26),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.winStreak > 0
                      ? '🔥 ${user.winStreak}-game win streak!'
                      : "Let's make this day productive",
                  style: TextStyle(
                    color: user.winStreak > 0
                        ? AppColors.gold
                        : ac.textSecondary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Avatar with tap
          SoundTap(
            onTap: () => context.go('/profile'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: AvatarWidget(
                name: user.name,
                avatarColor: user.avatarColor,
                imagePath: user.avatarImagePath,
                radius: 26,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: -0.10, end: 0, curve: Curves.easeOut);
  }
}

// ── Stats bar — Ranking + Points pills ────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final dynamic user;
  const _StatsBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          // Ranking pill
          Expanded(
            child: _StatPill(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.gold,
              label: 'Ranking',
              value: '${user.totalMatches > 0 ? user.wins : 0}',
              gradientColors: [
                AppColors.gold.withValues(alpha: 0.18),
                AppColors.goldDark.withValues(alpha: 0.08),
              ],
              borderColor: AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 12),
          // Points pill
          Expanded(
            child: _StatPill(
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.primaryLight,
              label: 'Points',
              value: '${user.coins}',
              gradientColors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.primaryDark.withValues(alpha: 0.08),
              ],
              borderColor: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 150.ms)
        .fadeIn(duration: 360.ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOut);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final List<Color> gradientColors;
  final Color borderColor;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.gradientColors,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
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
              SoundService().click();
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
    return SoundTap(
      onTap: onTap,
      child: OutlinedButton.icon(
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
    ),
    );
  }
}
