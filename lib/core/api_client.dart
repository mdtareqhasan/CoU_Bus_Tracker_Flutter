import 'dart:async';
import 'package:dio/dio.dart';
import 'constants.dart';
import 'storage_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storage;

  ApiClient._(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(_storage));
    // Wakes the Render server on cold start and retries read-only (GET/HEAD)
    // requests that fail during the boot window. Mutating requests (register,
    // login, verify) are never retried automatically so we cannot create
    // duplicate accounts/uploads or double-submit.
    _dio.interceptors.add(RetryOnColdStartInterceptor());
    // NOTE: LogInterceptor body logging is intentionally disabled so that
    // OTPs, Google ID tokens, passwords, and JWTs are never written to logs.
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: false,
    ));
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

  AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      await _storage.clearSession();
    }
    handler.next(err);
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
        final isStillCold = retryErr.type == DioExceptionType.connectionError ||
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
