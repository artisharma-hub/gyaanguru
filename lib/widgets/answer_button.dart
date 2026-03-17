import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

enum AnswerState { none, selected, correct, wrong }

class AnswerButton extends StatelessWidget {
  final String label;
  final String option;
  final VoidCallback? onTap;
  final AnswerState state;

  const AnswerButton({
    super.key,
    required this.label,
    required this.option,
    required this.onTap,
    this.state = AnswerState.none,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor     = AppColors.surfaceVariant;
    Color borderColor = AppColors.border;
    Color textColor   = AppColors.textPrimary;
    Color badgeBg     = AppColors.surfaceVariant;
    Color badgeText   = AppColors.textSecondary;
    List<BoxShadow> shadows = [];

    switch (state) {
      case AnswerState.selected:
        bgColor     = AppColors.primary.withValues(alpha: 0.2);
        borderColor = AppColors.primaryLight;
        badgeBg     = AppColors.primary;
        badgeText   = Colors.white;
        shadows     = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ];
        break;
      case AnswerState.correct:
        bgColor     = AppColors.correctGreen.withValues(alpha: 0.15);
        borderColor = AppColors.correctGreen;
        textColor   = AppColors.correctGreen;
        badgeBg     = AppColors.correctGreen;
        badgeText   = Colors.white;
        shadows     = [
          BoxShadow(
            color: AppColors.correctGreen.withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ];
        break;
      case AnswerState.wrong:
        bgColor     = AppColors.wrongRed.withValues(alpha: 0.15);
        borderColor = AppColors.wrongRed;
        textColor   = AppColors.wrongRed;
        badgeBg     = AppColors.wrongRed;
        badgeText   = Colors.white;
        break;
      case AnswerState.none:
        break;
    }

    Widget button = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            // Option badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    color: badgeText,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state == AnswerState.correct)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.correctGreen, size: 18),
            if (state == AnswerState.wrong)
              const Icon(Icons.cancel_rounded,
                  color: AppColors.wrongRed, size: 18),
          ],
        ),
      ),
    );

    if (state == AnswerState.correct) {
      return button
          .animate()
          .shimmer(color: AppColors.correctGreen.withValues(alpha: 0.3), duration: 400.ms);
    } else if (state == AnswerState.wrong) {
      return button.animate().shakeX(amount: 4, duration: 300.ms);
    } else if (state == AnswerState.selected) {
      return button.animate().scaleXY(begin: 0.97, end: 1.0, duration: 150.ms);
    }

    return button;
  }
}
