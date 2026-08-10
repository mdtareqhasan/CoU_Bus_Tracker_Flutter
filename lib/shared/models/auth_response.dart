import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String? accessToken;
  final String? tokenType;
  @JsonKey(name: 'adminName')
  final String? displayName;
  final String? name;
  final String? email;
  final String? role;

  const AuthResponse({
    this.accessToken,
    this.tokenType,
    this.displayName,
    this.name,
    this.email,
    this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  String get userDisplayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return 'ব্যবহারকারী';
  }
}
