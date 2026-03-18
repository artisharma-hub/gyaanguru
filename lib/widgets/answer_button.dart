import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../services/sound_service.dart';

enum AnswerState { none, selected, correct, wrong }

class AnswerButton extends StatefulWidget {
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
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  bool _pressed = false;

  void _onTapDown(_) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    HapticFeedback.lightImpact();
    SoundService().click();
  }

  void _onTapUp(_) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;

    Color bgColor     = ac.surfaceVariant;
    Color borderColor = ac.border;
    Color textColor   = ac.textPrimary;
    Color badgeBg     = ac.border2;
    Color badgeText   = ac.textSecondary;
    List<BoxShadow> shadows = [];
    Gradient? bgGradient;

    switch (widget.state) {
      case AnswerState.selected:
        bgGradient  = LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primaryLight.withValues(alpha: 0.10),
        ]);
        bgColor     = Colors.transparent;
        borderColor = AppColors.primary;
        textColor   = context.isDark ? AppColors.primaryLight : AppColors.primary;
        badgeBg     = AppColors.primary;
        badgeText   = Colors.white;
        shadows     = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AnswerState.correct:
        bgGradient  = LinearGradient(colors: [
          AppColors.correctGreen.withValues(alpha: 0.18),
          AppColors.correctGreen.withValues(alpha: 0.07),
        ]);
        bgColor     = Colors.transparent;
        borderColor = AppColors.correctGreen;
        textColor   = AppColors.correctGreen;
        badgeBg     = AppColors.correctGreen;
        badgeText   = Colors.white;
        shadows     = [
          BoxShadow(
            color: AppColors.correctGreen.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ];
        break;
      case AnswerState.wrong:
        bgGradient  = LinearGradient(colors: [
          AppColors.wrongRed.withValues(alpha: 0.14),
          AppColors.wrongRed.withValues(alpha: 0.06),
        ]);
        bgColor     = Colors.transparent;
        borderColor = AppColors.wrongRed;
        textColor   = AppColors.wrongRed;
        badgeBg     = AppColors.wrongRed;
        badgeText   = Colors.white;
        break;
      case AnswerState.none:
        break;
    }

    final isIdle = widget.state == AnswerState.none;
    final scale  = (_pressed && isIdle) ? 0.965 : 1.0;

    Widget button = GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            gradient: bgGradient,
            color: bgGradient == null ? bgColor : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.state != AnswerState.none ? 2.0 : 1.5,
            ),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              // Option badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: widget.state != AnswerState.none
                      ? [BoxShadow(color: badgeBg.withValues(alpha: 0.4), blurRadius: 8)]
                      : [],
                ),
                child: Center(
                  child: Text(
                    widget.option,
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
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.state == AnswerState.correct)
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.correctGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.correctGreen.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
              if (widget.state == AnswerState.wrong)
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.wrongRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wrongRed.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.state == AnswerState.correct) {
      return button
          .animate()
          .scaleXY(begin: 1.0, end: 1.05, duration: 180.ms, curve: Curves.easeOut)
          .shimmer(color: AppColors.correctGreen.withValues(alpha: 0.35), duration: 400.ms)
          .then()
          .scaleXY(begin: 1.05, end: 1.0, duration: 350.ms, curve: Curves.elasticOut);
    } else if (widget.state == AnswerState.wrong) {
      return button.animate().shakeX(amount: 6, duration: 400.ms);
    } else if (widget.state == AnswerState.selected) {
      return button.animate().scaleXY(begin: 0.96, end: 1.0, duration: 180.ms, curve: Curves.easeOut);
    }

    return button;
  }
}
