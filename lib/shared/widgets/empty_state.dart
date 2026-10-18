import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

/// Canonical empty state. Use this everywhere a list is empty —
/// no more hand-rolled `Center(Column(Icon, Text))` blocks.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.ctaLabel,
    this.onCtaPressed,
    this.padding = const EdgeInsets.all(AppTheme.space48),
  });

  final String title;
  final String? body;
  final IconData icon;
  final Color? iconColor;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ic = iconColor ?? AppTheme.bluePrimary;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ic.withValues(alpha: isDark ? 0.18 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: ic.withValues(alpha: 0.85)),
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Motion.enter)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Motion.bounce,
                ),
            const SizedBox(height: AppTheme.space20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.15, end: 0, curve: Motion.enter),
            if (body != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white60
                          : AppTheme.textSecondary,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
            ],
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: AppTheme.space24),
              FilledButton.icon(
                onPressed: onCtaPressed,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(ctaLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: ic,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space24,
                    vertical: AppTheme.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}
