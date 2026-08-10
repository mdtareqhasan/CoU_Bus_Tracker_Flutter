// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      studentId: json['studentId'] as String?,
      department: json['department'] as String?,
      varsityBatch: json['varsityBatch'] as String?,
      idCardImageUrl: json['idCardImageUrl'] as String?,
      isEduMail: json['isEduMail'] as bool?,
      isVerified: json['isVerified'] as bool?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'studentId': instance.studentId,
      'department': instance.department,
      'varsityBatch': instance.varsityBatch,
      'idCardImageUrl': instance.idCardImageUrl,
      'isEduMail': instance.isEduMail,
      'isVerified': instance.isVerified,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
