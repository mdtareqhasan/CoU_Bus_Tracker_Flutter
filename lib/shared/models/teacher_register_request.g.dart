// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherRegisterRequest _$TeacherRegisterRequestFromJson(
  Map<String, dynamic> json,
) => TeacherRegisterRequest(
  name: json['name'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  designation: json['designation'] as String?,
  department: json['department'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$TeacherRegisterRequestToJson(
  TeacherRegisterRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'password': instance.password,
  'designation': instance.designation,
  'department': instance.department,
  'phone': instance.phone,
};
