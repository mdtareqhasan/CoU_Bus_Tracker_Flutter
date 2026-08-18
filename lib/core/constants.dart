class ApiConstants {
  static const String apiBaseSuffix = '/api';

  static String get baseUrl {
    const define = String.fromEnvironment('API_BASE_URL',
        defaultValue:
            'https://cou-bus-tracker-backend-admin-frontend.onrender.com/api');
    return define;
  }

  static String get originUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 90);

  static const Duration cacheMaxAge = Duration(minutes: 5);
}

class ApiEndpoints {
  static const String buses = '/buses';
  static String busDetail(int id) => '/buses/$id';
  static const String schedules = '/schedules';
  static String schedulesByBus(int busId) => '/schedules/bus/$busId';
  static const String activeNotices = '/notices/active';

  static const String studentRegister = '/auth/student/register';
  static const String studentLogin = '/auth/student/login';
  static const String teacherRegister = '/auth/teacher/register';
  static const String teacherLogin = '/auth/teacher/login';
  static const String adminLogin = '/auth/admin/login';
  static const String googleLogin = '/auth/google/login';
  static const String studentProfile = '/auth/student/me';
  static const String teacherProfile = '/auth/teacher/me';
  static const String studentUploadIdCard = '/auth/student/upload-id-card';
  static const String teacherUploadIdCard = '/auth/teacher/upload-id-card';
  static const String emailVerify = '/auth/email-verification/verify';
  static const String emailResend = '/auth/email-verification/resend';
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
  static const String verificationEmail = 'pending_verification_email';
  static const String verificationRole = 'pending_verification_role';
  static const String languageCode = 'language_code';
  static const String cachedBuses = 'cached_buses';
  static const String cachedSchedules = 'cached_schedules';
  static const String cachedNotices = 'cached_notices';
  static String cachedBusDetail(int id) => 'cached_bus_detail_$id';
  static const String cacheTimestamp = 'cache_timestamp';
}
