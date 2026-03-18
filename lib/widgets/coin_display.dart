import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Animated coin display with continuous Y-axis spin + glow.
class CoinDisplay extends StatefulWidget {
  final int coins;
  final double fontSize;
  final bool spin;

  const CoinDisplay({
    super.key,
    required this.coins,
    this.fontSize = 16,
    this.spin = true,
  });

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.spin) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(int c) {
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return '$c';
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.fontSize + 10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            // coin-flip: scaleX follows |cos(angle)|, face flips at 0
            final angle = _ctrl.value * 2 * math.pi;
            final scaleX = math.cos(angle).abs().clamp(0.05, 1.0);
            // pulse glow: brightens at 0 and π (front face)
            final glowAlpha = (0.35 + 0.3 * (1 - math.cos(angle).abs())).clamp(0.0, 1.0);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(scaleX, 1.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: glowAlpha),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: size * 0.6,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: widget.fontSize * 0.35),
        Text(
          _fmt(widget.coins),
          style: TextStyle(
            color: AppColors.gold,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: widget.fontSize,
          ),
        ),
      ],
    );
  }
}
