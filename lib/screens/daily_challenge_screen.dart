import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../models/question_model.dart';
import '../services/api_service.dart';
import '../widgets/answer_button.dart';
import '../widgets/coin_display.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  bool _started = false;
  bool _submitted = false;
  List<QuestionModel> _questions = [];
  String _date = '';
  int _currentIndex = 0;
  double _timeLeft = 10.0;
  Timer? _timer;

  final Map<String, String> _answers = {};
  String? _selectedOption;
  String? _correctOption;
  bool _showResult = false;
  int? _finalScore;
  int? _rank;
  int? _coinsEarned;
  String? _alreadyPlayedRank;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDaily() async {
    try {
      final data = await _api.getDailyChallenge();
      final rawQs = data['questions'] as List? ?? [];
      setState(() {
        _questions = rawQs
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
        _date = data['date']?.toString() ??
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (data['already_played'] == true) {
          _alreadyPlayedRank = data['your_rank']?.toString();
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 10.0;
      _selectedOption = null;
      _correctOption = null;
      _showResult = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          t.cancel();
          _onTimeout();
        }
      });
    });
  }

  void _onTimeout() {
    final q = _questions[_currentIndex];
    _answers[q.id] = '';
    setState(() {
      _correctOption = q.correctOption;
      _showResult = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _onAnswer(String option) {
    if (_showResult || _selectedOption != null) return;
    _timer?.cancel();
    final q = _questions[_currentIndex];
    _answers[q.id] = option;
    setState(() {
      _selectedOption = option;
      _correctOption = q.correctOption;
      _showResult = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _startTimer();
    } else {
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    setState(() => _submitted = true);
    try {
      final result = await _api.submitDailyChallenge(_date, _answers);
      if (!mounted) return;
      setState(() {
        _finalScore = (result['score'] as num?)?.toInt();
        _rank = (result['rank'] as num?)?.toInt();
        _coinsEarned = (result['coins_earned'] as num?)?.toInt();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finalScore =
            _answers.values.where((v) => v.isNotEmpty).length * 10;
        _coinsEarned = 75;
      });
    }
  }

  String get _todayFormatted {
    try {
      final d = DateTime.parse(_date);
      return DateFormat('MMMM d, yyyy').format(d);
    } catch (_) {
      return _date;
    }
  }

  Duration get _timeToMidnight {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  Color get _timerColor {
    if (_timeLeft <= 3) return AppColors.timerDanger;
    if (_timeLeft <= 5) return AppColors.gold;
    return AppColors.timerSafe;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_submitted) {
      return _ResultView(
        score: _finalScore ?? 0,
        rank: _rank,
        coinsEarned: _coinsEarned ?? 75,
        date: _todayFormatted,
        onGoHome: () => context.go('/home'),
      );
    }

    if (_alreadyPlayedRank != null) {
      return _AlreadyPlayedView(
        rank: _alreadyPlayedRank!,
        onGoHome: () => context.go('/home'),
      );
    }

    if (!_started) {
      return _IntroView(
        date: _todayFormatted,
        timeToMidnight: _timeToMidnight,
        questionCount: _questions.length,
        onStart: () {
          setState(() => _started = true);
          _startTimer();
        },
        onBack: () => context.go('/home'),
      );
    }

    // ── Playing ─────────────────────────────────────────────────────────────
    final q = _questions[_currentIndex];
    final timerFraction = (_timeLeft / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Q badge + timer badge
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    // Back / Q indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.quiz_rounded,
                              color: AppColors.primaryLight, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Q${_currentIndex + 1} / ${_questions.length}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Timer badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _timerColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _timerColor.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _timerColor.withValues(alpha: 0.28),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded,
                              color: _timerColor, size: 14),
                          const SizedBox(width: 5),
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

              // Gradient linear progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          color: ac.surfaceVariant,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          height: 6,
                          width: constraints.maxWidth * timerFraction,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _timerColor.withValues(alpha: 0.7),
                                _timerColor,
                              ],
                            ),
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
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Question card
              Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ac.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
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
                            fontSize: 18,
                            height: 1.45,
                          ),
                        )
                            .animate(key: ValueKey(_currentIndex))
                            .fadeIn(duration: 300.ms),
                      ),
                    ),
                  ),
                ),
              ),

              // Answer grid
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    physics: const NeverScrollableScrollPhysics(),
                    children: ['A', 'B', 'C', 'D'].map((opt) {
                      AnswerState state = AnswerState.none;
                      if (_showResult) {
                        if (opt == _correctOption) {
                          state = AnswerState.correct;
                        } else if (opt == _selectedOption) {
                          state = AnswerState.wrong;
                        }
                      } else if (opt == _selectedOption) {
                        state = AnswerState.selected;
                      }
                      return AnswerButton(
                        label: q.options[opt] ?? '',
                        option: opt,
                        onTap: _showResult ? null : () => _onAnswer(opt),
                        state: state,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Intro View ───────────────────────────────────────────────────────────────
class _IntroView extends StatelessWidget {
  final String date;
  final Duration timeToMidnight;
  final int questionCount;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _IntroView({
    required this.date,
    required this.timeToMidnight,
    required this.questionCount,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back button row
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Intro card with gradient header area
                      Container(
                        decoration: BoxDecoration(
                          color: ac.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Gradient header area
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.30),
                                    AppColors.primary.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryDark,
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.28),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.today_rounded,
                                        color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Today's Challenge",
                                    style: TextStyle(
                                      color: ac.textSecondary,
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Reset pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.update_rounded,
                                            color: AppColors.accent, size: 13),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Resets in '
                                          '${timeToMidnight.inHours}h '
                                          '${timeToMidnight.inMinutes.remainder(60)}m',
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Rules list
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _RuleRow(
                                    icon: Icons.quiz_outlined,
                                    text:
                                        '$questionCount questions — same for everyone',
                                  ),
                                  const _RuleRow(
                                    icon: Icons.timer_rounded,
                                    text: '10 seconds per question',
                                  ),
                                  const _RuleRow(
                                    icon: Icons.monetization_on_rounded,
                                    text: '+75 coins for completing',
                                  ),
                                  const _RuleRow(
                                    icon: Icons.emoji_events_rounded,
                                    text: '+200 coins for Top 10 rank',
                                  ),
                                  const _RuleRow(
                                    icon: Icons.replay_rounded,
                                    text: 'Can only be played once today',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08),

                      const Spacer(),

                      // Start button
                      GestureDetector(
                        onTap: onStart,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryDark,
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Start Challenge',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Already Played View ──────────────────────────────────────────────────────
class _AlreadyPlayedView extends StatelessWidget {
  final String rank;
  final VoidCallback onGoHome;

  const _AlreadyPlayedView({required this.rank, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onGoHome,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.correctGreen.withValues(alpha: 0.25),
                                AppColors.correctGreen.withValues(alpha: 0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.correctGreen.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.correctGreen
                                    .withValues(alpha: 0.28),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: AppColors.correctGreen, size: 52),
                        ).animate().scaleXY(
                            begin: 0.5,
                            end: 1.0,
                            curve: Curves.elasticOut,
                            duration: 600.ms),

                        const SizedBox(height: 24),

                        Text(
                          "You've already played today!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ac.textPrimary,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: ac.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.28),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Your Rank',
                                style: TextStyle(
                                  color: ac.textSecondary,
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (b) =>
                                    const LinearGradient(
                                  colors: [
                                    AppColors.goldDark,
                                    AppColors.gold,
                                    AppColors.goldLight,
                                  ],
                                ).createShader(b),
                                child: Text(
                                  '#$rank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 42,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        Text(
                          'Come back tomorrow for a new challenge!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ac.textSecondary,
                            fontFamily: 'Nunito',
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 32),

                        GestureDetector(
                          onTap: onGoHome,
                          child: Container(
                            height: 54,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: 600.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rule Row ─────────────────────────────────────────────────────────────────
class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ac.textPrimary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result View ──────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final int score;
  final int? rank;
  final int coinsEarned;
  final String date;
  final VoidCallback onGoHome;

  const _ResultView({
    required this.score,
    this.rank,
    required this.coinsEarned,
    required this.date,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // Trophy icon with glow
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.22),
                          AppColors.gold.withValues(alpha: 0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.28),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: AppColors.gold, size: 56),
                  ).animate().scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      curve: Curves.elasticOut,
                      duration: 600.ms),
                ),

                const SizedBox(height: 20),

                Text(
                  'Challenge Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 6),

                Text(
                  date,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                // Score + rank card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ac.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.28),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppColors.goldDark, AppColors.gold, AppColors.goldLight],
                        ).createShader(b),
                        child: Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 62,
                          ),
                        ),
                      ),
                      if (rank != null) ...[
                        Divider(
                            color: ac.surfaceVariant, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryDark,
                                    AppColors.primaryLight,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.leaderboard_rounded,
                                  color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rank  #$rank',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Divider(color: ac.surfaceVariant, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CoinDisplay(coins: coinsEarned, fontSize: 20),
                          const SizedBox(width: 6),
                          Text(
                            'earned!',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.18),

                const Spacer(),

                // Home button
                GestureDetector(
                  onTap: onGoHome,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
