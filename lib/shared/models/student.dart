import 'package:json_annotation/json_annotation.dart';
import '../../l10n/l10n.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  final int? id;
  final String? name;
  final String? email;
  final String? rollNumber;
  final String? department;
  final String? session;
  final String? idCardImageUrl;
  final bool? isEduMail;
  final bool? isVerified;
  final bool? isActive;
  final DateTime? createdAt;

  const Student({
    this.id,
    this.name,
    this.email,
    this.rollNumber,
    this.department,
    this.session,
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
    if (isVerified == true) return L10n.current.statusVerified;
    if (isActive == false) return L10n.current.statusInactive;
    return L10n.current.statusPending;
  }
}
