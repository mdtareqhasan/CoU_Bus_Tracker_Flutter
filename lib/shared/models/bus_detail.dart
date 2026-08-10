import 'package:json_annotation/json_annotation.dart';
import 'bus.dart';
import 'schedule.dart';

part 'bus_detail.g.dart';

@JsonSerializable()
class BusDetail extends Bus {
  final List<Schedule>? schedules;

  const BusDetail({
    super.id,
    super.busNumber,
    super.busName,
    super.category,
    super.route,
    super.driverName,
    super.driverPhone,
    super.busImageUrl,
    super.trackerUrl,
    super.isActive,
    this.schedules,
  });

  factory BusDetail.fromJson(Map<String, dynamic> json) =>
      _$BusDetailFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BusDetailToJson(this);
}
