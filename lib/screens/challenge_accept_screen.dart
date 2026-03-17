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

  static const _categoryIcons = {
    'cricket': Icons.sports_cricket_rounded,
    'bollywood': Icons.movie_filter_rounded,
    'gk': Icons.menu_book_rounded,
    'math': Icons.functions_rounded,
    'science': Icons.biotech_rounded,
    'hindi': Icons.record_voice_over_rounded,
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
        SnackBar(
          content: const Text(
            'Failed to join challenge. Try again.',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.wrongRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    final matchId = result['match_id']?.toString() ?? '';
    final category =
        _challengeData?['category']?.toString() ?? 'cricket';
    context.go('/battle/$matchId?category=$category');
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF15172E), Color(0xFF1A1D38)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    // ── Error state ───────────────────────────────────────────────────────

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF15172E), Color(0xFF1A1D38)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.wrongRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.wrongRed.withValues(alpha: 0.40),
                          width: 2,
                        ),
                        boxShadow: AppColors.wrongGlow(blur: 20),
                      ),
                      child: const Icon(
                        Icons.link_off_rounded,
                        color: AppColors.wrongRed,
                        size: 44,
                      ),
                    ).animate().scaleXY(begin: 0.7, end: 1.0, duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'The challenge link may have expired or already been used.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.primaryGlow(blur: 16),
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Main challenge card ────────────────────────────────────────────────

    final challenger =
        _challengeData?['challenger'] as Map<String, dynamic>? ?? {};
    final challengerName = challenger['name']?.toString() ?? 'Someone';
    final challengerColor =
        challenger['avatar_color']?.toString() ?? '#FF4500';
    final category = _challengeData?['category']?.toString() ?? 'cricket';
    final categoryName = _categoryNames[category] ?? category;
    final categoryColor = _categoryColors[category] ?? AppColors.primary;
    final categoryIcon = _categoryIcons[category] ?? Icons.quiz_rounded;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF15172E), Color(0xFF1A1D38)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // ── Challenge card ──────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar with soft glow
                            _GlowAvatar(
                              name: challengerName,
                              avatarColor: challengerColor,
                              glowColor: categoryColor,
                            )
                                .animate()
                                .scaleXY(
                                  begin: 0.5,
                                  end: 1.0,
                                  duration: 620.ms,
                                  curve: Curves.elasticOut,
                                ),
                            const SizedBox(height: 20),
                            // Challenger title
                            Text(
                              '$challengerName\nis challenging you!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                            ).animate(delay: 180.ms).fadeIn(duration: 350.ms),
                            const SizedBox(height: 20),
                            // Category neon pill badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: categoryColor.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    color: categoryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: categoryColor,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: 260.ms).fadeIn(duration: 350.ms),
                            const SizedBox(height: 16),
                            // Info row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.quiz_rounded,
                                    color: AppColors.textSecondary,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '10 questions',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.timer_rounded,
                                    color: AppColors.textSecondary,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '10s each',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: 340.ms).fadeIn(duration: 350.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Accept button ───────────────────────────────────────
                GestureDetector(
                  onTap: _accepting ? null : _accept,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _accepting
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFF1E8449),
                                AppColors.correctGreen,
                                Color(0xFF55D98D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _accepting ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _accepting
                          ? null
                          : AppColors.correctGlow(blur: 18),
                    ),
                    child: Center(
                      child: _accepting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Accept Challenge',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                )
                    .animate(delay: 480.ms)
                    .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 10),
                // ── Decline button ──────────────────────────────────────
                TextButton(
                  onPressed: () => context.go('/home'),
                  style: TextButton.styleFrom(
                    overlayColor: AppColors.textMuted.withValues(alpha: 0.10),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ).animate(delay: 560.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glow Avatar Widget ────────────────────────────────────────────────────────

class _GlowAvatar extends StatelessWidget {
  final String name;
  final String avatarColor;
  final Color glowColor;

  const _GlowAvatar({
    required this.name,
    required this.avatarColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: glowColor.withValues(alpha: 0.55),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.30),
            blurRadius: 20,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.14),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AvatarWidget(
        name: name,
        avatarColor: avatarColor,
        radius: 50,
      ),
    );
  }
}
