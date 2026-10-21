// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusRoute _$BusRouteFromJson(Map<String, dynamic> json) => BusRoute(
  id: (json['id'] as num).toInt(),
  nameBn: json['nameBn'] as String?,
  nameEn: json['nameEn'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  oppositeRouteId: (json['oppositeRouteId'] as num?)?.toInt(),
  activeScheduleCount: (json['activeScheduleCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$BusRouteToJson(BusRoute instance) => <String, dynamic>{
  'id': instance.id,
  'nameBn': instance.nameBn,
  'nameEn': instance.nameEn,
  'isActive': instance.isActive,
  'oppositeRouteId': instance.oppositeRouteId,
  'activeScheduleCount': instance.activeScheduleCount,
};
