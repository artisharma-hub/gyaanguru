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
        const SnackBar(content: Text('Please select a category first!')),
      );
      return;
    }
    context.go('/matchmaking?category=$_selectedCategory');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.14),
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
                // ── Header ──────────────────────────────────────────────────
                _HomeHeader(user: user),

                // ── Section label ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Category',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'Pick your battlefield',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_selectedCategory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
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
                        ),
                    ],
                  ),
                ),

                // ── Category grid ─────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
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
                            .slideY(begin: 0.18, end: 0);
                      },
                    ),
                  ),
                ),

                // ── CTAs ──────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Find Opponent — gradient button
                      GestureDetector(
                        onTap: _findOpponent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _selectedCategory.isEmpty
                                ? null
                                : const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: _selectedCategory.isEmpty ? AppColors.surfaceVariant : null,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _selectedCategory.isEmpty
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 18,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: _selectedCategory.isEmpty
                                    ? AppColors.textMuted
                                    : Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Find Opponent',
                                style: TextStyle(
                                  color: _selectedCategory.isEmpty
                                      ? AppColors.textMuted
                                      : Colors.white,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Challenge a Friend — outline
                      OutlinedButton.icon(
                        onPressed: () => context.go('/challenge/create'),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text(
                          'Challenge a Friend',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // space for floating nav
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

// ── Header widget ──────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final dynamic user;
  const _HomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox(height: 16);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.accent.withValues(alpha: 0.10),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: AvatarWidget(
              name: user.name,
              avatarColor: user.avatarColor,
              imagePath: user.avatarImagePath,
              radius: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.name.split(' ').first}!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (user.winStreak > 0)
                  Text(
                    '${user.winStreak} Win Streak',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Ready to battle?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
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
