import 'package:flutter/material.dart';
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
    'cricket':   _CategoryData('Cricket & Sports', 'assets/images/cat_cricket.png',   AppColors.cricket),
    'bollywood': _CategoryData('Bollywood & OTT',  'assets/images/cat_bollywood.png', AppColors.bollywood),
    'gk':        _CategoryData('Indian GK',        'assets/images/cat_gk.png',        AppColors.gk),
    'math':      _CategoryData('Rapid Math',       'assets/images/cat_math.png',      AppColors.math),
    'science':   _CategoryData('Science & Tech',   'assets/images/cat_science.png',   AppColors.science),
    'hindi':     _CategoryData('Hindi Wordplay',   'assets/images/cat_hindi.png',     AppColors.hindi),
  };

  static const _counts = {
    'cricket': 10, 'bollywood': 10, 'gk': 10,
    'math': 10,    'science': 10,   'hindi': 10,
  };

  @override
  Widget build(BuildContext context) {
    final d     = _data[categoryKey] ?? _data['cricket']!;
    final count = questionCount ?? _counts[categoryKey] ?? 10;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    d.color.withValues(alpha: 0.65),
                    d.color.withValues(alpha: 0.30),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? d.color.withValues(alpha: 0.80)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: d.color.withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: d.color.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image asset in a soft glow container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : d.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.asset(
                d.imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.quiz_rounded,
                  color: d.color,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              d.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count questions',
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.80)
                    : Colors.white.withValues(alpha: 0.45),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final String imagePath;
  final Color color;
  const _CategoryData(this.name, this.imagePath, this.color);
}
