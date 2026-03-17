import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

class CategoryCard extends StatelessWidget {
  final String categoryKey;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.categoryKey,
    required this.isSelected,
    required this.onTap,
  });

  static const _data = {
    'cricket':   _CategoryData('Cricket & Sports',  Icons.sports_cricket_rounded, AppColors.cricket),
    'bollywood': _CategoryData('Bollywood & OTT',   Icons.movie_rounded,          AppColors.bollywood),
    'gk':        _CategoryData('Indian GK',         Icons.public_rounded,         AppColors.gk),
    'math':      _CategoryData('Rapid Math',        Icons.calculate_rounded,      AppColors.math),
    'science':   _CategoryData('Science & Tech',    Icons.science_rounded,        AppColors.science),
    'hindi':     _CategoryData('Hindi Wordplay',    Icons.translate_rounded,      AppColors.hindi),
  };

  @override
  Widget build(BuildContext context) {
    final d = _data[categoryKey] ?? _data['cricket']!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppColors.categoryGradient(d.color),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: d.color.withValues(alpha: 0.55),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ],
              )
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
        child: Stack(
          children: [
            // Top-right accent dot when not selected
            if (!isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Content — Positioned.fill so mainAxisAlignment.center truly centers
            Positioned.fill(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon circle with pulse animation when not selected
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : d.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: d.color.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    d.icon,
                    color: isSelected ? Colors.white : d.color,
                    size: 38,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .scaleXY(
                      begin: 1.0,
                      end: isSelected ? 1.06 : 1.04,
                      duration: 1400.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    d.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            ),  // Positioned.fill
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scaleXY(end: 1.04, duration: 200.ms),
    );
  }
}

class _CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryData(this.name, this.icon, this.color);
}
