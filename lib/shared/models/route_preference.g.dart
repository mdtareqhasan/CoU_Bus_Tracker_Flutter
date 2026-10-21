// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutePreference _$RoutePreferenceFromJson(Map<String, dynamic> json) =>
    RoutePreference(
      routeId: (json['routeId'] as num).toInt(),
      isPinned: json['isPinned'] as bool? ?? false,
      scheduleAlertsEnabled: json['scheduleAlertsEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$RoutePreferenceToJson(RoutePreference instance) =>
    <String, dynamic>{
      'routeId': instance.routeId,
      'isPinned': instance.isPinned,
      'scheduleAlertsEnabled': instance.scheduleAlertsEnabled,
    };
