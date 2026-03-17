import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/challenge_provider.dart';
import '../widgets/vs_card.dart';

class ChallengeAcceptScreen extends ConsumerStatefulWidget {
  final String token;
  const ChallengeAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<ChallengeAcceptScreen> createState() =>
      _ChallengeAcceptScreenState();
}

class _ChallengeAcceptScreenState
    extends ConsumerState<ChallengeAcceptScreen> {
  Map<String, dynamic>? _challengeData;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  static const _categoryNames = {
    'cricket': 'Cricket & Sports',
    'bollywood': 'Bollywood & OTT',
    'gk': 'Indian GK & History',
    'math': 'Rapid Math',
    'science': 'Science & Tech',
    'hindi': 'Hindi Wordplay',
  };

  static const _categoryColors = {
    'cricket': AppColors.cricket,
    'bollywood': AppColors.bollywood,
    'gk': AppColors.gk,
    'math': AppColors.math,
    'science': AppColors.science,
    'hindi': AppColors.hindi,
  };

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final data =
        await ref.read(challengeProvider.notifier).getChallenge(widget.token);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Challenge not found or expired.';
      });
    } else {
      setState(() {
        _loading = false;
        _challengeData = data;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final result =
        await ref.read(challengeProvider.notifier).joinChallenge(widget.token);
    if (!mounted) return;
    if (result == null) {
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join challenge. Try again.')),
      );
      return;
    }
    final matchId = result['match_id']?.toString() ?? '';
    final category =
        _challengeData?['category']?.toString() ?? 'cricket';
    context.go('/battle/$matchId?category=$category');
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link_off,
                    color: AppColors.wrongRed, size: 64),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The challenge link may have expired or already been used.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final challenger =
        _challengeData?['challenger'] as Map<String, dynamic>? ?? {};
    final challengerName = challenger['name']?.toString() ?? 'Someone';
    final challengerColor =
        challenger['avatar_color']?.toString() ?? '#FF4500';
    final category = _challengeData?['category']?.toString() ?? 'cricket';
    final categoryName = _categoryNames[category] ?? category;
    final categoryColor = _categoryColors[category] ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: AvatarWidget(
                  name: challengerName,
                  avatarColor: challengerColor,
                  radius: 48,
                ),
              ).animate().scaleXY(
                    begin: 0.5,
                    end: 1.0,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),
              Text(
                '$challengerName\nis challenging you!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: categoryColor,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '10 questions · 10 seconds each',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _accepting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _accepting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '⚔️  Accept Challenge',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
              )
                  .animate(delay: 500.ms)
                  .slideY(begin: 0.3, end: 0)
                  .fadeIn(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Decline',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
