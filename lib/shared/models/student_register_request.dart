import 'package:json_annotation/json_annotation.dart';

part 'student_register_request.g.dart';

@JsonSerializable()
class StudentRegisterRequest {
  final String name;
  final String email;
  final String password;
  @JsonKey(name: 'studentId')
  final String studentId;
  final String department;
  @JsonKey(name: 'varsityBatch')
  final String varsityBatch;

  const StudentRegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.studentId,
    required this.department,
    required this.varsityBatch,
  });

  factory StudentRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$StudentRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StudentRegisterRequestToJson(this);
}
