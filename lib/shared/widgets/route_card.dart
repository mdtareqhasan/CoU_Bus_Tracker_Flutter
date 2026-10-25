import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../models/bus_route.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/buses/buses_provider.dart';
import '../../features/routes/routes_provider.dart';

/// One card on the Route tab (and the home "My Routes" list).
///
/// A linked corridor renders as a single card holding two rows — one per
/// physical direction — because riders think of it as one way to ride there
/// and back. Each row is tappable and lands on that direction's detail page.
/// A one-way route renders a single row plus a badge.
///
/// Deliberately never says "Both ways": a pair is two one-direction trips,
/// and each row keeps its own name, arrow and trip count.
///
/// The trip count is the *rider's* count, not the route's: it sums only the
/// categories the signed-in role may ride (see [BusRoute.visibleTripCount]).
/// The card watches [authProvider] itself so no call site can forget the
/// gate — the same lesson as the route detail page.
class RouteCard extends ConsumerWidget {
  const RouteCard({
    super.key,
    required this.group,
    required this.onTap,
    this.flat = false,
  });

  final RouteGroup group;

  /// Called with the tapped direction's route id.
  final ValueChanged<int> onTap;

  /// Flat cards drop the shadow/surface (used inside a list on a colored
  /// background); default cards float like StatCard/ScheduleCard.
  final bool flat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(
      flat ? AppTheme.radiusMedium : AppTheme.radiusLarge,
    );
    final allowed = allowedCategoriesForRole(ref.watch(authProvider).role);

    final rows = <Widget>[
      _RouteRow(
        route: group.route,
        showOneWayBadge: group.isOneWay,
        allowedTripCategories: allowed,
        onTap: () => onTap(group.route.id),
      ),
      if (group.opposite != null)
        _RouteRow(
          route: group.opposite!,
          showOneWayBadge: false,
          allowedTripCategories: allowed,
          onTap: () => onTap(group.opposite!.id),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: flat
            ? Colors.transparent
            : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
        borderRadius: radius,
        boxShadow: flat ? null : AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: AppTheme.space16,
                  endIndent: AppTheme.space16,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One direction inside a [RouteCard]: arrow, name, trip count, badge.
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.route,
    required this.showOneWayBadge,
    required this.allowedTripCategories,
    required this.onTap,
  });

  final BusRoute route;
  final bool showOneWayBadge;

  /// The categories the signed-in role may ride — the trip label counts only
  /// these, so a student is never shown a teacher bus's trips.
  final Set<String> allowedTripCategories;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = route.localizedName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            // Direction glyph. The route NAME carries the direction
            // ("X → Y" / "Y → X"), so both rows share the same forward
            // arrow rather than mirroring it — mirroring would contradict
            // the name on the opposite row.
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '—',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tripCountLabel(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showOneWayBadge) ...[
              const SizedBox(width: AppTheme.space8),
              _OneWayBadge(),
            ],
            const SizedBox(width: AppTheme.space8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  /// "12 trips" / "No trips yet" — from the listing's per-category counts, so
  /// the card never fires a second request and never claims the other role's
  /// trips as the rider's. A listing served before the breakdown existed
  /// falls back to the route total (see [BusRoute.visibleTripCount]).
  String _tripCountLabel(BuildContext context) {
    final count = route.visibleTripCount(allowedTripCategories);
    if (count == null || count <= 0) return context.l10n.routeNoTrips;
    return context.l10n.routeTripCount(count);
  }
}

class _OneWayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        context.l10n.routeOneWay,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
