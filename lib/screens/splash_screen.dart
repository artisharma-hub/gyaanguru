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

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
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
      backgroundColor: ac.background,
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: context.isDark ? 0.22 : 0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: context.isDark ? 0.18 : 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with pulsing rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(begin: 0.85, end: 1.15, duration: 2000.ms, curve: Curves.easeInOut)
                        .fadeIn(duration: 600.ms)
                        .then()
                        .fadeOut(duration: 600.ms),

                    // Middle ring
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(begin: 0.9, end: 1.1, duration: 1600.ms, curve: Curves.easeInOut)
                        .fadeIn(duration: 400.ms),

                    // Logo box
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.55),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: 50,
                            shadows: [Shadow(color: Colors.white38, blurRadius: 12)],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scaleXY(begin: 0.6, end: 1.0, duration: 700.ms, curve: Curves.elasticOut),
                  ],
                ),

                const SizedBox(height: 28),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [ac.textPrimary, AppColors.primaryLight],
                  ).createShader(bounds),
                  child: const Text(
                    'Gyaan Guru',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'Knowledge is Power',
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

                const SizedBox(height: 64),

                // Loading dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(delay: (1000 + i * 180).ms, onPlay: (c) => c.repeat())
                        .scaleXY(begin: 0.5, end: 1.0, duration: 500.ms, curve: Curves.easeInOut)
                        .then()
                        .scaleXY(begin: 1.0, end: 0.5, duration: 500.ms);
                  }),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
