import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Frosted-glass card primitive. The single source of truth for the
/// "lifted card" look across the app.
///
/// Use [GlassCard] as the shell for any list item, info panel, or surface
/// that needs the polished glass + soft shadow treatment. No screen may
/// hand-roll a `Container(decoration: BoxDecoration(...))` to do this job.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppTheme.radiusLG,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.elevation = GlassCardElevation.soft,
    this.glowColor,
    this.onTap,
    this.onLongPress,
    this.height,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final GlassCardElevation elevation;
  final Color? glowColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppTheme.surfaceDarkElevated : AppTheme.surface);
    final borderC = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0x0F0F172A));

    final shadows = switch (elevation) {
      GlassCardElevation.flat => const <BoxShadow>[],
      GlassCardElevation.soft => AppTheme.shadowXS,
      GlassCardElevation.medium => AppTheme.shadowSM,
      GlassCardElevation.large => AppTheme.shadowMD,
      GlassCardElevation.glow => [
          ...AppTheme.shadowSM,
          BoxShadow(
            color: (glowColor ?? AppTheme.blueVivid).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -2,
          ),
        ],
    };

    final card = AnimatedContainer(
      duration: Motion.durMed,
      curve: Motion.enter,
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderC, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return card;
  }
}

enum GlassCardElevation {
  flat,
  soft,
  medium,
  large,
  glow,
}
