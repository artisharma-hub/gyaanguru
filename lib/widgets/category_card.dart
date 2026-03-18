import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

class CategoryCard extends StatelessWidget {
  final String categoryKey;
  final bool isSelected;
  final VoidCallback onTap;
  final int? questionCount;

  const CategoryCard({
    super.key,
    required this.categoryKey,
    required this.isSelected,
    required this.onTap,
    this.questionCount,
  });

  static const _data = {
    'cricket':   _CategoryData('Cricket & Sports',  '🏏', AppColors.cricket),
    'bollywood': _CategoryData('Bollywood & OTT',   '🎬', AppColors.bollywood),
    'gk':        _CategoryData('Indian GK',         '🌍', AppColors.gk),
    'math':      _CategoryData('Rapid Math',        '🧮', AppColors.math),
    'science':   _CategoryData('Science & Tech',    '🔬', AppColors.science),
    'hindi':     _CategoryData('Hindi Wordplay',    '📝', AppColors.hindi),
  };

  // default question counts per category
  static const _counts = {
    'cricket': 10, 'bollywood': 10, 'gk': 10,
    'math': 10, 'science': 10, 'hindi': 10,
  };

  @override
  Widget build(BuildContext context) {
    final d = _data[categoryKey] ?? _data['cricket']!;
    final count = questionCount ?? _counts[categoryKey] ?? 10;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    d.color.withValues(alpha: 0.85),
                    d.color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: d.color.withValues(alpha: 0.50), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8)),
                  BoxShadow(color: d.color.withValues(alpha: 0.20), blurRadius: 40, offset: const Offset(0, 14)),
                ],
              )
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: d.color.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ambient glow blob top-right
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.color.withValues(alpha: isSelected ? 0.25 : 0.12),
                  ),
                ),
              ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji icon in container
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : d.color.withValues(alpha: 0.14),
                          boxShadow: [
                            BoxShadow(
                              color: d.color.withValues(alpha: isSelected ? 0.30 : 0.18),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            d.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: isSelected ? -3 : -2, duration: 1600.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 10),
                      Text(
                        d.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count questions',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.textMuted,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(key: ValueKey(isSelected))
          .scaleXY(
            begin: isSelected ? 0.92 : 1.0,
            end: 1.0,
            duration: 380.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}

class _CategoryData {
  final String name;
  final String emoji;
  final Color color;
  const _CategoryData(this.name, this.emoji, this.color);
}
