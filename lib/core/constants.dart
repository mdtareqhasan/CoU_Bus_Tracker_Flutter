/// Backend API base URL — hardcoded. Config (version, maintenance, etc.)
/// is fetched from `/api/config` on this server at cold launch.
const String kBaseUrl =
    'https://cou-bus-tracker-backend-admin-frontend.onrender.com';

const String kDefaultPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.cse.coubustracker';

class ApiConstants {
  static String get baseUrl => '$kBaseUrl/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 90);
}

class ApiEndpoints {
  static const String buses = '/buses';
  static String busDetail(int id) => '/buses/$id';
  static const String schedules = '/schedules';
  static String schedulesByBus(int busId) => '/schedules/bus/$busId';
  static const String activeNotices = '/notices/active';

  // Registration has been unified into a single OTP-first endpoint.
  // The Student/Teacher row is only created on successful OTP verification.
  static const String initPhoneRegistration = '/auth/phone-verification/init';
  static const String verifyPhoneOtp = '/auth/phone-verification/verify';
  static const String resendPhoneOtp = '/auth/phone-verification/resend';
  /// Legacy send endpoint — kept for reference. Prefer /resend for in-flow
  /// resends, and /init for new registrations.
  static const String sendPhoneOtp = '/auth/phone-verification/send';

  static const String studentLoginPhone = '/auth/student/login';
  static const String teacherLoginPhone = '/auth/teacher/login';

  static const String studentProfile = '/auth/student/me';
  static const String teacherProfile = '/auth/teacher/me';
  static const String studentUploadIdCard = '/auth/student/upload-id-card';
  static const String teacherUploadIdCard = '/auth/teacher/upload-id-card';
  static const String appVersion = '/app/version';
  static const String publicConfig = '/config';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String tokenType = 'token_type';
  static const String userRole = 'user_role';
  static const String displayName = 'display_name';
  static const String userEmail = 'user_email';
  static const String userId = 'user_id';
  static const String isVerified = 'is_verified';
  static const String isEduMail = 'is_edu_mail';
  static const String themeMode = 'theme_mode';
  static const String verificationRole = 'pending_verification_role';
  static const String userPhone = 'user_phone';
  static const String pendingPhone = 'pending_verification_phone';
  static const String languageCode = 'language_code';
  static const String cachedBuses = 'cached_buses';
  static const String cachedSchedules = 'cached_schedules';
  static const String cachedNotices = 'cached_notices';
  static String cachedBusDetail(int id) => 'cached_bus_detail_$id';
  static const String cacheTimestamp = 'cache_timestamp';
  static const String skippedVersion = 'skipped_version';
  static const String registrationDraft = 'registration_draft';
}
