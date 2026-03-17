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
      backgroundColor: ac.background,
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(
                      alpha: context.isDark ? 0.22 : 0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(
                      alpha: context.isDark ? 0.16 : 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.hPad(context), vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSizes.hp(context, 20)),

                    // ── Logo + branding ───────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          // Logo with glow rings
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                        alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                              )
                                  .animate(onPlay: (c) => c.repeat())
                                  .scaleXY(
                                    begin: 0.85,
                                    end: 1.12,
                                    duration: 2000.ms,
                                    curve: Curves.easeInOut,
                                  )
                                  .fadeIn()
                                  .then()
                                  .fadeOut(duration: 700.ms),
                              Container(
                                width: 88, height: 88,
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
                                      color: AppColors.primary
                                          .withValues(alpha: 0.55),
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
                                      fontSize: 48,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white38,
                                          blurRadius: 12,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .scaleXY(
                                    begin: 0.6,
                                    end: 1.0,
                                    duration: 700.ms,
                                    curve: Curves.elasticOut,
                                  ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: [ac.textPrimary, AppColors.primaryLight],
                            ).createShader(b),
                            child: Text(
                              'Gyaan Guru',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w900,
                                fontSize: AppSizes.sp(context, 30),
                                letterSpacing: -0.5,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 6),

                          Text(
                            'Live Quiz Battle — Prove Your Knowledge!',
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 500.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Form card ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ac.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: ac.border2, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                                alpha: context.isDark ? 0.10 : 0.06),
                            blurRadius: 32,
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
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.sports_esports_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join the Arena',
                                      style: TextStyle(
                                        color: ac.textPrimary,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      'No OTP — start instantly',
                                      style: TextStyle(
                                        color: ac.textSecondary,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),
                            Divider(color: ac.border, height: 1),
                            const SizedBox(height: 22),

                            TextFormField(
                              controller: _nameController,
                              validator: _validateName,
                              style: TextStyle(
                                color: ac.textPrimary,
                                fontFamily: 'Poppins',
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

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _phoneController,
                              validator: _validatePhone,
                              style: TextStyle(
                                color: ac.textPrimary,
                                fontFamily: 'Poppins',
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

                            const SizedBox(height: 26),

                            // CTA button
                            GestureDetector(
                              onTap: _isLoading ? null : _register,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            AppColors.primaryDark,
                                            AppColors.primary,
                                            AppColors.primaryLight,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  color: _isLoading ? null : null,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: _isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.50),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22, width: 22,
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
                                            Icon(Icons.bolt_rounded,
                                                color: Colors.white, size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'Start Playing',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 17,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.25, end: 0),

                    const SizedBox(height: 20),

                    Text(
                      'By joining you agree to play fair and have fun!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: ac.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
