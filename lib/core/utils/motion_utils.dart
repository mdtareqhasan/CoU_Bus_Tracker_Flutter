import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized motion helper that respects the user's
/// `MediaQuery.disableAnimations` (system reduced-motion) setting.
///
/// Use this anywhere you'd call `.animate()` from `flutter_animate` so the
/// animations short-circuit cleanly when reduced motion is on.
extension RespectMotion on Widget {
  /// Animate a widget only if motion is allowed. When reduced motion is on
  /// the widget is returned untouched.
  Widget animateIfAllowed({
    bool reducedMotion(BuildContext context) => false,
  }) {
    return Builder(
      builder: (context) {
        final disable = MediaQuery.of(context).disableAnimations;
        if (disable) return this;
        return animate();
      },
    );
  }
}
