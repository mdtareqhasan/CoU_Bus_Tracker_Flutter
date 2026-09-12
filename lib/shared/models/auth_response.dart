class AuthResponse {
  final String? accessToken;
  final String? tokenType;
  final String? role;
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final bool? isVerified;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final bool? isEduMail;

  const AuthResponse({
    this.accessToken,
    this.tokenType,
    this.role,
    this.id,
    this.name,
    this.email,
    this.phone,
    this.isVerified,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.isEduMail,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String?,
      tokenType: json['tokenType'] as String?,
      role: json['role'] as String?,
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      // Backend uses "isEmailVerified" (OTP flow) and "isVerified" (login)
      isVerified: (json['isEmailVerified'] ?? json['isVerified']) as bool?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      isPhoneVerified: json['isPhoneVerified'] as bool?,
      isEduMail: json['isEduMail'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'tokenType': tokenType,
    'role': role,
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'isVerified': isVerified,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'isEduMail': isEduMail,
  };

  String get userDisplayName => name ?? 'ব্যবহারকারী';
}
