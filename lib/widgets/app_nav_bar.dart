import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded,        'Home'),
    (Icons.today_rounded,       'Daily'),
    (Icons.leaderboard_rounded, 'Ranks'),
    (Icons.person_rounded,      'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.$1,
                      color: selected ? Colors.white : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  if (!selected)
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
