import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/sound_service.dart';

// Cyan-blue active pill colors (vibrant, contrasts against dark indigo bar)
const _cyanStart = Color(0xFF00B4D8);
const _cyanEnd   = Color(0xFF48CAE4);

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
    return Padding(
      // Floating margin — lifts bar off screen edge
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          // Dark indigo-blue opaque capsule
          color: const Color(0xFF160E38),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
          boxShadow: [
            // Primary purple outer glow
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.30),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            // Cyan active glow (always-on subtle tint)
            BoxShadow(
              color: _cyanStart.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            // Depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
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
                onTap: () { SoundService().click(); onTap(i); },
                behavior: HitTestBehavior.opaque,
                child: _NavItem(
                  activeIcon:   item.$1,
                  inactiveIcon: item.$2,
                  label:        item.$3,
                  selected:     selected,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        // Pill expands horizontally to fit icon + label when active
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_cyanStart, _cyanEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _cyanStart.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _cyanStart.withValues(alpha: 0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — filled when active, outlined when inactive
            Icon(
              selected ? activeIcon : inactiveIcon,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.38),
              size: 20,
            ),

            // Label — Flexible prevents overflow when tab width is tight
            Flexible(
              child: AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            ),
          ],
        ),
      )
          .animate(key: ValueKey('${label}_$selected'))
          .scaleXY(
            begin: selected ? 0.82 : 1.0,
            end: 1.0,
            duration: 380.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}
