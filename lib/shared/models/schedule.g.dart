// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schedule _$ScheduleFromJson(Map<String, dynamic> json) => Schedule(
  id: (json['id'] as num?)?.toInt(),
  busId: (json['busId'] as num?)?.toInt(),
  busNumber: json['busNumber'] as String?,
  busName: json['busName'] as String?,
  category: json['category'] as String?,
  departureTime: json['departureTime'] as String?,
  arrivalTime: json['arrivalTime'] as String?,
  direction: json['direction'] as String?,
  startPoint: json['startPoint'] as String?,
  endPoint: json['endPoint'] as String?,
  days: json['days'] as String?,
);

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
  'id': instance.id,
  'busId': instance.busId,
  'busNumber': instance.busNumber,
  'busName': instance.busName,
  'category': instance.category,
  'departureTime': instance.departureTime,
  'arrivalTime': instance.arrivalTime,
  'direction': instance.direction,
  'startPoint': instance.startPoint,
  'endPoint': instance.endPoint,
  'days': instance.days,
};
