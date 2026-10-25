import 'package:json_annotation/json_annotation.dart';

import '../../l10n/l10n.dart';

part 'bus_route.g.dart';

/// One direction of a bus route, as served by the public `GET /routes`.
///
/// One row = one physical direction (e.g. "Kandirpar → Campus"). A route that
/// runs both ways is stored as two rows pointing at each other via
/// [oppositeRouteId]; the client pairs them up for display and must never
/// label a pair "Both ways" — see `groupRoutes` in the routes provider.
@JsonSerializable()
class BusRoute {
  const BusRoute({
    required this.id,
    this.nameBn,
    this.nameEn,
    this.isActive = true,
    this.oppositeRouteId,
    this.activeScheduleCount,
    this.activeScheduleCountsByCategory,
  });

  final int id;
  final String? nameBn;
  final String? nameEn;

  /// Retired rows are served only to admins; the public listing carries
  /// active ones. Kept nullable-default so older cached JSON still parses.
  @JsonKey(defaultValue: true)
  final bool isActive;

  /// The route running the opposite direction, or `null` for a one-way route.
  /// Both sides always point at each other (server enforces reciprocity), but
  /// the partner may be missing from a listing if it was retired meanwhile.
  final int? oppositeRouteId;

  /// Active trips on this direction — labels an empty route ("no trips yet")
  /// without a second round trip.
  final int? activeScheduleCount;

  /// The same trips broken down by bus category, e.g. `{TEACHER: 2, BLUE: 1}`.
  ///
  /// The listing endpoint is public and never learns the caller's role, so
  /// the role gate has to happen here: the client sums only the categories
  /// its signed-in rider may ride ([visibleTripCount]). Absent from listings
  /// served before the breakdown existed and from old cache entries — see
  /// [visibleTripCount] for how that degrades.
  final Map<String, int>? activeScheduleCountsByCategory;

  factory BusRoute.fromJson(Map<String, dynamic> json) =>
      _$BusRouteFromJson(json);
  Map<String, dynamic> toJson() => _$BusRouteToJson(this);

  /// Route name in the active app language, falling back to the other
  /// language when only one is set (same rule as `Schedule.localizedRouteName`).
  String? get localizedName {
    final preferred = L10n.locale.languageCode == 'bn' ? nameBn : nameEn;
    final fallback = L10n.locale.languageCode == 'bn' ? nameEn : nameBn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  /// True when this direction is stored as one-way (no partner row at all).
  /// A missing *partner* while [oppositeRouteId] is set is a different case —
  /// the corridor exists but the other side isn't in this listing.
  bool get isOneWay => oppositeRouteId == null;

  /// Trips on this direction a rider allowed to ride [allowedCategories] may
  /// actually take.
  ///
  /// Falls back to [activeScheduleCount] when the server sent no breakdown —
  /// an older backend, or a listing cached before this field existed — so a
  /// missing field degrades to today's behaviour instead of counting nothing.
  int? visibleTripCount(Set<String> allowedCategories) {
    final byCategory = activeScheduleCountsByCategory;
    if (byCategory == null) return activeScheduleCount;

    var visible = 0;
    for (final entry in byCategory.entries) {
      if (allowedCategories.contains(entry.key.toUpperCase())) {
        visible += entry.value;
      }
    }
    return visible;
  }

  /// Whether a rider who may ride [allowedCategories] should be shown this
  /// direction at all.
  ///
  /// A direction with **no** trips stays listed — "No trips yet" is its
  /// honest label and the empty-route copy exists for it. A direction that
  /// *does* carry trips, none of them the rider's, is the other role's
  /// schedule, so it is hidden rather than teased.
  bool shouldListFor(Set<String> allowedCategories) {
    final total = activeScheduleCount;
    if (total == null || total <= 0) return true;
    return (visibleTripCount(allowedCategories) ?? 0) > 0;
  }
}
