import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/schedule.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;
  final bool flat;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onTap,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = schedule.direction?.toUpperCase() == 'UP';
    final directionColor = isUp ? AppTheme.success : AppTheme.warning;

    final radius = BorderRadius.circular(
      flat ? AppTheme.radiusMedium : AppTheme.radiusLarge,
    );

    // Localized bus name; bus number only as a fallback when there is no name.
    final name = schedule.localizedBusName;
    final number = schedule.busNumber;
    final hasName = name != null && name.trim().isNotEmpty;
    final hasNumber = number != null && number.trim().isNotEmpty;
    final title = hasName ? name : (hasNumber ? number : null);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: flat
            ? Colors.transparent
            : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
        borderRadius: radius,
        // Outlined card style: a 1px border instead of a drop shadow.
        border: Border.all(
          color: AppTheme.textHint.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: title != null
                          ? Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: directionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: directionColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.directionLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: directionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 16,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // No maxLines/ellipsis: this is the schedule's route name — wrap, never truncate.
                      child: Text(
                        schedule.routeDisplay,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // Localized 12-hour time (bn gets period words +
                      // Bengali digits), "Not scheduled" when absent.
                      schedule.displayDeparture,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.days ?? 'All Days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIP: start/end timeline for the route — not wired into the card yet.
  // Stops are parsed out of the localized route name ("A → B → C").
  // ignore: unused_element
  Widget _buildRouteTimeline(BuildContext context) {
    final stops = schedule.routeDisplay
        .split('→')
        .map((stop) => stop.trim())
        .where((stop) => stop.isNotEmpty)
        .toList();
    return Row(
      children: [
        _TimelinePoint(
          label: stops.isNotEmpty ? stops.first : 'Start',
          isActive: true,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: AppTheme.textHint.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        _TimelinePoint(
          label: stops.length > 1 ? stops.last : 'End',
          isActive: true,
        ),
      ],
    );
  }
}

class _TimelinePoint extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TimelinePoint({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryBlue : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBlue, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 3;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
