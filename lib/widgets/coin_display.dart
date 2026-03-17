import 'package:flutter/material.dart';
import '../app/theme.dart';

class CoinDisplay extends StatelessWidget {
  final int coins;
  final double fontSize;

  const CoinDisplay({super.key, required this.coins, this.fontSize = 16});

  String _formatCoins(int c) {
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return '$c';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on, color: AppColors.gold, size: fontSize + 4),
        const SizedBox(width: 4),
        Text(
          _formatCoins(coins),
          style: TextStyle(
            color: AppColors.gold,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
