import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'storage_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storage;

  ApiClient._(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor(_storage));
    // Wakes the Render server on cold start and retries read-only (GET/HEAD)
    // requests that fail during the boot window. Mutating requests (register,
    // login, verify) are never retried automatically so we cannot create
    // duplicate accounts/uploads or double-submit.
    _dio.interceptors.add(RetryOnColdStartInterceptor());
    // NOTE: LogInterceptor body logging is intentionally disabled so that
    // OTPs, Google ID tokens, passwords, and JWTs are never written to logs.
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false, error: false),
    );
  }

  factory ApiClient(StorageService storage) {
    _instance ??= ApiClient._(storage);
    return _instance!;
  }

  Dio get dio => _dio;

  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class AuthInterceptor extends Interceptor {
  final StorageService _storage;

  /// Fired once when an authenticated request gets 401/403 (e.g. the user was
  /// deleted/rejected from the admin panel). The app wires this up to reset the
  /// in-memory auth state, show a session-expired message, and navigate to the
  /// login screen. Only requests that carried an auth token trigger it, so a
  /// plain wrong-password login 401 does not.
  static void Function()? onSessionExpired;

  /// Fired when an authenticated request is refused with 403
  /// `code = PROFILE_INCOMPLETE`. The user is still signed in — their profile
  /// just lacks the once-only academic details the product policy requires —
  /// so nothing is cleared here; the app routes them to
  /// `/auth/academic-details?role=...` instead. Receives the stored role
  /// (`student` / `teacher`).
  static void Function(String role)? onProfileIncomplete;

  /// Machine-readable marker the backend sends with that 403.
  static const String profileIncompleteCode = 'PROFILE_INCOMPLETE';

  static bool _handlingExpiry = false;

  /// Public endpoints that must never carry an auth header.
  static final _publicPaths = RegExp(
    r'/auth/(student|teacher)/(login|register)'
    r'|/auth/phone-verification/(send|verify|resend|init)'
    r'|/auth/email-verification/(send|verify|resend|init)'
    r'|/auth/email-login'
    r'|/auth/forgot-password'
    r'|/auth/forgot-password-email'
    r'|/config'
    r'|/app/version'
    r'|/notices/active'
    r'|/buses'
    r'|/schedules',
  );

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Never attach a token to public endpoints.
    if (_publicPaths.hasMatch(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final hadAuthHeader = err.requestOptions.headers['Authorization'] != null;

    // Incomplete profile ≠ expired session. Clearing the session here would
    // log the user out at the exact moment they need the completion form, so
    // this branch deliberately touches nothing and only navigates.
    if (statusCode == 403 && _isProfileIncomplete(err)) {
      final role = _storage.getRole() ?? 'student';
      if (kDebugMode) {
        debugPrint(
          '[AUTH][INTERCEPTOR] 403 $profileIncompleteCode → '
          '/auth/academic-details?role=$role (session kept)',
        );
      }
      onProfileIncomplete?.call(role);
      handler.next(err);
      return;
    }

    if ((statusCode == 401 || statusCode == 403) && hadAuthHeader) {
      await _handleSessionExpiry();
    }
    handler.next(err);
  }

  /// `true` when the 403 body carries the backend's `PROFILE_INCOMPLETE`
  /// marker (anything else on 403 is treated as a dead session).
  static bool _isProfileIncomplete(DioException err) {
    final data = err.response?.data;
    return data is Map && data['code'] == profileIncompleteCode;
  }

  Future<void> _handleSessionExpiry() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      // Remove every piece of local data: auth session (secure storage),
      // user profile prefs, and cached bus/schedule/notice data.
      await _storage.clearSession();
      await _storage.clearAllCache();
      onSessionExpired?.call();
    } finally {
      _handlingExpiry = false;
    }
  }
}

/// Retries read-only requests that fail because the Render server is still
/// starting up. Only GET/HEAD requests are retried — mutating requests are
/// never retried automatically so a registration/login cannot be double-submitted.
class RetryOnColdStartInterceptor extends Interceptor {
  static const int _maxRetries = 2;
  static const Duration _delayBetweenRetries = Duration(seconds: 3);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();
    final isReadOnly = method == 'GET' || method == 'HEAD';

    final isConnectionPhaseError =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;

    if (!isReadOnly ||
        !isConnectionPhaseError ||
        err.requestOptions.extra['_retryCount'] != null) {
      handler.next(err);
      return;
    }

    var retryCount = 0;
    final maxRetries = err.requestOptions.extra['_maxRetries'] ?? _maxRetries;

    while (retryCount < maxRetries) {
      retryCount++;
      await Future.delayed(_delayBetweenRetries * retryCount);
      try {
        final options = err.requestOptions;
        options.extra['_retryCount'] = retryCount;
        options.extra['_maxRetries'] = maxRetries;

        final response = await Dio().fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } on DioException catch (retryErr) {
        final isStillCold =
            retryErr.type == DioExceptionType.connectionError ||
            retryErr.type == DioExceptionType.connectionTimeout;
        if (!isStillCold || retryCount >= maxRetries) {
          handler.next(retryErr);
          return;
        }
      }
    }

    handler.next(err);
  }
}
