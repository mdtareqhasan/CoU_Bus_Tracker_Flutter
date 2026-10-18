import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/schedule.dart';
import 'glass_card.dart';
import 'live_dot.dart';
import 'app_pill.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;
  final bool compact;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = schedule.direction?.toUpperCase() == 'UP';
    final directionColor =
        isUp ? AppTheme.success : AppTheme.warning;

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: compact ? AppTheme.space12 : AppTheme.space14,
      ),
      elevation: GlassCardElevation.soft,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left timeline rail: filled dot → dashed line
          SizedBox(
            width: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.bluePrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          // Bus number block
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            decoration: BoxDecoration(
              color: AppTheme.bluePrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.busNumber ?? '—',
                  style: const TextStyle(
                    color: AppTheme.bluePrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact && schedule.busName != null)
                  Text(
                    schedule.busName!,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          // Route + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        schedule.routeDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.92)
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppTheme.textHint.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule.days ?? 'All Days',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    AppPill(
                      label: schedule.directionLabel,
                      icon: isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: directionColor,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                schedule.displayDeparture,
                style: TextStyle(
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.bluePrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
