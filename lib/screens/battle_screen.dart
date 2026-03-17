import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/match_state.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
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
  DateTime? _questionStartTime;

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
    setState(() {
      _timeLeft = _questionDuration;
      _timerActive = true;
      _questionStartTime = DateTime.now();
    });
    _questionTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft -= 0.05;
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
    final matchState     = ref.watch(matchProvider);
    final user           = ref.watch(authProvider).valueOrNull;
    final categoryColor  = _categoryColors[widget.category] ?? AppColors.primary;
    final timerFraction  = (_timeLeft / _questionDuration).clamp(0.0, 1.0);

    ref.listen(matchProvider, (prev, next) {
      if (next.phase == MatchPhase.playing &&
          (prev?.currentQuestionIndex != next.currentQuestionIndex ||
              prev?.phase != MatchPhase.playing)) {
        _startTimer();
      }
      if (next.phase == MatchPhase.finished && !_navigated) {
        _navigated = true;
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          router.go('/result', extra: {
            'isWinner':              next.isWinner,
            'isTie':                 next.isTie,
            'myScore':               next.myScore,
            'opponentScore':         next.opponentScore,
            'opponentName':          next.opponentName ?? 'Opponent',
            'opponentAvatarColor':   next.opponentAvatarColor ?? '#FF4500',
            'coinsEarned':           next.coinsEarned,
            'matchId':               next.matchId,
            'category':              widget.category,
            'myName':                user?.name ?? 'You',
            'myAvatarColor':         user?.avatarColor ?? '#FF4500',
          });
        });
      }
    });

    if (matchState.phase == MatchPhase.countdown) {
      return _CountdownScreen(countdown: matchState.countdown);
    }

    if (matchState.phase == MatchPhase.error) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.wrongRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: AppColors.wrongRed, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                matchState.errorMessage ?? 'Connection lost',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final q = matchState.currentQuestion;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Category color top accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withValues(alpha: 0),
                    categoryColor,
                    categoryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: q == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                    ),
                  )
                : Column(
                    children: [
                      // ── Score header ──────────────────────────────────────
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppColors.border, width: 1),
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

                      // ── Q indicator + time ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Row(
                          children: [
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Q${matchState.currentQuestionIndex + 1} / 10',
                                style: TextStyle(
                                  color: categoryColor,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Timer text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _timerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _timerColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_rounded,
                                      color: _timerColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_timeLeft.toStringAsFixed(1)}s',
                                    style: TextStyle(
                                      color: _timerColor,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Timer progress bar ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(3),
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
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _timerColor.withValues(alpha: 0.5),
                                          blurRadius: 6,
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

                      // ── Question text ─────────────────────────────────────
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: categoryColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                q.questionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                  height: 1.4,
                                ),
                              )
                                  .animate(key: ValueKey(q.id))
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ),
                          ),
                        ),
                      ),

                      // ── Answer buttons ────────────────────────────────────
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.0,
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
    );
  }
}

// ── Countdown screen ────────────────────────────────────────────────────────────
class _CountdownScreen extends StatelessWidget {
  final int countdown;
  const _CountdownScreen({required this.countdown});

  @override
  Widget build(BuildContext context) {
    final isGo = countdown <= 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Glow behind number
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  (isGo ? AppColors.correctGreen : AppColors.primary)
                      .withValues(alpha: 0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Battle starts in',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
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
                      begin: 1.5,
                      end: 1.0,
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
