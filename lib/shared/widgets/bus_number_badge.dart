import 'package:flutter/material.dart';

/// Bus registration number shown like a license plate: a small bordered
/// plate with an icon, so it reads as a plate number and not as a name.
///
/// Use [onDark] on coloured/gradient backgrounds (e.g. the bus page hero).
class BusNumberBadge extends StatelessWidget {
  const BusNumberBadge({
    super.key,
    required this.number,
    this.onDark = false,
    this.fontSize = 11,
  });

  final String number;
  final bool onDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = onDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.6,
        vertical: fontSize * 0.25,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: onDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: base.withValues(alpha: onDark ? 0.6 : 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_rounded, // swap for any icon you prefer
            size: fontSize + 3,
            color: base.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            number,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: base,
            ),
          ),
        ],
      ),
    );
  }
}
