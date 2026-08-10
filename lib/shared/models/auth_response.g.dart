// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['accessToken'] as String?,
      tokenType: json['tokenType'] as String?,
      displayName: json['adminName'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'tokenType': instance.tokenType,
      'adminName': instance.displayName,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
    };
