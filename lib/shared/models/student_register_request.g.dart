// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentRegisterRequest _$StudentRegisterRequestFromJson(
        Map<String, dynamic> json) =>
    StudentRegisterRequest(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      studentId: json['studentId'] as String,
      department: json['department'] as String,
      varsityBatch: json['varsityBatch'] as String,
    );

Map<String, dynamic> _$StudentRegisterRequestToJson(
        StudentRegisterRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
      'studentId': instance.studentId,
      'department': instance.department,
      'varsityBatch': instance.varsityBatch,
    };
