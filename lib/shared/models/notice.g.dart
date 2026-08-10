// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notice _$NoticeFromJson(Map<String, dynamic> json) => Notice(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      body: json['body'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$NoticeToJson(Notice instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };
