import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/share_sheet.dart';

class ChallengeCreateScreen extends ConsumerStatefulWidget {
  const ChallengeCreateScreen({super.key});

  @override
  ConsumerState<ChallengeCreateScreen> createState() =>
      _ChallengeCreateScreenState();
}

class _ChallengeCreateScreenState
    extends ConsumerState<ChallengeCreateScreen> {
  String _selectedCategory = '';
  bool _challengeCreated = false;
  String _challengeLink = '';
  String _challengeToken = '';

  static const _categories = [
    'cricket',
    'bollywood',
    'gk',
    'math',
    'science',
    'hindi',
  ];

  Future<void> _createChallenge() async {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first!')),
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

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final isLoading = challengeState is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Challenge a Friend',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_challengeCreated) ...[
                const Text(
                  'Pick a Category',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your friend will be quizzed on this topic',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      return CategoryCard(
                        categoryKey: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                      )
                          .animate(delay: (i * 60).ms)
                          .fadeIn(duration: 300.ms);
                    },
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _createChallenge,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link, size: 24),
                  label: Text(
                    isLoading ? 'Creating...' : 'Create Challenge Link',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.share,
                        color: AppColors.primary, size: 36),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 0.95, end: 1.05, duration: 1000.ms)
                      .then()
                      .scaleXY(begin: 1.05, end: 0.95, duration: 1000.ms),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Challenge Link Created!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for your friend to join...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Share this link:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Nunito',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _challengeLink.isNotEmpty
                            ? _challengeLink
                            : 'gyaanguru.app/challenge/$_challengeToken',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Nunito',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final link = _challengeLink.isNotEmpty
                              ? _challengeLink
                              : 'gyaanguru.app/challenge/$_challengeToken';
                          showShareSheet(
                            context,
                            link: link,
                            challengerName: user?.name ?? 'Your friend',
                            category: _selectedCategory,
                          );
                        },
                        icon: const Icon(Icons.share, size: 22),
                        label: const Text(
                          'Share Again',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontFamily: 'Nunito'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
