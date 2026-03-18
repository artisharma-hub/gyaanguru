import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// Wraps any widget with a tap that plays a click sound + haptic.
/// Drop-in replacement for GestureDetector where you need audio feedback.
///
/// Usage:
///   SoundTap(onTap: () => doSomething(), child: MyButton())
class SoundTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;

  const SoundTap({
    super.key,
    required this.child,
    this.onTap,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              SoundService().click();
              onTap!();
            },
      child: child,
    );
  }
}
