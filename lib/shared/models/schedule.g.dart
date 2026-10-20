// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schedule _$ScheduleFromJson(Map<String, dynamic> json) => Schedule(
  id: (json['id'] as num?)?.toInt(),
  busId: (json['busId'] as num?)?.toInt(),
  busNumber: json['busNumber'] as String?,
  busNameBn: json['busNameBn'] as String?,
  busNameEn: json['busNameEn'] as String?,
  category: json['category'] as String?,
  departureTime: json['departureTime'] as String?,
  arrivalTime: json['arrivalTime'] as String?,
  direction: json['direction'] as String?,
  routeId: (json['routeId'] as num?)?.toInt(),
  routeNameBn: json['routeNameBn'] as String?,
  routeNameEn: json['routeNameEn'] as String?,
  days: json['days'] as String?,
);

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
  'id': instance.id,
  'busId': instance.busId,
  'busNumber': instance.busNumber,
  'busNameBn': instance.busNameBn,
  'busNameEn': instance.busNameEn,
  'category': instance.category,
  'departureTime': instance.departureTime,
  'arrivalTime': instance.arrivalTime,
  'direction': instance.direction,
  'routeId': instance.routeId,
  'routeNameBn': instance.routeNameBn,
  'routeNameEn': instance.routeNameEn,
  'days': instance.days,
};
