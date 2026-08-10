import 'package:json_annotation/json_annotation.dart';

part 'teacher_register_request.g.dart';

@JsonSerializable()
class TeacherRegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? designation;
  final String? department;
  final String? phone;

  const TeacherRegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.designation,
    this.department,
    this.phone,
  });

  factory TeacherRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$TeacherRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherRegisterRequestToJson(this);
}
