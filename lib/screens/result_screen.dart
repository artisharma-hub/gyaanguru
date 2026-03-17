import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/coin_display.dart';
import '../widgets/vs_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const ResultScreen({super.key, required this.data});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<int> _coinAnimation;
  int _displayedCoins = 0;

  bool get _isWinner => widget.data['isWinner'] as bool? ?? false;
  bool get _isTie    => widget.data['isTie']    as bool? ?? false;
  int  get _myScore  => widget.data['myScore']  as int?  ?? 0;
  int  get _opponentScore   => widget.data['opponentScore']   as int?    ?? 0;
  String get _opponentName  => widget.data['opponentName']    as String? ?? 'Opponent';
  String get _opponentAvatarColor => widget.data['opponentAvatarColor'] as String? ?? '#EA580C';
  int    get _coinsEarned   => widget.data['coinsEarned']     as int?    ?? 0;
  String get _category      => widget.data['category']        as String? ?? 'cricket';
  String get _myName        => widget.data['myName']          as String? ?? 'You';
  String get _myAvatarColor => widget.data['myAvatarColor']   as String? ?? '#FF4500';

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _coinAnimation = IntTween(begin: 0, end: _coinsEarned).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOut),
    )..addListener(() => setState(() => _displayedCoins = _coinAnimation.value));
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _coinController.forward();
    });
    // Refresh user data so coins/stats reflect the completed match
    Future.microtask(() {
      if (mounted) ref.read(authProvider.notifier).refreshUser();
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _rematch() {
    ref.read(matchProvider.notifier).reset();
    context.go('/matchmaking?category=$_category');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    final Color glowColor = _isWinner
        ? AppColors.gold
        : _isTie
            ? AppColors.accent
            : AppColors.surfaceVariant;

    final String headline = _isWinner
        ? 'Gyaan Guru! 🏆'
        : _isTie
            ? "It's a Tie! 🤝"
            : 'Better Luck Next Time';

    final String subtext = _isWinner
        ? 'You dominated the quiz!'
        : _isTie
            ? 'Both players scored the same!'
            : 'Keep practicing — come back stronger!';

    final List<Color> ctaColors = _isWinner
        ? [const Color(0xFFD97706), AppColors.gold, AppColors.goldLight]
        : [AppColors.primary, AppColors.primaryLight];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    glowColor.withValues(alpha: _isWinner ? 0.18 : 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // Confetti (winner only)
          if (_isWinner)
            ...List.generate(24, (i) {
              final rng = math.Random(i);
              return Positioned(
                top: -20,
                left: rng.nextDouble() * MediaQuery.of(context).size.width,
                child: Container(
                  width: 7 + rng.nextDouble() * 7,
                  height: 7 + rng.nextDouble() * 7,
                  decoration: BoxDecoration(
                    color: [
                      AppColors.gold,
                      AppColors.primaryLight,
                      AppColors.correctGreen,
                      AppColors.highlight,
                      AppColors.accent,
                    ][i % 5],
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate(delay: (rng.nextDouble() * 600).ms)
                    .slideY(
                      begin: 0,
                      end: 18,
                      duration: (1500 + rng.nextInt(1000)).ms,
                    )
                    .fadeOut(delay: 1200.ms, duration: 400.ms),
              );
            }),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ── Result icon ───────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isWinner
                              ? [const Color(0xFFD97706), AppColors.gold]
                              : _isTie
                                  ? [AppColors.accentDark, AppColors.accent]
                                  : [AppColors.surfaceVariant, AppColors.surfaceBright],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isWinner ? '🏆' : _isTie ? '🤝' : '😤',
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    )
                        .animate()
                        .scaleXY(begin: 0.5, end: 1.0, duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms),
                  ),

                  const SizedBox(height: 20),

                  // ── Headline ──────────────────────────────────────────────
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isWinner
                          ? AppColors.gold
                          : _isTie
                              ? AppColors.accent
                              : AppColors.textPrimary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 6),

                  Text(
                    subtext,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 28),

                  // ── Score card ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isWinner
                            ? AppColors.gold.withValues(alpha: 0.35)
                            : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: _isWinner
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                blurRadius: 20,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Final Score',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        VsCard(
                          myName: _myName,
                          myAvatarColor: _myAvatarColor,
                          myScore: _myScore,
                          opponentName: _opponentName,
                          opponentAvatarColor: _opponentAvatarColor,
                          opponentScore: _opponentScore,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 14),

                  // ── Coins earned ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.gold.withValues(alpha: 0.1),
                        AppColors.gold.withValues(alpha: 0.05),
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'COINS EARNED',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoinDisplay(coins: _displayedCoins, fontSize: 30),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 10),

                  // ── Stats row ─────────────────────────────────────────────
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatPill(
                            label: 'Total Coins',
                            value: '${user.coins}',
                            color: AppColors.gold,
                          ),
                          Container(width: 1, height: 32, color: AppColors.border),
                          _StatPill(
                            label: 'Win Streak',
                            value: _isWinner ? '${user.winStreak + 1} 🔥' : '0 🔥',
                            color: _isWinner ? AppColors.gold : AppColors.textSecondary,
                          ),
                          Container(width: 1, height: 32, color: AppColors.border),
                          _StatPill(
                            label: 'Total Wins',
                            value: _isWinner ? '${user.wins + 1}' : '${user.wins}',
                            color: AppColors.correctGreen,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 650.ms),

                  const SizedBox(height: 28),

                  // ── Rematch button ────────────────────────────────────────
                  GestureDetector(
                    onTap: _rematch,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: ctaColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (_isWinner ? AppColors.gold : AppColors.primary)
                                .withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'REMATCH',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 750.ms)
                      .fadeIn(duration: 400.ms)
                      .scaleXY(begin: 0.92, end: 1.0, curve: Curves.elasticOut),

                  const SizedBox(height: 12),

                  // ── Home button ───────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(matchProvider.notifier).reset();
                      context.go('/home');
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'Home',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ).animate(delay: 850.ms).fadeIn(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
