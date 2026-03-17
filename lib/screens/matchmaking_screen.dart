import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/match_state.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../services/api_service.dart';
import '../widgets/vs_card.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final String category;
  const MatchmakingScreen({super.key, required this.category});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _navigated = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMatchmaking());
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    final user = ref.read(authProvider).valueOrNull;
    final token = await ref.read(authProvider.notifier).getToken();
    if (!mounted) return;
    if (user == null || token == null) {
      context.go('/register');
      return;
    }
    ref
        .read(matchProvider.notifier)
        .startMatchmaking(user.id, widget.category, token);
  }

  void _cancel() {
    ref.read(matchProvider.notifier).cancelMatchmaking();
    context.go('/home');
  }

  Future<void> _playVsBot() async {
    _timeoutTimer?.cancel();
    ref.read(matchProvider.notifier).cancelMatchmaking();

    try {
      final data = await ApiService().createBotMatch(widget.category);
      final matchId = data['match_id'] as String;
      final opponent = data['opponent'] as Map<String, dynamic>;

      ref.read(matchProvider.notifier).setOpponent(
            opponentId: opponent['id'] as String,
            opponentName: opponent['name'] as String,
            opponentAvatarColor: opponent['avatar_color'] as String,
          );

      if (mounted) {
        context.go('/battle/$matchId?category=${widget.category}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start bot match. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final categoryColor =
        _categoryColors[widget.category] ?? AppColors.primary;
    final categoryName =
        _categoryNames[widget.category] ?? widget.category;

    // Navigate when matched
    if (matchState.phase == MatchPhase.matched &&
        matchState.matchId != null &&
        !_navigated) {
      _navigated = true;
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          context.go(
              '/battle/${matchState.matchId}?category=${widget.category}');
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancel,
          ),
          title: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                color: categoryColor,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        body: Center(
          child: matchState.phase == MatchPhase.matched
              ? _MatchFoundWidget(
                  myName: user?.name ?? 'You',
                  myAvatarColor: user?.avatarColor ?? '#FF4500',
                  opponentName: matchState.opponentName ?? 'Opponent',
                  opponentAvatarColor:
                      matchState.opponentAvatarColor ?? '#E65100',
                )
              : matchState.phase == MatchPhase.error
                  ? _ErrorWidget(
                      message: matchState.errorMessage ?? 'Connection error',
                      onRetry: () {
                        ref.read(matchProvider.notifier).reset();
                        setState(() {
                          _timedOut = false;
                          _navigated = false;
                        });
                        _startMatchmaking();
                        _timeoutTimer =
                            Timer(const Duration(seconds: 30), () {
                          if (mounted) setState(() => _timedOut = true);
                        });
                      },
                    )
                  : _SearchingWidget(
                      categoryColor: categoryColor,
                      timedOut: _timedOut,
                      onPlayBot: _playVsBot,
                    ),
        ),
      ),
    );
  }
}

class _SearchingWidget extends StatelessWidget {
  final Color categoryColor;
  final bool timedOut;
  final VoidCallback onPlayBot;

  const _SearchingWidget({
    required this.categoryColor,
    required this.timedOut,
    required this.onPlayBot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  width: 60.0 + i * 50,
                  height: 60.0 + i * 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3 - i * 0.08),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.8,
                      end: 1.2,
                      duration: (1200 + i * 300).ms,
                    )
                    .fadeIn()
                    .then()
                    .fadeOut(duration: 600.ms),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: categoryColor, width: 2),
                ),
                child: Icon(Icons.search, color: categoryColor, size: 28),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms)
                  .then()
                  .scaleXY(begin: 1.1, end: 0.9, duration: 800.ms),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Searching for opponent...',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 600.ms)
            .then(delay: 600.ms)
            .fadeOut(duration: 600.ms),
        const SizedBox(height: 8),
        const Text(
          'Matching from global player pool',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 40),
        if (timedOut) ...[
          const Text(
            'No opponent found nearby.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPlayBot,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text(
              'Play vs Bot',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ],
    );
  }
}

class _MatchFoundWidget extends StatelessWidget {
  final String myName;
  final String myAvatarColor;
  final String opponentName;
  final String opponentAvatarColor;

  const _MatchFoundWidget({
    required this.myName,
    required this.myAvatarColor,
    required this.opponentName,
    required this.opponentAvatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Opponent Found!',
          style: TextStyle(
            color: AppColors.correctGreen,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scaleXY(
              begin: 0.8,
              end: 1.0,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: VsCard(
            myName: myName,
            myAvatarColor: myAvatarColor,
            myScore: 0,
            opponentName: opponentName,
            opponentAvatarColor: opponentAvatarColor,
            opponentScore: 0,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        const Text(
          'Get ready... Battle starts soon!',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
          strokeWidth: 2,
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off, color: AppColors.wrongRed, size: 60),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text(
            'Try Again',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
