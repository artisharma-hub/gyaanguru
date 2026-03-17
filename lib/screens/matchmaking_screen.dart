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
import '../services/sound_service.dart';
import '../widgets/vs_card.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final String category;
  const MatchmakingScreen({super.key, required this.category});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  Timer? _timeoutTimer;
  bool _timedOut  = false;
  bool _navigated = false;

  static const _categoryNames = {
    'cricket':   'Cricket & Sports',
    'bollywood': 'Bollywood & OTT',
    'gk':        'Indian GK & History',
    'math':      'Rapid Math',
    'science':   'Science & Tech',
    'hindi':     'Hindi Wordplay',
  };

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
    final user  = ref.read(authProvider).valueOrNull;
    final token = await ref.read(authProvider.notifier).getToken();
    if (!mounted) return;
    if (user == null || token == null) {
      context.go('/register');
      return;
    }
    ref.read(matchProvider.notifier)
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
      final data     = await ApiService().createBotMatch(widget.category);
      final matchId  = data['match_id'] as String;
      final opponent = data['opponent'] as Map<String, dynamic>;
      ref.read(matchProvider.notifier).setOpponent(
            opponentId:          opponent['id'] as String,
            opponentName:        opponent['name'] as String,
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
    final matchState    = ref.watch(matchProvider);
    final user          = ref.watch(authProvider).valueOrNull;
    final categoryColor = _categoryColors[widget.category] ?? AppColors.primary;
    final categoryName  = _categoryNames[widget.category] ?? widget.category;
    final ac            = context.ac;

    ref.listen(matchProvider, (prev, next) {
      if (prev?.phase != MatchPhase.matched &&
          next.phase == MatchPhase.matched &&
          next.matchId != null &&
          !_navigated) {
        _navigated = true;
        SoundService().matchFound();
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            router.go('/battle/${next.matchId}?category=${widget.category}');
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _cancel(); },
      child: Scaffold(
        backgroundColor: ac.background,
        appBar: AppBar(
          backgroundColor: ac.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ac.textPrimary),
            onPressed: _cancel,
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                color: categoryColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        body: Center(
          child: matchState.phase == MatchPhase.matched
              ? _MatchFoundWidget(
                  myName:              user?.name ?? 'You',
                  myAvatarColor:       user?.avatarColor ?? '#FF4500',
                  opponentName:        matchState.opponentName ?? 'Opponent',
                  opponentAvatarColor: matchState.opponentAvatarColor ?? '#E65100',
                )
              : matchState.phase == MatchPhase.error
                  ? _ErrorWidget(
                      message: matchState.errorMessage ?? 'Connection error',
                      onRetry: () {
                        ref.read(matchProvider.notifier).reset();
                        setState(() {
                          _timedOut  = false;
                          _navigated = false;
                        });
                        _startMatchmaking();
                        _timeoutTimer = Timer(const Duration(seconds: 30), () {
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

// ── Searching widget ──────────────────────────────────────────────────────────
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
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar animation
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding rings
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 70.0 + i * 52,
                    height: 70.0 + i * 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.28 - i * 0.07),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                        begin: 0.75,
                        end: 1.2,
                        duration: (1200 + i * 350).ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn()
                      .then()
                      .fadeOut(duration: 500.ms),

                // Center icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      categoryColor.withValues(alpha: 0.25),
                      categoryColor.withValues(alpha: 0.08),
                    ]),
                    shape: BoxShape.circle,
                    border: Border.all(color: categoryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_search_rounded,
                      color: categoryColor, size: 32),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.92, end: 1.08, duration: 900.ms),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Searching for opponent...',
            style: TextStyle(
              color: ac.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 600.ms)
              .then(delay: 800.ms)
              .fadeOut(duration: 500.ms),

          const SizedBox(height: 8),

          Text(
            'Matching from global player pool',
            style: TextStyle(
              color: ac.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 40),

          if (timedOut) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ac.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ac.border),
              ),
              child: Column(
                children: [
                  Text(
                    'No opponent found nearby.',
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onPlayBot,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentDark, AppColors.accent,
                              AppColors.accentLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Play vs Bot',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ],
      ),
    );
  }
}

// ── Match found widget ────────────────────────────────────────────────────────
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
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Opponent found banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.correctGreen.withValues(alpha: 0.2),
                AppColors.correctGreen.withValues(alpha: 0.05),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.correctGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.correctGreen, size: 20),
                SizedBox(width: 8),
                Text(
                  'Opponent Found!',
                  style: TextStyle(
                    color: AppColors.correctGreen,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: 0.85, end: 1.0, curve: Curves.elasticOut),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ac.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.correctGreen.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.correctGreen.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: VsCard(
              myName:              myName,
              myAvatarColor:       myAvatarColor,
              myScore:             0,
              opponentName:        opponentName,
              opponentAvatarColor: opponentAvatarColor,
              opponentScore:       0,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.elasticOut),

          const SizedBox(height: 28),

          Text(
            'Get ready... Battle starts soon!',
            style: TextStyle(
              color: ac.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
            strokeWidth: 2,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

// ── Error widget ──────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.wrongRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: AppColors.wrongRed, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ac.textPrimary,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
