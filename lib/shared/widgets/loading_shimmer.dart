import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme.dart';

/// Shimmer skeleton primitive. Use this for any loading state — no more
/// hand-rolled `Shimmer.fromColors(Container(...))` blocks.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    this.height = 96,
    this.width,
    this.borderRadius = AppTheme.radiusLG,
    this.margin = EdgeInsets.zero,
    this.itemCount = 1,
    this.itemSpacing = AppTheme.space12,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final int itemCount;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final high = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    final bar = Shimmer.fromColors(
      baseColor: base,
      highlightColor: high,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        margin: margin,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );

    if (itemCount <= 1) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < itemCount; i++) ...[
          if (i > 0) SizedBox(height: itemSpacing),
          bar,
        ],
      ],
    );
  }
}
