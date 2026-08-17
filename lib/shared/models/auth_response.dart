import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String? accessToken;
  final String? tokenType;
  final String? role;
  final int? id;
  final String? name;
  final String? email;
  final bool? isVerified;
  final bool? isEduMail;

  const AuthResponse({
    this.accessToken,
    this.tokenType,
    this.role,
    this.id,
    this.name,
    this.email,
    this.isVerified,
    this.isEduMail,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  String get userDisplayName => name ?? 'ব্যবহারকারী';
}
