import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/time_utils.dart';
import '../../l10n/l10n.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  final int? id;
  final int? busId;
  final String? busNumber;
  final String? busNameBn;
  final String? busNameEn;
  final String? category;
  final String? departureTime;
  final String? arrivalTime;
  final String? direction;
  final int? routeId;
  final String? routeNameBn;
  final String? routeNameEn;
  final String? days;

  const Schedule({
    this.id,
    this.busId,
    this.busNumber,
    this.busNameBn,
    this.busNameEn,
    this.category,
    this.departureTime,
    this.arrivalTime,
    this.direction,
    this.routeId,
    this.routeNameBn,
    this.routeNameEn,
    this.days,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleToJson(this);

  /// Bus name in the active app language, falling back to the other language.
  String? get localizedBusName {
    final preferred = L10n.locale.languageCode == 'bn' ? busNameBn : busNameEn;
    final fallback = L10n.locale.languageCode == 'bn' ? busNameEn : busNameBn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  /// Route name in the active app language, falling back to the other
  /// language. A bus runs different routes at different times of day, so the
  /// route belongs to the schedule, not the bus.
  String? get localizedRouteName {
    final preferred = L10n.locale.languageCode == 'bn' ? routeNameBn : routeNameEn;
    final fallback = L10n.locale.languageCode == 'bn' ? routeNameEn : routeNameBn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String get directionLabel {
    switch (direction?.toUpperCase()) {
      case 'UP':
        return L10n.current.scheduleDirectionToCampus;
      case 'DOWN':
        return L10n.current.scheduleDirectionFromCampus;
      default:
        return direction ?? '';
    }
  }

  String get displayArrival {
    if (arrivalTime != null && arrivalTime!.isNotEmpty) return arrivalTime!;
    return L10n.current.timeNotScheduled;
  }

  String get routeDisplay => localizedRouteName ?? '';

  String get displayDeparture {
    return TimeUtils.formatTime(departureTime);
  }
}
