import 'package:json_annotation/json_annotation.dart';

part 'route_preference.g.dart';

/// One rider's flags for one route, from `GET/PUT /me/route-preferences`.
///
/// The two flags are independent: [isPinned] shows the route on the home
/// screen, [scheduleAlertsEnabled] is the audience signal the backend pushes
/// schedule-change notifications to. The server stores a row only while at
/// least one flag is true — a (false, false) response means "no preference".
@JsonSerializable()
class RoutePreference {
  const RoutePreference({
    required this.routeId,
    this.isPinned = false,
    this.scheduleAlertsEnabled = false,
  });

  final int routeId;
  final bool isPinned;
  final bool scheduleAlertsEnabled;

  factory RoutePreference.fromJson(Map<String, dynamic> json) =>
      _$RoutePreferenceFromJson(json);
  Map<String, dynamic> toJson() => _$RoutePreferenceToJson(this);

  RoutePreference copyWith({bool? isPinned, bool? scheduleAlertsEnabled}) {
    return RoutePreference(
      routeId: routeId,
      isPinned: isPinned ?? this.isPinned,
      scheduleAlertsEnabled:
          scheduleAlertsEnabled ?? this.scheduleAlertsEnabled,
    );
  }

  /// No row on the server — what a fresh route starts as.
  bool get isNone => !isPinned && !scheduleAlertsEnabled;
}
