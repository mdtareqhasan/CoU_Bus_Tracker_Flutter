import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Fixed-height aurora gradient header used in Home dashboard and as the
/// leading band of list screens (Buses, Schedules). Identical visual
/// language to [AppAppBar], but rendered as a `SliverToBoxAdapter`'s
/// `Container` rather than a `SliverAppBar`.
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.child,
    this.height = 220,
    this.padding = const EdgeInsets.fromLTRB(
      AppTheme.space24,
      AppTheme.space48,
      AppTheme.space24,
      AppTheme.space24,
    ),
    this.bottomRadius = AppTheme.radius2XL,
    this.showGlow = true,
    this.systemOverlayStyle = SystemUiOverlayStyle.light,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final double bottomRadius;
  final bool showGlow;
  final SystemUiOverlayStyle systemOverlayStyle;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlayStyle,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: AppTheme.auroraHeaderGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(bottomRadius),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showGlow) ...[
                Positioned(
                  top: -50,
                  right: -40,
                  child: _GlowBlob(
                    size: 220,
                    color: AppTheme.cyanBright.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -40,
                  child: _GlowBlob(
                    size: 240,
                    color: AppTheme.indigoDeep.withValues(alpha: 0.45),
                  ),
                ),
              ],
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
