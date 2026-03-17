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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finalScore = _answers.values.where((v) => v.isNotEmpty).length * 10;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    if (_submitted) {
      return _ResultView(
        score: _finalScore ?? 0,
        rank: _rank,
        date: _todayFormatted,
        onGoHome: () => context.go('/home'),
      );
    }

    if (_alreadyPlayedRank != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
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
                const Text(
                  "You've already played today's challenge!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your rank: #$_alreadyPlayedRank',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Come back tomorrow!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/home')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.today,
                        color: AppColors.primary, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      "Today's Challenge",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _todayFormatted,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Resets in ${_timeToMidnight.inHours}h '
                          '${_timeToMidnight.inMinutes.remainder(60)}m',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _RuleRow(
                      icon: Icons.quiz_outlined,
                      text:
                          '${_questions.length} questions — same for everyone',
                    ),
                    _RuleRow(
                        icon: Icons.timer,
                        text: '10 seconds per question'),
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
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  setState(() => _started = true);
                  _startTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Challenge',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Playing
    final q = _questions[_currentIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Q${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_timeLeft.toStringAsFixed(1)}s',
                    style: TextStyle(
                      color: _timeLeft <= 3
                          ? AppColors.timerDanger
                          : AppColors.timerSafe,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                          height: 6, color: AppColors.surfaceVariant),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        height: 6,
                        width: constraints.maxWidth *
                            (_timeLeft / 10.0).clamp(0.0, 1.0),
                        color: _timeLeft <= 3
                            ? AppColors.timerDanger
                            : AppColors.timerSafe,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    q.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  )
                      .animate(key: ValueKey(_currentIndex))
                      .fadeIn(duration: 300.ms),
                ),
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
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
  final String date;
  final VoidCallback onGoHome;

  const _ResultView({
    required this.score,
    this.rank,
    required this.date,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 72)
                  .animate()
                  .scaleXY(
                    begin: 0.5,
                    end: 1.0,
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
              const SizedBox(height: 16),
              const Text(
                'Challenge Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 56,
                      ),
                    ),
                    if (rank != null) ...[
                      const Divider(color: AppColors.surfaceVariant),
                      Text(
                        'Your Rank: #$rank',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const CoinDisplay(coins: 75, fontSize: 20),
                    const Text(
                      'earned!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
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
              ElevatedButton(
                onPressed: onGoHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
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
