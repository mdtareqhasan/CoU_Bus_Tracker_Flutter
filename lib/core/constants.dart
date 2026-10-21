import 'package:flutter/foundation.dart';

/// Backend API base URL — debug builds hit the local Docker backend,
/// release/profile builds hit the production API.
// const String kBaseUrl = kDebugMode
//     ? 'http://192.168.1.111:8081'
//     : 'https://api.kubijatra.com';
const String kBaseUrl = 'https://api.kubijatra.com';

const String kDefaultPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.cse.coubustracker';

/// OAuth *web* client ID (client_type 3 in android/app/google-services.json).
/// Required as `serverClientId` so Android returns an ID token the backend
/// can verify. Not a secret — it is already embedded in google-services.json.
const String kGoogleServerClientId =
    '601520130344-b0s8fni9k71ktjhbcvtqbi74k4itpkps.apps.googleusercontent.com';

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

  // Routes: public listing (each direction is one row; pairs point at each
  // other via oppositeRouteId) + per-direction trips.
  static const String routes = '/routes';
  static String schedulesByRoute(int routeId) => '/schedules/route/$routeId';

  // My route preferences (authenticated, rider-only): pins + schedule-alert
  // opt-in. PUT takes a partial body — omitted fields keep their value.
  static const String routePreferences = '/me/route-preferences';
  static String routePreference(int routeId) =>
      '/me/route-preferences/$routeId';

  // Registration has been unified into a single OTP-first endpoint.
  // The Student/Teacher row is only created on successful OTP verification.
  static const String initPhoneRegistration = '/auth/phone-verification/init';
  static const String verifyPhoneOtp = '/auth/phone-verification/verify';
  static const String resendPhoneOtp = '/auth/phone-verification/resend';

  /// Legacy send endpoint — kept for reference. Prefer /resend for in-flow
  /// resends, and /init for new registrations.
  static const String sendPhoneOtp = '/auth/phone-verification/send';

  static const String initEmailRegistration = '/auth/email-verification/init';
  static const String verifyEmailOtp = '/auth/email-verification/verify';
  static const String resendEmailOtp = '/auth/email-verification/resend';
  static const String sendEmailOtp = '/auth/email-verification/send';

  static const String studentLoginPhone = '/auth/student/login';
  static const String teacherLoginPhone = '/auth/teacher/login';
  static const String emailLogin = '/auth/email-login';
  static const String googleLogin = '/auth/google/login';

  static const String studentProfile = '/auth/student/me';
  static const String teacherProfile = '/auth/teacher/me';

  // Write-once academic details. Google Sign-In creates the Student/Teacher
  // row with these columns NULL, so the app sends them once afterwards.
  // Re-submitting an identical payload for an already-complete profile is a
  // safe no-op; changing a populated value is rejected with 400.
  // The payload references the option *ids* fetched from /academic/** below.
  static const String studentAcademic = '/auth/student/academic';
  static const String teacherAcademic = '/auth/teacher/academic';

  // Public academic reference data behind the registration pickers — the
  // department/office/session lists that used to be hardcoded in this app now
  // live in the database. Unauthenticated, and exempt from the backend's
  // PROFILE_INCOMPLETE gate because the completion screen needs them before
  // the profile exists.
  static const String academicDepartments = '/academic/departments';
  static const String academicOffices = '/academic/offices';
  static const String academicUnits = '/academic/units';
  static const String academicSessions = '/academic/sessions';

  static const String studentUploadIdCard = '/auth/student/upload-id-card';
  static const String teacherUploadIdCard = '/auth/teacher/upload-id-card';
  static const String forgotPasswordInit = '/auth/forgot-password/init';
  static const String forgotPasswordVerify = '/auth/forgot-password/verify';
  static const String forgotPasswordEmailInit =
      '/auth/forgot-password-email/init';
  static const String forgotPasswordEmailVerify =
      '/auth/forgot-password-email/verify';
  static const String appVersion = '/app/version';
  static const String publicConfig = '/config';

  // Notifications (FCM device-token registration). Both share the same path;
  // unregister passes the token as a `?token=` query parameter.
  static const String registerFcmToken = '/notifications/fcm-token';
  static const String unregisterFcmToken = '/notifications/fcm-token';
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
  static const String pendingEmail = 'pending_verification_email';
  static const String languageCode = 'language_code';
  static const String cachedBuses = 'cached_buses';
  static const String cachedSchedules = 'cached_schedules';
  static const String cachedNotices = 'cached_notices';
  static const String cachedRoutes = 'cached_routes';
  static String cachedBusDetail(int id) => 'cached_bus_detail_$id';

  /// Route preferences are per-rider, so the cache key carries the user id —
  /// one account's pins can never surface for another account on this device.
  static String cachedRoutePreferences(int userId) =>
      'cached_route_preferences_$userId';

  /// Prefix used by [cachedRoutePreferences]; cleared wholesale on logout so
  /// no previous rider's pins linger in prefs.
  static const String cachedRoutePreferencesPrefix =
      'cached_route_preferences_';
  static const String cacheTimestamp = 'cache_timestamp';
  static const String skippedVersion = 'skipped_version';
  static const String registrationDraft = 'registration_draft';
}
