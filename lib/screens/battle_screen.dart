import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/match_state.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../services/sound_service.dart';
import '../widgets/answer_button.dart';
import '../widgets/vs_card.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String category;
  const BattleScreen({super.key, required this.matchId, required this.category});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  Timer? _questionTimer;
  double _timeLeft = 10.0;
  bool _timerActive = false;
  bool _navigated = false;
  bool _timerWarnPlayed = false;
  DateTime? _questionStartTime;
  final _sound = SoundService();

  static const _questionDuration = 10.0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    if (widget.matchId == 'bot') return;
    final token = await ref.read(authProvider.notifier).getToken();
    if (!mounted || token == null) return;
    ref.read(matchProvider.notifier).connectBattle(widget.matchId, token);
  }

  void _startTimer() {
    _questionTimer?.cancel();
    _timerWarnPlayed = false;
    setState(() {
      _timeLeft = _questionDuration;
      _timerActive = true;
      _questionStartTime = DateTime.now();
    });
    _questionTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 3 && !_timerWarnPlayed) {
          _timerWarnPlayed = true;
          _sound.timerWarning();
        }
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _timerActive = false;
          t.cancel();
          final q = ref.read(matchProvider).currentQuestion;
          if (q != null) {
            ref.read(matchProvider.notifier).submitAnswer(q.id, '', _questionDuration);
          }
        }
      });
    });
  }

  void _onAnswerTap(String option) {
    if (!_timerActive) return;
    _sound.click();
    _questionTimer?.cancel();
    setState(() => _timerActive = false);
    final elapsed = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0
        : _questionDuration;
    final q = ref.read(matchProvider).currentQuestion;
    if (q != null) {
      ref.read(matchProvider.notifier).submitAnswer(q.id, option, elapsed);
    }
  }

  Color get _timerColor {
    if (_timeLeft <= 3) return AppColors.timerDanger;
    if (_timeLeft <= 5) return AppColors.gold;
    return AppColors.timerSafe;
  }

  @override
  Widget build(BuildContext context) {
    final matchState    = ref.watch(matchProvider);
    final user          = ref.watch(authProvider).valueOrNull;
    final categoryColor = _categoryColors[widget.category] ?? AppColors.primary;
    final ac            = context.ac;

    ref.listen(matchProvider, (prev, next) {
      if (next.phase == MatchPhase.playing &&
          (prev?.currentQuestionIndex != next.currentQuestionIndex ||
              prev?.phase != MatchPhase.playing)) {
        _startTimer();
      }
      if (prev?.correctOption == null && next.correctOption != null) {
        final wasCorrect = next.selectedOption == next.correctOption;
        if (wasCorrect) {
          _sound.correct();
        } else {
          _sound.wrong();
        }
      }
      if (next.phase == MatchPhase.finished && !_navigated) {
        _navigated = true;
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          router.go('/result', extra: {
            'isWinner':             next.isWinner,
            'isTie':                next.isTie,
            'myScore':              next.myScore,
            'opponentScore':        next.opponentScore,
            'opponentName':         next.opponentName ?? 'Opponent',
            'opponentAvatarColor':  next.opponentAvatarColor ?? '#FF4500',
            'coinsEarned':          next.coinsEarned,
            'matchId':              next.matchId,
            'category':             widget.category,
            'myName':               user?.name ?? 'You',
            'myAvatarColor':        user?.avatarColor ?? '#FF4500',
          });
        });
      }
    });

    if (matchState.phase == MatchPhase.countdown) {
      return _CountdownScreen(countdown: matchState.countdown);
    }

    if (matchState.phase == MatchPhase.error) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF15172E), Color(0xFF1A1D38), Color(0xFF15172E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.wrongRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.wrongRed.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wrongRed.withValues(alpha: 0.30),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      color: AppColors.wrongRed, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  matchState.errorMessage ?? 'Connection lost',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q             = matchState.currentQuestion;
    final timerFraction = (_timeLeft / _questionDuration).clamp(0.0, 1.0);
    final isDanger      = _timeLeft <= 3;

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
            // ── Soft category-colored radial glow top-left ────────────────
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    categoryColor.withValues(alpha: 0.14),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // ── Soft secondary glow bottom-right ──────────────────────────
            Positioned(
              bottom: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // ── Top accent bar — 4px category-colored with glow ───────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0),
                      categoryColor,
                      categoryColor.withValues(alpha: 0.8),
                      categoryColor.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: q == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(categoryColor),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading question...',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // ── VS Score header ──────────────────────────────
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: ac.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.20),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: VsCard(
                            myName: user?.name ?? 'You',
                            myAvatarColor: user?.avatarColor ?? '#FF4500',
                            myScore: matchState.myScore,
                            opponentName: matchState.opponentName ?? 'Opponent',
                            opponentAvatarColor:
                                matchState.opponentAvatarColor ?? '#EA580C',
                            opponentScore: matchState.opponentScore,
                          ),
                        ),

                        // ── Q indicator badge + circular arc timer ────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Category + question badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.18),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: categoryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: categoryColor.withValues(alpha: 0.60),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      '${widget.category.toUpperCase()}  ·  Q${matchState.currentQuestionIndex + 1}/10',
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Circular arc timer
                              _CircularTimer(
                                fraction: timerFraction,
                                color: _timerColor,
                                timeLeft: _timeLeft,
                              ),
                            ],
                          ),
                        ),

                        // ── Secondary linear progress bar ─────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: ac.surfaceVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 50),
                                      width: constraints.maxWidth * timerFraction,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _timerColor.withValues(alpha: 0.7),
                                            _timerColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _timerColor.withValues(alpha: 0.50),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // ── Question card ──────────────────────────────────
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: ac.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDanger
                                      ? AppColors.timerDanger.withValues(alpha: 0.55)
                                      : AppColors.primary.withValues(alpha: 0.15),
                                  width: isDanger ? 2 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDanger
                                            ? AppColors.timerDanger
                                            : AppColors.primary)
                                        .withValues(alpha: isDanger ? 0.30 : 0.12),
                                    blurRadius: isDanger ? 24 : 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  q.questionText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ac.textPrimary,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppSizes.sp(context, 22),
                                    height: 1.4,
                                  ),
                                )
                                    .animate(key: ValueKey(q.id))
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.08, end: 0),
                              ),
                            ),
                          ),
                        ),

                        // ── Answer buttons 2×2 grid ────────────────────────
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.9,
                              physics: const NeverScrollableScrollPhysics(),
                              children: ['A', 'B', 'C', 'D'].map((opt) {
                                final label = q.options[opt] ?? '';
                                AnswerState ansState = AnswerState.none;
                                final resultKnown = matchState.correctOption != null;
                                if (resultKnown) {
                                  if (opt == matchState.correctOption) {
                                    ansState = AnswerState.correct;
                                  } else if (opt == matchState.selectedOption) {
                                    ansState = AnswerState.wrong;
                                  }
                                } else if (opt == matchState.selectedOption) {
                                  ansState = AnswerState.selected;
                                }
                                return AnswerButton(
                                  label: label,
                                  option: opt,
                                  onTap: _timerActive &&
                                          matchState.selectedOption == null
                                      ? () => _onAnswerTap(opt)
                                      : null,
                                  state: ansState,
                                );
                              }).toList(),
                            ),
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

// ── Circular Arc Timer ──────────────────────────────────────────────────���─────
class _CircularTimer extends StatelessWidget {
  final double fraction;
  final Color color;
  final double timeLeft;

  const _CircularTimer({
    required this.fraction,
    required this.color,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = timeLeft <= 3;
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _ArcTimerPainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            timeLeft <= 0 ? '0' : timeLeft.ceil().toString(),
            style: TextStyle(
              color: color,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.50),
                  blurRadius: 8,
                ),
              ],
            ),
          )
              .animate(
                key: ValueKey(timeLeft.ceil()),
                onPlay: isDanger ? (c) => c.repeat(reverse: true) : null,
              )
              .scaleXY(
                begin: isDanger ? 1.0 : 0.7,
                end: isDanger ? 1.15 : 1.0,
                duration: isDanger ? 400.ms : 200.ms,
                curve: Curves.elasticOut,
              ),
        ),
      ),
    );
  }
}

class _ArcTimerPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _ArcTimerPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Glow layer (soft outer glow)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      glowPaint,
    );

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcTimerPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ── Countdown screen ──────────────────────────────────────────────────────────
class _CountdownScreen extends StatelessWidget {
  final int countdown;
  const _CountdownScreen({required this.countdown});

  @override
  Widget build(BuildContext context) {
    final isGo = countdown <= 0;
    final ac   = context.ac;
    final glowColor = isGo ? AppColors.correctGreen : AppColors.primary;

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
            // Subtle corner glow top-left
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Subtle corner glow bottom-right
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Central radial glow
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    glowColor.withValues(alpha: 0.20),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Battle starts in',
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: isGo
                          ? [AppColors.correctGreen, const Color(0xFF34D399)]
                          : [AppColors.primary, AppColors.primaryLight],
                    ).createShader(b),
                    child: Text(
                      isGo ? 'GO!' : '$countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 110,
                        height: 1,
                      ),
                    ),
                  )
                      .animate(key: ValueKey(countdown))
                      .scaleXY(
                        begin: 1.6,
                        end: 1.0,
                        duration: 450.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
