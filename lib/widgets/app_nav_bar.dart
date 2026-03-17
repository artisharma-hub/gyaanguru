import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded,        Icons.home_outlined,          'Home'),
    (Icons.today_rounded,       Icons.today_outlined,         'Daily'),
    (Icons.leaderboard_rounded, Icons.leaderboard_outlined,   'Ranks'),
    (Icons.person_rounded,      Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 68,
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: ac.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final selected = currentIndex == i;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: _NavItem(
                icon:     selected ? item.$1 : item.$2,
                label:    item.$3,
                selected: selected,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated pill with icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.32), blurRadius: 10, offset: const Offset(0, 3))]
                : [],
          ),
          child: Icon(icon, color: selected ? Colors.white : ac.textMuted, size: 22),
        )
            .animate(key: ValueKey('${label}_$selected'))
            .scaleXY(begin: selected ? 0.75 : 1.0, end: 1.0, duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 2),

        // Always-visible label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: selected ? AppColors.primary : ac.textMuted,
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: selected ? 0.2 : 0,
          ),
          child: Text(label),
        ),

        // Active dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(top: 2),
          width: selected ? 14 : 0,
          height: selected ? 3 : 0,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])
                : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
