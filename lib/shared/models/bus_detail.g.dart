// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusDetail _$BusDetailFromJson(Map<String, dynamic> json) => BusDetail(
  id: (json['id'] as num?)?.toInt(),
  busNumber: json['busNumber'] as String?,
  busName: json['busName'] as String?,
  category: json['category'] as String?,
  route: json['route'] as String?,
  driverName: json['driverName'] as String?,
  driverPhone: json['driverPhone'] as String?,
  busImageUrl: json['busImageUrl'] as String?,
  trackerUrl: json['trackerUrl'] as String?,
  isActive: json['isActive'] as bool?,
  schedules: (json['schedules'] as List<dynamic>?)
      ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BusDetailToJson(BusDetail instance) => <String, dynamic>{
  'id': instance.id,
  'busNumber': instance.busNumber,
  'busName': instance.busName,
  'category': instance.category,
  'route': instance.route,
  'driverName': instance.driverName,
  'driverPhone': instance.driverPhone,
  'busImageUrl': instance.busImageUrl,
  'trackerUrl': instance.trackerUrl,
  'isActive': instance.isActive,
  'schedules': instance.schedules,
};
