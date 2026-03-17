import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;

  // Outer ring pulse controller
  late final AnimationController _ring1Controller;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;

  // Inner ring pulse controller (offset phase)
  late final AnimationController _ring2Controller;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;

  @override
  void initState() {
    super.initState();

    // Outer ring — slower, larger sweep
    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: false);

    _ring1Scale = Tween<double>(begin: 0.80, end: 1.20).animate(
      CurvedAnimation(parent: _ring1Controller, curve: Curves.easeInOut),
    );
    _ring1Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 70),
    ]).animate(_ring1Controller);

    // Inner ring — faster, starts half-phase offset
    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: false);

    _ring2Scale = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _ring2Controller, curve: Curves.easeInOut),
    );
    _ring2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.45), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.0), weight: 60),
    ]).animate(_ring2Controller);

    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  @override
  void dispose() {
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    super.dispose();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    final authState = ref.read(authProvider);
    if (authState is AsyncLoading) {
      Future.delayed(const Duration(milliseconds: 500), _navigate);
      return;
    }
    _navigated = true;
    final user = authState.valueOrNull;

    final pendingLink = consumePendingDeepLink();
    if (pendingLink != null && user != null && pendingLink.scheme == 'gyaanguru') {
      final segs = pendingLink.pathSegments;
      if (segs.length >= 3 && segs[0] == 'challenge' && segs[1] == 'accept') {
        final token = segs[2];
        if (token.isNotEmpty) {
          context.go('/challenge/accept/$token');
          return;
        }
      }
    }

    if (user != null) {
      context.go('/home');
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // ── Ambient background glows ──────────────────────────────────
            Positioned(
              top: -120,
              left: -100,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20),
                      AppColors.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -90,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.16),
                      AppColors.accent.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Subtle mid-screen glow
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.35,
              left: MediaQuery.sizeOf(context).width * 0.5 - 160,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Center content ────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animated glow rings
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing ring
                        AnimatedBuilder(
                          animation: _ring1Controller,
                          builder: (_, __) => Transform.scale(
                            scale: _ring1Scale.value,
                            child: Opacity(
                              opacity: _ring1Opacity.value,
                              child: Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                              delay: 600.ms,
                              duration: 400.ms,
                            ),

                        // Inner pulsing ring
                        AnimatedBuilder(
                          animation: _ring2Controller,
                          builder: (_, __) => Transform.scale(
                            scale: _ring2Scale.value,
                            child: Opacity(
                              opacity: _ring2Opacity.value,
                              child: Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryLight,
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryLight
                                          .withValues(alpha: 0.20),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                              delay: 800.ms,
                              duration: 400.ms,
                            ),

                        // Logo box
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryDark,
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.60),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 60,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 50,
                                shadows: [
                                  Shadow(
                                    color: Colors.white54,
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scaleXY(
                              begin: 0.50,
                              end: 1.0,
                              duration: 750.ms,
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App title — gradient ShaderMask
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.textPrimary,
                        AppColors.primaryLight,
                        AppColors.accentLight,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'Gyaan Guru',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 38,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.30,
                        end: 0.0,
                        delay: 350.ms,
                        duration: 550.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 10),

                  // Tagline
                  Text(
                    'Knowledge is Power',
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.20,
                        end: 0.0,
                        delay: 650.ms,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 72),

                  // Bouncing loading dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                          .animate(
                            delay: (1100 + i * 160).ms,
                            onPlay: (c) => c.repeat(),
                          )
                          .moveY(
                            begin: 0,
                            end: -10,
                            duration: 420.ms,
                            curve: Curves.easeOut,
                          )
                          .then()
                          .moveY(
                            begin: -10,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeIn,
                          );
                    }),
                  ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
