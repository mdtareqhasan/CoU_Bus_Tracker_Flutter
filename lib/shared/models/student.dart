import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  final int? id;
  final String? name;
  final String? email;
  final String? studentId;
  final String? department;
  final String? varsityBatch;
  final String? idCardImageUrl;
  final bool? isEduMail;
  final bool? isVerified;
  final bool? isActive;
  final DateTime? createdAt;

  const Student({
    this.id,
    this.name,
    this.email,
    this.studentId,
    this.department,
    this.varsityBatch,
    this.idCardImageUrl,
    this.isEduMail,
    this.isVerified,
    this.isActive,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);

  String get verificationStatus {
    if (isVerified == true) return 'যাচাইকৃত';
    if (isActive == false) return 'নিষ্ক্রিয়';
    return 'অপেক্ষমাণ';
  }
}
