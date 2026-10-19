import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import 'glass_card.dart';

/// Stat card — full-bleed gradient tile with a monospace-style count and
/// a tinted icon. Use [isHero] for the 2 large cards on the dashboard;
/// otherwise the card tightens up for narrow grids.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isHero = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    final numValue = int.tryParse(value) ?? 0;
    final minHeight = isHero ? 130.0 : 96.0;

    // A hard `SizedBox(height:)` forced the value + label past the bottom edge
    // on the compact (non-hero) cards, since 96px couldn't hold the icon row,
    // the 28px count and the 12px label plus 16px of padding on each side.
    // `minHeight` keeps the intended compact look while letting the card grow
    // to fit its content, so it can no longer overflow.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.space16),
        elevation: GlassCardElevation.soft,
        glowColor: AppTheme.blueVivid,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isHero ? 40 : 36,
                  height: isHero ? 40 : 36,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.blueVivid.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: isHero ? 20 : 18),
                ),
                AnimatedSwitcher(
                  duration: Motion.durMed,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    key: ValueKey(numValue),
                    size: 14,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: numValue.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutExpo,
                  builder: (context, val, child) {
                    return Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontSize: isHero ? 34 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.6,
                        height: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Motion.enter);
  }
}
