import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/schedule.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const ScheduleCard({super.key, required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = schedule.direction?.toUpperCase() == 'UP';
    final directionColor = isUp ? AppTheme.success : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        schedule.busNumber ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (schedule.busName != null)
                      Text(
                        schedule.busName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: directionColor.withOpacity(0.1),
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
                      child: Text(
                        schedule.routeDisplay,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Text(
                      schedule.displayDeparture,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
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

  Widget _buildRouteTimeline(BuildContext context) {
    return Row(
      children: [
        _TimelinePoint(label: schedule.startPoint ?? 'Start', isActive: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: AppTheme.textHint.withOpacity(0.3),
              ),
            ),
          ),
        ),
        _TimelinePoint(label: schedule.endPoint ?? 'End', isActive: true),
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
