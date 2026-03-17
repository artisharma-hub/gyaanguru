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
    'cricket':   _CategoryData('Cricket & Sports',  Icons.sports_cricket_rounded,    AppColors.cricket),
    'bollywood': _CategoryData('Bollywood & OTT',   Icons.movie_filter_rounded,      AppColors.bollywood),
    'gk':        _CategoryData('Indian GK',         Icons.menu_book_rounded,         AppColors.gk),
    'math':      _CategoryData('Rapid Math',        Icons.functions_rounded,         AppColors.math),
    'science':   _CategoryData('Science & Tech',    Icons.biotech_rounded,           AppColors.science),
    'hindi':     _CategoryData('Hindi Wordplay',    Icons.record_voice_over_rounded, AppColors.hindi),
  };

  @override
  Widget build(BuildContext context) {
    final d = _data[categoryKey] ?? _data['cricket']!;
    final ac = context.ac;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppColors.categoryGradientRich(d.color),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: d.color.withValues(alpha: 0.42), blurRadius: 22, spreadRadius: 1, offset: const Offset(0, 8)),
                  BoxShadow(color: d.color.withValues(alpha: 0.16), blurRadius: 38, offset: const Offset(0, 16)),
                ],
              )
            : BoxDecoration(
                color: ac.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ac.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: d.color.withValues(alpha: context.isDark ? 0.12 : 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Stack(
          children: [
            if (!isSelected)
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.color.withValues(alpha: context.isDark ? 0.10 : 0.07),
                  ),
                ),
              ),
            if (!isSelected)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: d.color.withValues(alpha: 0.55), shape: BoxShape.circle),
                ),
              ),
            if (isSelected)
              Positioned(
                top: -28,
                right: -18,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.11),
                  ),
                ),
              ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIcon(d),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      d.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : ac.textPrimary,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.25,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(key: ValueKey(isSelected))
          .scaleXY(begin: isSelected ? 0.91 : 1.0, end: 1.0, duration: 380.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildIcon(_CategoryData d) {
    final iconWidget = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [d.color.withValues(alpha: 0.18), d.color.withValues(alpha: 0.07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.white.withValues(alpha: 0.22), blurRadius: 10, spreadRadius: 1)]
            : [BoxShadow(color: d.color.withValues(alpha: 0.14), blurRadius: 9, offset: const Offset(0, 3))],
      ),
      child: Icon(d.icon, color: isSelected ? Colors.white : d.color, size: 34),
    );

    if (isSelected) {
      return iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 900.ms, curve: Curves.easeInOut)
          .shimmer(color: Colors.white.withValues(alpha: 0.18), duration: 1800.ms);
    }

    return iconWidget
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1800.ms, curve: Curves.easeInOut);
  }
}

class _CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryData(this.name, this.icon, this.color);
}
