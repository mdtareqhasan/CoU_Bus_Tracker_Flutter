// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  email: json['email'] as String?,
  rollNumber: json['rollNumber'] as String?,
  department: json['department'] as String?,
  session: json['session'] as String?,
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
  'rollNumber': instance.rollNumber,
  'department': instance.department,
  'session': instance.session,
  'idCardImageUrl': instance.idCardImageUrl,
  'isEduMail': instance.isEduMail,
  'isVerified': instance.isVerified,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt?.toIso8601String(),
};
