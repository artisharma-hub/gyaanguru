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
import '../widgets/sound_tap.dart';

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
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: Stack(
            children: [
              // Ambient background glows
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      categoryColor.withValues(alpha: 0.14),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
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

              SafeArea(
                child: Column(
                  children: [
                    // ── Custom AppBar ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.textPrimary),
                            onPressed: _cancel,
                          ),
                          const Spacer(),
                          // Category badge — neon pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: categoryColor.withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: categoryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryColor.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    // ── Body content ───────────────────────────────────────
                    Expanded(
                      child: Center(
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
                                      _timeoutTimer = Timer(
                                          const Duration(seconds: 30), () {
                                        if (mounted) {
                                          setState(() => _timedOut = true);
                                        }
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Searching widget ────────────────────────────────────────────────────────────
class _SearchingWidget extends StatefulWidget {
  final Color categoryColor;
  final bool timedOut;
  final VoidCallback onPlayBot;

  const _SearchingWidget({
    required this.categoryColor,
    required this.timedOut,
    required this.onPlayBot,
  });

  @override
  State<_SearchingWidget> createState() => _SearchingWidgetState();
}

class _SearchingWidgetState extends State<_SearchingWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ringCtrs;
  late final List<Animation<double>> _ringScales;
  late final List<Animation<double>> _ringOpacities;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Three concentric expanding rings, staggered
    _ringCtrs = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1800 + i * 400),
      )..repeat();
      return ctrl;
    });

    _ringScales = _ringCtrs.map((c) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _ringOpacities = _ringCtrs.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 80),
      ]).animate(c);
    }).toList();

    // Pulsing center icon
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _ringCtrs) {
      c.dispose();
    }
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Radar / ring animation ──────────────────────────────────────
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Three expanding rings
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _ringCtrs[i],
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _ringScales[i].value,
                        child: Opacity(
                          opacity: _ringOpacities[i].value,
                          child: Container(
                            width: 80.0 + i * 56,
                            height: 80.0 + i * 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.categoryColor
                                    .withValues(alpha: 0.60 - i * 0.12),
                                width: 1.5 - i * 0.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.categoryColor
                                      .withValues(alpha: 0.18 - i * 0.04),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Pulsing center icon
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        widget.categoryColor.withValues(alpha: 0.30),
                        widget.categoryColor.withValues(alpha: 0.10),
                      ]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.categoryColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.categoryColor.withValues(alpha: 0.45),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: widget.categoryColor.withValues(alpha: 0.20),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_search_rounded,
                      color: widget.categoryColor,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // "Searching" headline
          const Text(
            'Searching for Opponent',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 700.ms)
              .then(delay: 900.ms)
              .fadeOut(duration: 600.ms),

          const SizedBox(height: 8),

          const Text(
            'Finding your match...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 44),

          // ── Bot fallback card (after timeout) ───────────────────────────
          if (widget.timedOut)
            _BotFallbackCard(onPlayBot: widget.onPlayBot),
        ],
      ),
    );
  }
}

// ── Bot fallback card ──────────────────────────────────────────────────────────
class _BotFallbackCard extends StatelessWidget {
  final VoidCallback onPlayBot;
  const _BotFallbackCard({required this.onPlayBot});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No opponent found nearby.',
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Play vs Bot gradient button
          SoundTap(
            onTap: onPlayBot,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentDark, AppColors.accent, AppColors.accentLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.20),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Play vs Bot',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms)
        .slideY(begin: 0.22, end: 0, curve: Curves.easeOut);
  }
}

// ── Match found widget ──────────────────────────────────────────────────────────
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
          // "Match Found!" green banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.correctGreen.withValues(alpha: 0.24),
                AppColors.correctGreen.withValues(alpha: 0.08),
              ]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.correctGreen.withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.correctGreen.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.correctGreen, size: 22),
                SizedBox(width: 10),
                Text(
                  'Match Found!',
                  style: TextStyle(
                    color: AppColors.correctGreen,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: 0.80, end: 1.0, curve: Curves.elasticOut),

          const SizedBox(height: 30),

          // VS card with elastic scale-in
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ac.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.correctGreen.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.correctGreen.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
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
              .fadeIn(delay: 180.ms, duration: 500.ms)
              .scaleXY(
                begin: 0.75,
                end: 1.0,
                delay: 180.ms,
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 28),

          Text(
            'Get ready... Battle starts soon!',
            style: TextStyle(
              color: ac.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
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

// ── Error widget ────────────────────────────────────────────────────────────────
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
          // Error card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ac.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.wrongRed.withValues(alpha: 0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wrongRed.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.wrongRed.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.wrongRed.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wrongRed.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.wrongRed,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOut),

          const SizedBox(height: 24),

          // Retry button
          SoundTap(
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.primaryGlow(blur: 18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}
