import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading        = false;
  bool _isPressed        = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty)  return 'Name is required';
    if (v.length < 2)  return 'Must be at least 2 characters';
    if (v.length > 30) return 'Must be 30 characters or fewer';
    if (!RegExp(r"^[a-zA-Z\s''-]+$").hasMatch(v)) {
      return 'Only letters and spaces allowed';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty)    return 'Phone number is required';
    if (digits.length != 10) return 'Enter a valid 10-digit number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Must start with 6, 7, 8, or 9';
    }
    return null;
  }

  Future<void> _register() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final digits       = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final existingName = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          digits,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          if (existingName != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Welcome back, $existingName! Logged in with your saved profile.'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          context.go('/home');
        }
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac   = context.ac;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // ── Ambient background glows ────────────────────────────────
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -90,
              child: Container(
                width: 280,
                height: 280,
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

            // ── Scrollable content ──────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.hPad(context),
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: AppSizes.hp(context, 18)),

                      // ── Logo + branding ───────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            // Logo with pulsing rings
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.18),
                                        width: 1.5,
                                      ),
                                    ),
                                  )
                                      .animate(onPlay: (c) => c.repeat())
                                      .scaleXY(
                                        begin: 0.82,
                                        end: 1.14,
                                        duration: 2100.ms,
                                        curve: Curves.easeInOut,
                                      )
                                      .fadeIn(duration: 500.ms)
                                      .then()
                                      .fadeOut(duration: 700.ms),

                                  // Inner ring
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryLight
                                            .withValues(alpha: 0.28),
                                        width: 1.0,
                                      ),
                                    ),
                                  )
                                      .animate(
                                        delay: 400.ms,
                                        onPlay: (c) => c.repeat(),
                                      )
                                      .scaleXY(
                                        begin: 0.88,
                                        end: 1.10,
                                        duration: 1700.ms,
                                        curve: Curves.easeInOut,
                                      )
                                      .fadeIn(duration: 400.ms)
                                      .then()
                                      .fadeOut(duration: 600.ms),

                                  // Logo box
                                  Container(
                                    width: 80,
                                    height: 80,
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
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.60),
                                          blurRadius: 32,
                                          spreadRadius: 3,
                                        ),
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.22),
                                          blurRadius: 55,
                                          spreadRadius: 6,
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
                                          fontSize: 44,
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
                                        begin: 0.55,
                                        end: 1.0,
                                        duration: 750.ms,
                                        curve: Curves.elasticOut,
                                      ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Gradient title
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [
                                  AppColors.textPrimary,
                                  AppColors.primaryLight,
                                  AppColors.accentLight,
                                ],
                                stops: [0.0, 0.55, 1.0],
                              ).createShader(b),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'Gyaan Guru',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  fontSize: AppSizes.sp(context, 32),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 280.ms, duration: 450.ms)
                                .slideY(
                                  begin: 0.30,
                                  end: 0.0,
                                  delay: 280.ms,
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 8),

                            Text(
                              'Live Quiz Battle — Prove Your Knowledge!',
                              style: TextStyle(
                                color: ac.textSecondary,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Form card ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: ac.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.38),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card header
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
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
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.45),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.sports_esports_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Join the Arena',
                                        style: TextStyle(
                                          color: ac.textPrimary,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      Text(
                                        'No OTP — start instantly',
                                        style: TextStyle(
                                          color: ac.textSecondary,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // Divider with subtle gradient overlay
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primary.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                validator: _validateName,
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600,
                                ),
                                textCapitalization: TextCapitalization.words,
                                maxLength: 30,
                                decoration: const InputDecoration(
                                  labelText: 'Your Name',
                                  hintText: 'e.g. Rahul Kumar',
                                  counterText: '',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Phone field
                              TextFormField(
                                controller: _phoneController,
                                validator: _validatePhone,
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600,
                                ),
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '10-digit mobile number',
                                  counterText: '',
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── CTA button with press scale ───────────
                              GestureDetector(
                                onTapDown: _isLoading
                                    ? null
                                    : (_) => setState(() => _isPressed = true),
                                onTapUp: _isLoading
                                    ? null
                                    : (_) {
                                        setState(() => _isPressed = false);
                                        _register();
                                      },
                                onTapCancel: _isLoading
                                    ? null
                                    : () => setState(() => _isPressed = false),
                                child: AnimatedScale(
                                  scale: _isPressed ? 0.96 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOut,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: _isLoading
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.primaryDark
                                                    .withValues(alpha: 0.6),
                                                AppColors.primary
                                                    .withValues(alpha: 0.6),
                                              ],
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                AppColors.primaryDark,
                                                AppColors.primary,
                                                AppColors.primaryLight,
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: _isLoading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.55),
                                                blurRadius: 22,
                                                offset: const Offset(0, 7),
                                              ),
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 40,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.bolt_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Start Playing',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Nunito',
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 17,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 180.ms, duration: 550.ms)
                          .slideY(
                            begin: 0.28,
                            end: 0.0,
                            delay: 180.ms,
                            duration: 580.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 22),

                      // Terms note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: ac.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'By joining you agree to our Terms & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ac.textMuted,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
