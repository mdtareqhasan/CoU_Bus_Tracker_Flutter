import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../shared/models/auth_response.dart';
import '../../shared/models/login_request.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Result<AuthResponse>> studentLogin(LoginRequest request) async {
    return _login(ApiEndpoints.studentLogin, request);
  }

  Future<Result<AuthResponse>> teacherLogin(LoginRequest request) async {
    return _login(ApiEndpoints.teacherLogin, request);
  }

  Future<Result<AuthResponse>> adminLogin(LoginRequest request) async {
    return _login(ApiEndpoints.adminLogin, request);
  }

  Future<Result<AuthResponse>> googleLogin(String idToken, String role) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken, 'role': role.toUpperCase()},
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> verifyEmailOtp({
    required String email,
    required String role,
    required String otp,
  }) async {
    _logRequest(ApiEndpoints.emailVerify);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.emailVerify,
        data: {'email': email, 'role': role.toUpperCase(), 'otp': otp},
      );
      _logOtpStatus(response.statusCode, 'verify');
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][OTP] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<String>> resendEmailOtp({
    required String email,
    required String role,
  }) async {
    _logRequest(ApiEndpoints.emailResend);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.emailResend,
        data: {'email': email, 'role': role.toUpperCase()},
      );
      _logOtpStatus(response.statusCode, 'resend');
      if (response.statusCode == 200) {
        return const Success('ওটিপি পাঠানো হয়েছে');
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][OTP] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> _login(
      String endpoint, LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> studentRegister({
    required String name,
    required String email,
    String? password,
    String? googleIdToken,
    required String studentId,
    required String department,
    required String varsityBatch,
    required File idCard,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password ?? '',
      'studentId': studentId,
      'department': department,
      'varsityBatch': varsityBatch,
      'idCard': await _createFilePart(idCard),
    };
    // googleIdToken is only sent for Google registration (never for
    // email/password registration).
    if (googleIdToken != null && googleIdToken.isNotEmpty) {
      fields['googleIdToken'] = googleIdToken;
    }
    final formData = FormData.fromMap(fields);

    return _register(ApiEndpoints.studentRegister, formData);
  }

  Future<Result<AuthResponse>> teacherRegister({
    required String name,
    required String email,
    String? password,
    String? googleIdToken,
    required String teacherId,
    required String department,
    String? designation,
    String? phone,
    required File idCard,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password ?? '',
      'teacherId': teacherId,
      'department': department,
      'designation': designation ?? '',
      'phone': phone ?? '',
      'idCard': await _createFilePart(idCard),
    };
    // googleIdToken is only sent for Google registration (never for
    // email/password registration).
    if (googleIdToken != null && googleIdToken.isNotEmpty) {
      fields['googleIdToken'] = googleIdToken;
    }
    final formData = FormData.fromMap(fields);

    return _register(ApiEndpoints.teacherRegister, formData);
  }

  Future<Result<AuthResponse>> _register(String endpoint, FormData data) async {
    _logRequest(endpoint);
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
      _logResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Debug-only logging. Never logs passwords, access tokens, Google tokens,
  /// Cloudinary data, or image bytes.
  void _logRequest(String endpoint) {
    if (!kDebugMode) return;
    debugPrint(
        '[AUTH][REQ] ${_apiClient.dio.options.baseUrl}$endpoint method=${'POST'}');
  }

  void _logResponse(Response response) {
    if (!kDebugMode) return;
    final data = response.data;
    final isEmailVerified = data is Map ? data['isEmailVerified'] : null;
    debugPrint(
        '[AUTH][RES] status=${response.statusCode} isEmailVerified=$isEmailVerified '
        'body=${_sanitizeBody(data)}');
  }

  void _logOtpStatus(int? statusCode, String action) {
    if (!kDebugMode) return;
    debugPrint('[AUTH][OTP] action=$action status=$statusCode');
  }

  void _logDioError(DioException e) {
    if (!kDebugMode) return;
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    debugPrint('[AUTH][DIO] type=${e.type} status=${e.response?.statusCode} '
        'backendMessage=$message '
        'uri=${e.requestOptions.uri}');
  }

  /// Removes any sensitive fields from a response body before it is logged.
  Object? _sanitizeBody(Object? body) {
    if (body is Map) {
      final safe = Map<dynamic, dynamic>.from(body);
      for (final key in ['accessToken', 'tokenType', 'idToken', 'password']) {
        if (safe.containsKey(key)) safe[key] = '***';
      }
      return safe;
    }
    return body;
  }

  Future<MultipartFile> _createFilePart(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    return await MultipartFile.fromFile(
      file.path,
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    );
  }

  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ErrorHandler.friendly(message);
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return _formatValidationErrors(errors);
      }
    }
    return ErrorHandler.getMessage(response.statusCode, null);
  }

  /// Formats Spring-style field validation errors into a readable message.
  String _formatValidationErrors(Map<dynamic, dynamic> errors) {
    final parts = <String>[];
    errors.forEach((field, value) {
      if (value is List && value.isNotEmpty) {
        parts.add(value.first.toString());
      } else if (value != null) {
        parts.add(value.toString());
      }
    });
    return parts.isNotEmpty ? parts.join('\n') : ErrorHandler.defaultError;
  }

  /// Handles network-level failures. Prefers the backend `message`/`errors`
  /// from the response body, and maps timeouts / connection errors /
  /// 502/503/504 to the server-busy message.
  String _handleDioError(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;

    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return ErrorHandler.serverBusyMessage;
    }

    if (response?.data is Map) {
      final data = response!.data as Map;
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ErrorHandler.friendly(message);
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return _formatValidationErrors(errors);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ErrorHandler.serverBusyMessage;
      case DioExceptionType.badResponse:
        if (statusCode == 401 || statusCode == 403) {
          return ErrorHandler.sessionExpired;
        }
        return ErrorHandler.getMessage(statusCode, null);
      default:
        return ErrorHandler.defaultError;
    }
  }
}
