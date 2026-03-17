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
    final user = ref.watch(authProvider).valueOrNull;
    final ac   = context.ac;
    final size = MediaQuery.sizeOf(context);

    final Color glowColor = _isWinner
        ? AppColors.gold
        : _isTie
            ? AppColors.accent
            : ac.surfaceVariant;

    final String headline = _isWinner
        ? 'Gyaan Guru!'
        : _isTie
            ? "It's a Tie!"
            : 'Better Luck!';

    final String subtext = _isWinner
        ? 'You dominated the quiz!'
        : _isTie
            ? 'Both players scored the same!'
            : 'Keep practicing — come back stronger!';

    // Rematch CTA gradient: primaryDark → primary → primaryLight for non-winners
    // goldDark → gold → goldLight for winners
    final List<Color> ctaColors = _isWinner
        ? [AppColors.goldDark, AppColors.gold, AppColors.goldLight]
        : [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF15172E), Color(0xFF1A1D38), Color(0xFF15172E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Background radial glow top-center ──────────────────────────
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      glowColor.withValues(alpha: _isWinner ? 0.22 : 0.09),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),

            // ── Bottom-right ambient glow ───────────────────────────────────
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.07),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // ── Confetti — 30 particles with rotation (winner only) ─────────
            if (_isWinner)
              ...List.generate(30, (i) {
                final rng = math.Random(i * 7 + 3);
                const colors = [
                  AppColors.primary,
                  AppColors.gold,
                  AppColors.correctGreen,
                  AppColors.accent,
                  AppColors.primaryLight,
                  AppColors.goldLight,
                  Colors.white,
                ];
                final particleColor = colors[i % colors.length];
                return Positioned(
                  top: -20,
                  left: rng.nextDouble() * size.width,
                  child: Container(
                    width: 6 + rng.nextDouble() * 9,
                    height: 6 + rng.nextDouble() * 9,
                    decoration: BoxDecoration(
                      color: particleColor,
                      borderRadius:
                          BorderRadius.circular(rng.nextBool() ? 10 : 2),
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
                    // ── Result icon with pulsing outer ring (winner) ──────
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost pulsing ring — winner only
                          if (_isWinner)
                            Container(
                              width: AppSizes.sp(context, 120),
                              height: AppSizes.sp(context, 120),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  width: 2,
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .scaleXY(
                                  begin: 0.85,
                                  end: 1.25,
                                  duration: 2200.ms,
                                  curve: Curves.easeInOut,
                                )
                                .fadeIn()
                                .then()
                                .fadeOut(duration: 700.ms),

                          // Inner pulsing ring — winner only
                          if (_isWinner)
                            Container(
                              width: AppSizes.sp(context, 108),
                              height: AppSizes.sp(context, 108),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.32),
                                  width: 1.5,
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
                                BoxShadow(
                                  color: glowColor.withValues(alpha: 0.20),
                                  blurRadius: 56,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isWinner
                                    ? Icons.emoji_events_rounded
                                    : _isTie
                                        ? Icons.handshake_rounded
                                        : Icons.trending_down_rounded,
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

                    // ── Headline — Nunito ExtraBold 28sp ─────────────────
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isWinner
                            ? AppColors.gold
                            : _isTie
                                ? AppColors.accent
                                : ac.textPrimary,
                        fontFamily: 'Nunito',
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
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 22),

                    // ── Score card: surface bg, gold border glow if winner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ac.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isWinner
                              ? AppColors.gold.withValues(alpha: 0.45)
                              : ac.border,
                          width: _isWinner ? 1.5 : 1,
                        ),
                        boxShadow: _isWinner
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                ),
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.08),
                                  blurRadius: 48,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'FINAL SCORE',
                            style: TextStyle(
                              color: ac.textMuted,
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
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

                    // ── Coins earned — animated fade + slideY ─────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.gold.withValues(alpha: 0.14),
                          AppColors.gold.withValues(alpha: 0.05),
                        ]),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.38),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'COINS EARNED',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CoinDisplay(coins: _displayedCoins, fontSize: 28),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: 10),

                    // ── Stats row: 3 tiles ────────────────────────────────
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: ac.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: ac.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatTile(
                              label: 'Total Coins',
                              value: '${user.coins}',
                              color: AppColors.gold,
                              icon: Icons.monetization_on_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: ac.border,
                            ),
                            _StatTile(
                              label: 'Win Streak',
                              value: _isWinner
                                  ? '${user.winStreak + 1}'
                                  : '0',
                              color: _isWinner ? AppColors.gold : ac.textSecondary,
                              icon: Icons.local_fire_department_rounded,
                              suffix: _isWinner ? ' 🔥' : '',
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: ac.border,
                            ),
                            _StatTile(
                              label: 'Total Wins',
                              value: _isWinner
                                  ? '${user.wins + 1}'
                                  : '${user.wins}',
                              color: AppColors.correctGreen,
                              icon: Icons.emoji_events_rounded,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 650.ms),

                    const SizedBox(height: 24),

                    // ── Rematch button: gradient primaryDark→primary→primaryLight, 56h
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
                            BoxShadow(
                              color: (_isWinner ? AppColors.gold : AppColors.primary)
                                  .withValues(alpha: 0.20),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
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

                    // ── Home button — outlined ────────────────────────────
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
                        side: BorderSide(
                          color: ac.border,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String suffix;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 5),
        Text(
          '$value$suffix',
          style: TextStyle(
            color: color,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: ac.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
