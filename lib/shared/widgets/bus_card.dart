import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/bus.dart';
import 'live_indicator.dart';

class BusCard extends StatelessWidget {
  final Bus bus;
  final String route;
  final VoidCallback onTap;

  const BusCard({
    super.key,
    required this.bus,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(bus.category);

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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: categoryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bus.busNumber ?? 'N/A',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (bus.busName != null &&
                              bus.busName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              bus.busName!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const Spacer(),
                          if (bus.trackerUrl != null &&
                              bus.trackerUrl!.isNotEmpty)
                            const LiveIndicator(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            size: 14,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          bus.categoryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toUpperCase()) {
      case 'BLUE':
        return AppTheme.primaryBlue;
      case 'RED':
        return AppTheme.error;
      case 'TEACHER':
        return Colors.deepPurple;
      case 'OFFICER':
        return Colors.teal;
      case 'STAFF':
        return Colors.orange;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
