class ApiConstants {
  static const String apiBaseSuffix = '/api';

  static String get baseUrl {
    const define = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://localhost:8081/api');
    return define;
  }

  static String get originUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

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
  static const String studentProfile = '/auth/student/me';
  static const String studentUploadIdCard = '/auth/student/upload-id-card';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String userRole = 'user_role';
  static const String displayName = 'display_name';
  static const String userEmail = 'user_email';
  static const String userId = 'user_id';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String cachedBuses = 'cached_buses';
  static const String cachedSchedules = 'cached_schedules';
  static const String cachedNotices = 'cached_notices';
  static String cachedBusDetail(int id) => 'cached_bus_detail_$id';
  static const String cacheTimestamp = 'cache_timestamp';
}
