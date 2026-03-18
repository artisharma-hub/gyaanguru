import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/share_sheet.dart';
import '../widgets/sound_tap.dart';
import '../services/sound_service.dart';

class ChallengeCreateScreen extends ConsumerStatefulWidget {
  const ChallengeCreateScreen({super.key});

  @override
  ConsumerState<ChallengeCreateScreen> createState() =>
      _ChallengeCreateScreenState();
}

class _ChallengeCreateScreenState
    extends ConsumerState<ChallengeCreateScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = '';
  bool _challengeCreated = false;
  String _challengeLink = '';
  String _challengeToken = '';
  bool _shareSuccess = false;
  late final AnimationController _pulseController;

  static const _categories = [
    'cricket',
    'bollywood',
    'gk',
    'math',
    'science',
    'hindi',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select a category first!',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.surfaceBright,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    await ref
        .read(challengeProvider.notifier)
        .createChallenge(_selectedCategory);
    if (!mounted) return;
    final state = ref.read(challengeProvider);
    state.whenData((data) {
      if (data != null) {
        final link = data['link']?.toString() ?? '';
        final token = data['token']?.toString() ?? '';
        setState(() {
          _challengeCreated = true;
          _challengeLink = link;
          _challengeToken = token;
        });
        final user = ref.read(authProvider).valueOrNull;
        showShareSheet(
          context,
          link: link.isNotEmpty ? link : 'gyaanguru.app/challenge/$token',
          challengerName: user?.name ?? 'Your friend',
          category: _selectedCategory,
        );
      }
    });
  }

  void _shareLink(String link, String? userName) {
    showShareSheet(
      context,
      link: link,
      challengerName: userName ?? 'Your friend',
      category: _selectedCategory,
    );
    setState(() => _shareSuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shareSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final isLoading = challengeState is AsyncLoading;
    final canCreate = _selectedCategory.isNotEmpty && !isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: SoundTap(
          onTap: () => context.
          pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Challenge a Friend',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _challengeCreated
                ? _buildSuccessView(user?.name)
                : _buildSelectionView(isLoading, canCreate),
          ),
        ),
      ),
    );
  }

  // ── Selection View ────────────────────────────────────────────────────────

  Widget _buildSelectionView(bool isLoading, bool canCreate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        // Header
        const Text(
          'Pick a Category',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.08, end: 0),
        const SizedBox(height: 4),
        const Text(
          'Your friend will be quizzed on this topic',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 20),
        // Category grid
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat;
              return CategoryCard(
                categoryKey: cat,
                isSelected: selected,
                onTap: () { SoundService().click(); setState(() => _selectedCategory = cat); },
              )
                  .animate(delay: (i * 65).ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.12, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
            },
          ),
        ),
        const SizedBox(height: 16),
        // Create button
        _GradientButton(
          onPressed: canCreate ? _createChallenge : null,
          isLoading: isLoading,
          icon: Icons.bolt_rounded,
          label: isLoading ? 'Creating...' : 'Create Challenge Link',
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }

  // ── Success / Share View ──────────────────────────────────────────────────

  Widget _buildSuccessView(String? userName) {
    final link = _challengeLink.isNotEmpty
        ? _challengeLink
        : 'gyaanguru.app/challenge/$_challengeToken';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        // Animated share icon
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final scale = 0.95 + 0.10 * _pulseController.value;
              final glow = 0.22 + 0.18 * _pulseController.value;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glow),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glow * 0.5),
                        blurRadius: 52,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ).animate().scaleXY(begin: 0.6, end: 1.0, duration: 550.ms, curve: Curves.elasticOut),
        const SizedBox(height: 28),
        const Text(
          'Challenge Link Created!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.3,
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 6),
        const Text(
          'Waiting for your friend to join...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ).animate(delay: 220.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 28),
        // Share link card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Share this link',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Text(
                  link,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              // Share button
              SizedBox(
                width: double.infinity,
                child: _GradientButton(
                  onPressed: () => _shareLink(link, userName),
                  isLoading: false,
                  icon: _shareSuccess ? Icons.check_circle_rounded : Icons.share_rounded,
                  label: _shareSuccess ? 'Shared!' : 'Share',
                  successState: _shareSuccess,
                ),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
        const Spacer(flex: 2),
        // Back to home
        OutlinedButton(
          onPressed: () { SoundService().click(); context.go('/home'); },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ).animate(delay: 450.ms).fadeIn(duration: 350.ms),
      ],
    );
  }
}

// ── Reusable gradient CTA button ─────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String label;
  final bool successState;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
    this.successState = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SoundTap(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 54,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : successState
                  ? const LinearGradient(
                      colors: [Color(0xFF1E8449), AppColors.correctGreen, Color(0xFF55D98D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
          color: disabled ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: (successState ? AppColors.correctGreen : AppColors.primary)
                        .withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                color: disabled ? AppColors.textMuted : Colors.white,
                size: 22,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: disabled ? AppColors.textMuted : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
