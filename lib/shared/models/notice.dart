import 'package:json_annotation/json_annotation.dart';

part 'notice.g.dart';

@JsonSerializable()
class Notice {
  final int? id;
  final String? title;
  final String? body;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const Notice({
    this.id,
    this.title,
    this.body,
    this.isActive,
    this.createdAt,
    this.expiresAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) =>
      _$NoticeFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeToJson(this);

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
}
