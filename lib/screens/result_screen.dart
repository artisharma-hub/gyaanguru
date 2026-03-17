import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../services/sound_service.dart';
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (_isWinner) {
          SoundService().victory();
        } else {
          SoundService().defeat();
        }
      }
    });
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
    final user     = ref.watch(authProvider).valueOrNull;
    final ac       = context.ac;
    final size     = MediaQuery.sizeOf(context);

    final Color glowColor = _isWinner
        ? AppColors.gold
        : _isTie
            ? AppColors.accent
            : ac.surfaceVariant;

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
      backgroundColor: ac.background,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    glowColor.withValues(alpha: _isWinner ? 0.20 : 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // Confetti for winner (more particles)
          if (_isWinner)
            ...List.generate(36, (i) {
              final rng = math.Random(i * 7 + 3);
              final colors = [
                AppColors.gold,
                AppColors.primaryLight,
                AppColors.correctGreen,
                AppColors.highlight,
                AppColors.accent,
                AppColors.goldLight,
                Colors.white,
              ];
              return Positioned(
                top: -20,
                left: rng.nextDouble() * size.width,
                child: Container(
                  width: 6 + rng.nextDouble() * 9,
                  height: 6 + rng.nextDouble() * 9,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    borderRadius: BorderRadius.circular(
                        rng.nextBool() ? 10 : 2),
                  ),
                )
                    .animate(delay: (rng.nextDouble() * 800).ms)
                    .slideY(
                      begin: 0,
                      end: 22,
                      duration: (1400 + rng.nextInt(1200)).ms,
                      curve: Curves.easeIn,
                    )
                    .rotate(
                      begin: 0,
                      end: rng.nextDouble() * 2,
                      duration: (1400 + rng.nextInt(1200)).ms,
                    )
                    .fadeOut(delay: 1400.ms, duration: 400.ms),
              );
            }),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Result icon ─────────────────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring (winner only)
                        if (_isWinner)
                          Container(
                            width: AppSizes.sp(context, 108),
                            height: AppSizes.sp(context, 108),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scaleXY(
                                begin: 0.9,
                                end: 1.15,
                                duration: 1800.ms,
                                curve: Curves.easeInOut,
                              )
                              .fadeIn()
                              .then()
                              .fadeOut(duration: 600.ms),
                        // Icon circle
                        Container(
                          width: AppSizes.sp(context, 88),
                          height: AppSizes.sp(context, 88),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isWinner
                                  ? [const Color(0xFFD97706), AppColors.gold]
                                  : _isTie
                                      ? [AppColors.accentDark, AppColors.accent]
                                      : [ac.surfaceVariant, ac.surfaceBright],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.45),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isWinner
                                  ? Icons.emoji_events_rounded
                                  : _isTie
                                      ? Icons.handshake_rounded
                                      : Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        )
                            .animate()
                            .scaleXY(
                              begin: 0.4,
                              end: 1.0,
                              duration: 700.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Headline ────────────────────────────────────────────
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isWinner
                          ? AppColors.gold
                          : _isTie
                              ? AppColors.accent
                              : ac.textPrimary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: AppSizes.sp(context, 28),
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
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 22),

                  // ── Score card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isWinner
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : ac.border,
                        width: 1,
                      ),
                      boxShadow: _isWinner
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.12),
                                blurRadius: 24,
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: context.isDark ? 0.2 : 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'FINAL SCORE',
                          style: TextStyle(
                            color: ac.textMuted,
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
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

                  const SizedBox(height: 12),

                  // ── Coins earned ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.gold.withValues(alpha: 0.12),
                        AppColors.gold.withValues(alpha: 0.05),
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'COINS EARNED',
                          style: TextStyle(
                            color: ac.textSecondary,
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CoinDisplay(coins: _displayedCoins, fontSize: 28),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 10),

                  // ── Stats row ───────────────────────────────────────────
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: ac.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ac.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatPill(
                            label: 'Total Coins',
                            value: '${user.coins}',
                            color: AppColors.gold,
                          ),
                          Container(width: 1, height: 32, color: ac.border),
                          _StatPill(
                            label: 'Win Streak',
                            value: _isWinner ? '${user.winStreak + 1}🔥' : '0',
                            color: _isWinner ? AppColors.gold : ac.textSecondary,
                          ),
                          Container(width: 1, height: 32, color: ac.border),
                          _StatPill(
                            label: 'Total Wins',
                            value: _isWinner ? '${user.wins + 1}' : '${user.wins}',
                            color: AppColors.correctGreen,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 650.ms),

                  const SizedBox(height: 24),

                  // ── Rematch button ──────────────────────────────────────
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
                            blurRadius: 20,
                            offset: const Offset(0, 6),
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
                              fontFamily: 'Poppins',
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

                  // ── Home button ─────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(matchProvider.notifier).reset();
                      context.go('/home');
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'Home',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: ac.border),
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
    final ac = context.ac;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: ac.textSecondary,
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
