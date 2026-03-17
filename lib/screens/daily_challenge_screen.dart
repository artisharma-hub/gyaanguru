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
      final data  = await _api.getDailyChallenge();
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
      _correctOption  = null;
      _showResult     = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
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
      _showResult    = true;
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
      _correctOption  = q.correctOption;
      _showResult     = true;
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
        _finalScore   = (result['score'] as num?)?.toInt();
        _rank         = (result['rank'] as num?)?.toInt();
        _coinsEarned  = (result['coins_earned'] as num?)?.toInt();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finalScore  = _answers.values.where((v) => v.isNotEmpty).length * 10;
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
    final now      = DateTime.now();
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
        backgroundColor: ac.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
      return Scaffold(
        backgroundColor: ac.background,
        appBar: AppBar(
          backgroundColor: ac.background,
          leading: BackButton(onPressed: () => context.go('/home')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.correctGreen, size: 72),
                const SizedBox(height: 20),
                Text(
                  "You've already played today!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your rank: #$_alreadyPlayedRank',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Come back tomorrow!',
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_started) {
      return Scaffold(
        backgroundColor: ac.background,
        appBar: AppBar(
          backgroundColor: ac.background,
          leading: BackButton(onPressed: () => context.go('/home')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date card with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      ac.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.today_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Today's Challenge",
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _todayFormatted,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: ac.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              color: ac.textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Resets in ${_timeToMidnight.inHours}h '
                            '${_timeToMidnight.inMinutes.remainder(60)}m',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 20),

              // Rules card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ac.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ac.border),
                ),
                child: Column(
                  children: [
                    _RuleRow(
                      icon: Icons.quiz_outlined,
                      text: '${_questions.length} questions — same for everyone',
                    ),
                    _RuleRow(icon: Icons.timer, text: '10 seconds per question'),
                    _RuleRow(
                        icon: Icons.monetization_on,
                        text: '+75 coins for completing'),
                    _RuleRow(
                        icon: Icons.emoji_events,
                        text: '+200 coins for Top 10 rank'),
                    _RuleRow(
                        icon: Icons.replay_outlined,
                        text: 'Can only be played once today'),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  setState(() => _started = true);
                  _startTimer();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary,
                          AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Start Challenge',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      );
    }

    // ── Playing ─────────────────────────────────────────────────────────────
    final q             = _questions[_currentIndex];
    final timerFraction = (_timeLeft / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Column(
          children: [
            // Q indicator + timer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Q${_currentIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _timerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _timerColor.withValues(alpha: 0.4)),
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
                            fontFamily: 'Poppins',
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

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 5, color: ac.surfaceVariant),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        height: 5,
                        width: constraints.maxWidth * timerFraction,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            _timerColor.withValues(alpha: 0.7),
                            _timerColor,
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: _timerColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Question
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        q.questionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      )
                          .animate(key: ValueKey(_currentIndex))
                          .fadeIn(duration: 300.ms),
                    ),
                  ),
                ),
              ),
            ),

            // Answer buttons
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
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ac.textPrimary,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: ac.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 72)
                  .animate()
                  .scaleXY(
                    begin: 0.5,
                    end: 1.0,
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
              const SizedBox(height: 16),
              Text(
                'Challenge Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ac.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 56,
                      ),
                    ),
                    if (rank != null) ...[
                      Divider(color: ac.surfaceVariant),
                      Text(
                        'Your Rank: #$rank',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    CoinDisplay(coins: coinsEarned, fontSize: 20),
                    Text(
                      'earned!',
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              const Spacer(),
              GestureDetector(
                onTap: onGoHome,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary,
                          AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
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
                          fontFamily: 'Poppins',
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
    );
  }
}
