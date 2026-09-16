import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/models/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Calls the profile endpoint to verify the stored token is still valid.
  /// Returns Success if the token is accepted (HTTP200), or Failure if the
  /// token is revoked / the user was deleted (HTTP401/403) or the backend
  /// is unreachable. The caller should treat any Failure as "session invalid".
  Future<Result<bool>> validateToken(String role) {
    final endpoint = role.toLowerCase() == 'teacher'
        ? ApiEndpoints.teacherProfile
        : ApiEndpoints.studentProfile;
    return _getProfile(endpoint);
  }

  Future<Result<bool>> _getProfile(String endpoint) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(endpoint);
      if (response.statusCode == 200) {
        return const Success(true);
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Step 1 of both phone login and registration verification: send a 6-digit
  /// OTP to the user's phone via BulkSMSBD.
  Future<Result<String>> sendPhoneOtp({
    required String phone,
    required String role,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(ApiEndpoints.sendPhoneOtp);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sendPhoneOtp,
        data: {'phone': normalized, 'role': role.toUpperCase()},
      );
      if (response.statusCode == 200) {
        return const Success('OTP পাঠানো হয়েছে');
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

  /// Verifies the OTP during registration and completes phone verification.
  /// Returns a JWT on success.
  Future<Result<AuthResponse>> verifyPhoneOtp({
    required String phone,
    required String role,
    required String otp,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(ApiEndpoints.verifyPhoneOtp);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyPhoneOtp,
        data: {'phone': normalized, 'role': role.toUpperCase(), 'otp': otp},
      );
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

  /// Resends the OTP after the 60-second cooldown.
  Future<Result<String>> resendPhoneOtp({
    required String phone,
    required String role,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(ApiEndpoints.resendPhoneOtp);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resendPhoneOtp,
        data: {'phone': normalized, 'role': role.toUpperCase()},
      );
      if (response.statusCode == 200) {
        return const Success('OTP পুনরায় পাঠানো হয়েছে');
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

  /// Phone + password login for a student (no OTP).
  Future<Result<AuthResponse>> studentLoginPhone({
    required String phone,
    required String password,
  }) {
    return _loginPhone(ApiEndpoints.studentLoginPhone, phone, password);
  }

  /// Phone + password login for a teacher (no OTP).
  Future<Result<AuthResponse>> teacherLoginPhone({
    required String phone,
    required String password,
  }) {
    return _loginPhone(ApiEndpoints.teacherLoginPhone, phone, password);
  }

  /// Step 1 of password reset: sends OTP to the phone number.
  Future<Result<String>> forgotPasswordInit({
    required String phone,
    required String role,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(ApiEndpoints.forgotPasswordInit);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPasswordInit,
        data: {'phone': normalized, 'role': role.toUpperCase()},
      );
      if (response.statusCode == 200) {
        final msg = (response.data is Map && response.data['message'] is String)
            ? response.data['message'] as String
            : 'OTP sent successfully';
        return Success(msg);
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][FORGOT-PWD] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Step 2 of password reset: verifies OTP and sets new password.
  Future<Result<String>> forgotPasswordVerify({
    required String phone,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(ApiEndpoints.forgotPasswordVerify);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPasswordVerify,
        data: {
          'phone': normalized,
          'role': role.toUpperCase(),
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode == 200) {
        final msg = (response.data is Map && response.data['message'] is String)
            ? response.data['message'] as String
            : 'Password reset successful';
        return Success(msg);
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][FORGOT-PWD-VERIFY] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> _loginPhone(
    String endpoint,
    String phone,
    String password,
  ) async {
    final normalized = normalizeBangladeshiPhone(phone);
    _logRequest(endpoint);
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {'phone': normalized, 'password': password},
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e, isLoginRequest: true));
    } catch (e) {
      debugPrint('[AUTH][LOGIN] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Step 1 of OTP-first registration: submits the full Student/Teacher
  /// payload + ID card to the backend. The backend validates everything,
  /// uploads the card, and sends the OTP. NO user row is created at this
  /// point — that only happens after the OTP is verified.
  ///
  /// Pass role=STUDENT to register a student (studentId + varsityBatch
  /// required), or role=TEACHER to register a teacher (teacherId required,
  /// designation optional).
  Future<Result<String>> initPhoneRegistration({
    required String role,
    required String name,
    required String phone,
    required String password,
    required String department,
    required File idCard,
    String? rollNumber,
    String? session,
    String? teacherId,
    String? designation,
  }) async {
    final normalized = normalizeBangladeshiPhone(phone);
    final fields = <String, dynamic>{
      'role': role.toUpperCase(),
      'name': name,
      'password': password,
      'phone': normalized,
      'department': department,
      'idCard': await _createFilePart(idCard),
    };
    if (role.toUpperCase() == 'STUDENT') {
      if (rollNumber == null || rollNumber.isEmpty) {
        return Failure(message: 'Roll number is required');
      }
      if (session == null || session.isEmpty) {
        return Failure(message: 'Session is required');
      }
      fields['rollNumber'] = rollNumber;
      fields['session'] = session;
    } else {
      if (teacherId == null || teacherId.isEmpty) {
        return Failure(message: 'Teacher ID is required');
      }
      fields['teacherId'] = teacherId;
      fields['designation'] = designation ?? '';
    }
    final formData = FormData.fromMap(fields);

    _logRequest(ApiEndpoints.initPhoneRegistration);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.initPhoneRegistration,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      _logResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final msg = (response.data is Map && response.data['message'] is String)
            ? response.data['message'] as String
            : 'OTP sent successfully';
        return Success(msg);
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][INIT] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Debug-only logging. Never logs passwords, access tokens, Google tokens,
  /// Cloudinary data, or image bytes.
  void _logRequest(String endpoint) {
    if (!kDebugMode) return;
    debugPrint(
      '[AUTH][REQ] ${_apiClient.dio.options.baseUrl}$endpoint method=${'POST'}',
    );
  }

  void _logResponse(Response response) {
    if (!kDebugMode) return;
    final data = response.data;
    final isVerified = data is Map ? data['isVerified'] : null;
    debugPrint(
      '[AUTH][RES] status=${response.statusCode} isVerified=$isVerified '
      'body=${_sanitizeBody(data)}',
    );
  }

  void _logDioError(DioException e) {
    if (!kDebugMode) return;
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    debugPrint(
      '[AUTH][DIO] type=${e.type} status=${e.response?.statusCode} '
      'backendMessage=$message '
      'uri=${e.requestOptions.uri}',
    );
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
  String _handleDioError(DioException e, {bool isLoginRequest = false}) {
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
          if (isLoginRequest) {
            // An invalid phone / wrong password during login is NOT a session
            // expiry.
            return ErrorHandler.invalidLogin;
          }
          return ErrorHandler.sessionExpired;
        }
        return ErrorHandler.getMessage(statusCode, null);
      default:
        return ErrorHandler.defaultError;
    }
  }
}
