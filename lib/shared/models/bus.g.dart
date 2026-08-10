// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bus _$BusFromJson(Map<String, dynamic> json) => Bus(
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
    );

Map<String, dynamic> _$BusToJson(Bus instance) => <String, dynamic>{
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
    };
