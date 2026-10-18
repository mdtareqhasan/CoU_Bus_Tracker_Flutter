import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Single pill primitive used for category chips, status badges, live
/// indicators, and direction (UP / DOWN) tags.
///
/// Replaces the 4 different pill implementations that were scattered
/// across `bus_card.dart`, `schedule_card.dart`, `bus_detail_screen.dart`,
/// and `live_indicator.dart`.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppTheme.bluePrimary,
    this.tonal = true,
    this.outline = false,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool tonal;
  final bool outline;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  /// Pre-built live pill (red dot + LIVE label).
  const AppPill.live({super.key})
      : label = 'LIVE',
        color = AppTheme.error,
        tonal = true,
        outline = false,
        dense = true,
        selected = false,
        onTap = null,
        icon = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = () {
      if (outline) return Colors.transparent;
      if (tonal) return color.withValues(alpha: 0.14);
      if (selected) return color;
      return color.withValues(alpha: 0.10);
    }();

    final fg = () {
      if (selected && !outline && !tonal) return Colors.white;
      if (outline) return color;
      return color;
    }();

    final border = outline
        ? Border.all(color: color.withValues(alpha: 0.55), width: 1.2)
        : null;

    final hPad = dense ? AppTheme.space8 : AppTheme.space12;
    final vPad = dense ? 4.0 : 6.0;
    final fontSize = dense ? 11.0 : 12.0;

    return Semantics(
      label: '$label, ${_hexFromColor(color)}',
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: AnimatedContainer(
            duration: Motion.durFast,
            curve: Motion.enter,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: border,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 1, color: fg),
                  SizedBox(width: dense ? 4 : 6),
                ],
                if (label == 'LIVE') ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: fg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _hexFromColor(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}
