import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

/// Live status dot — the single canonical implementation of the
/// pulsing "live" indicator used across the app.
///
/// Use [LiveDot] for any element that needs to signal "this bus is
/// tracked right now" (bus card, bus detail header, dashboard strip).
class LiveDot extends StatelessWidget {
  const LiveDot({
    super.key,
    this.color = AppTheme.success,
    this.size = 8.0,
    this.slow = false,
    this.showPulse = true,
  });

  final Color color;
  final double size;
  final bool slow;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final dur = slow ? 1600.ms : 1200.ms;

    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (!showPulse) return dot;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo (pulse outward + fade)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: dur,
                begin: const Offset(1, 1),
                end: const Offset(2.2, 2.2),
              )
              .fade(
                duration: dur,
                begin: 0.6,
                end: 0.0,
              ),
          dot,
        ],
      ),
    );
  }
}
