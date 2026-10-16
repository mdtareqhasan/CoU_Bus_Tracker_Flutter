import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/time_utils.dart';
import '../../l10n/l10n.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  final int? id;
  final int? busId;
  final String? busNumber;
  final String? busName;
  final String? category;
  final String? departureTime;
  final String? arrivalTime;
  final String? direction;
  final String? startPoint;
  final String? endPoint;
  final String? days;

  const Schedule({
    this.id,
    this.busId,
    this.busNumber,
    this.busName,
    this.category,
    this.departureTime,
    this.arrivalTime,
    this.direction,
    this.startPoint,
    this.endPoint,
    this.days,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleToJson(this);

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

  String get routeDisplay {
    if (startPoint != null && endPoint != null) {
      return '$startPoint → $endPoint';
    }
    return '';
  }

  String get displayDeparture {
    return TimeUtils.formatTime(departureTime);
  }
}
