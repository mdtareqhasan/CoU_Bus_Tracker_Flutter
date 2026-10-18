import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../models/bus.dart';
import 'glass_card.dart';
import 'live_dot.dart';
import 'app_pill.dart';

class BusCard extends StatelessWidget {
  final Bus bus;
  final String route;
  final VoidCallback onTap;
  final bool showLive;

  const BusCard({
    super.key,
    required this.bus,
    required this.route,
    required this.onTap,
    this.showLive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.colorForCategory(bus.category);
    final isLive = bus.trackerUrl != null && bus.trackerUrl!.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.space14),
      elevation: GlassCardElevation.soft,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bus.busNumber ?? 'N/A',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (bus.busName != null && bus.busName!.isNotEmpty) ...[
                      const SizedBox(width: AppTheme.space8),
                      Flexible(
                        child: Text(
                          bus.busName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isLive && showLive)
                      const LiveDot(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 13,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        route,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    AppPill(
                      label: bus.categoryLabel,
                      color: color,
                      dense: true,
                    ),
                    if (isLive && showLive) ...[
                      const SizedBox(width: AppTheme.space4),
                      AppPill.live(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.bluePrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.bluePrimary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
