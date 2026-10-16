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
import '../../l10n/l10n.dart';
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

  /// Fetches the profile data for the given role.
  /// Returns Success with the profile map, or Failure on error.
  Future<Result<Map<String, dynamic>>> getProfile(String role) async {
    final endpoint = role.toLowerCase() == 'teacher'
        ? ApiEndpoints.teacherProfile
        : ApiEndpoints.studentProfile;
    try {
      final response = await _apiClient.dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data is Map) {
        return Success(Map<String, dynamic>.from(response.data as Map));
      }
      return Failure(
        message: _extractErrorMessage(response),
        statusCode: response.statusCode,
        error: response.data,
      );
    } on DioException catch (e) {
      return Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
        error: e.response?.data,
      );
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<bool>> _getProfile(String endpoint) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(endpoint);
      if (response.statusCode == 200) {
        return const Success(true);
      }
      return Failure(
        message: _extractErrorMessage(response),
        statusCode: response.statusCode,
        error: response.data,
      );
    } on DioException catch (e) {
      return Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
        error: e.response?.data,
      );
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Writes the write-once academic details a profile is missing (Google
  /// Sign-In creates the row with all of them NULL).
  ///
  /// * `student` → `department` / `rollNumber` / `session`
  /// * `teacher` → `department` / `employeeId` / `designation`
  ///
  /// Returns the refreshed profile (200 body) on success. On failure the
  /// `Failure` carries `statusCode` plus the raw error body in `error` so the
  /// completion screen can show field-level 400 messages (`errors`) inline.
  Future<Result<Map<String, dynamic>>> updateAcademicDetails({
    required String role,
    required String department,
    String? rollNumber,
    String? session,
    String? employeeId,
    String? designation,
  }) async {
    final isTeacher = role.trim().toLowerCase() == 'teacher';
    final endpoint = isTeacher
        ? ApiEndpoints.teacherAcademic
        : ApiEndpoints.studentAcademic;

    // Only field *names* are ever logged — never the values.
    final fields = <String, dynamic>{'department': department};
    if (isTeacher) {
      fields['employeeId'] = employeeId;
      fields['designation'] = designation;
    } else {
      fields['rollNumber'] = rollNumber;
      fields['session'] = session;
    }

    debugPrint(
      '[AUTH][ACADEMIC] role=$role endpoint=$endpoint '
      'fields=${fields.keys.join(',')}',
    );
    _logRequest(endpoint, method: 'PUT');
    try {
      final response = await _apiClient.dio.put<dynamic>(
        endpoint,
        data: fields,
        options: Options(contentType: 'application/json'),
      );
      _logResponse(response);
      if (response.statusCode == 200 && response.data is Map) {
        return Success(Map<String, dynamic>.from(response.data as Map));
      }
      return Failure(
        message: _extractErrorMessage(response),
        statusCode: response.statusCode,
        error: response.data,
      );
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
        error: e.response?.data,
      );
    } catch (e) {
      debugPrint('[AUTH][ACADEMIC] unexpected error: $e');
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
        return Success(L10n.current.otpSent);
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
        return Success(L10n.current.otpResent);
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

  /// Email + password login for a student or teacher/employee.
  Future<Result<AuthResponse>> emailLogin({
    required String role,
    required String email,
    required String password,
  }) async {
    _logRequest(ApiEndpoints.emailLogin);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.emailLogin,
        data: {
          'role': role.toUpperCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e, isLoginRequest: true));
    } catch (e) {
      debugPrint('[AUTH][EMAIL-LOGIN] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Google Sign-In. Sends the Google ID token to the backend, which verifies
  /// it and issues a JWT for the matching student/teacher account.
  Future<Result<AuthResponse>> googleLogin({
    required String idToken,
    required String role,
  }) async {
    _logRequest(ApiEndpoints.googleLogin);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken, 'role': role.toUpperCase()},
      );
      _logResponse(response);
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e, isLoginRequest: true));
    } catch (e) {
      debugPrint('[AUTH][GOOGLE] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
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
        return Success(_successMessage(response, 'OTP sent successfully'));
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
        return Success(_successMessage(response, 'Password reset successful'));
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

  /// Step 1 of email OTP-first registration. Sends the full Student/Employee
  /// payload to /auth/email-verification/init as JSON. The backend creates the
  /// user only after the email OTP is verified.
  Future<Result<String>> initEmailRegistration({
    required String role,
    required String name,
    required String email,
    required String password,
    required String department,
    String? rollNumber,
    String? session,
    String? employeeId,
    String? designation,
  }) async {
    final fields = <String, dynamic>{
      'role': role.toUpperCase(),
      'name': name,
      'email': email,
      'password': password,
      'department': department,
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
      if (employeeId == null || employeeId.isEmpty) {
        return Failure(message: 'Employee ID is required');
      }
      fields['employeeId'] = employeeId;
      fields['designation'] = designation ?? '';
    }

    _logRequest(ApiEndpoints.initEmailRegistration);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.initEmailRegistration,
        data: fields,
        options: Options(contentType: 'application/json'),
      );
      _logResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(_successMessage(response, 'OTP sent successfully'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][INIT-EMAIL] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> verifyEmailOtp({
    required String email,
    required String role,
    required String otp,
  }) async {
    _logRequest(ApiEndpoints.verifyEmailOtp);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyEmailOtp,
        data: {'email': email, 'role': role.toUpperCase(), 'otp': otp},
      );
      _logResponse(response);
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e, isLoginRequest: true));
    } catch (e) {
      debugPrint('[AUTH][VERIFY-EMAIL] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<String>> resendEmailOtp({
    required String email,
    required String role,
  }) async {
    _logRequest(ApiEndpoints.resendEmailOtp);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resendEmailOtp,
        data: {'email': email, 'role': role.toUpperCase()},
      );
      _logResponse(response);
      if (response.statusCode == 200) {
        return Success(_successMessage(response, 'OTP resent successfully'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][RESEND-EMAIL] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Step 1 of email password reset: sends OTP to the email.
  Future<Result<String>> forgotPasswordEmailInit({
    required String email,
    required String role,
  }) async {
    _logRequest(ApiEndpoints.forgotPasswordEmailInit);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPasswordEmailInit,
        data: {'email': email.trim().toLowerCase(), 'role': role.toUpperCase()},
      );
      if (response.statusCode == 200) {
        return Success(_successMessage(response, 'OTP sent successfully'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][FORGOT-EMAIL] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Step 2 of email password reset: verifies OTP and sets new password.
  Future<Result<String>> forgotPasswordEmailVerify({
    required String email,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    _logRequest(ApiEndpoints.forgotPasswordEmailVerify);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPasswordEmailVerify,
        data: {
          'email': email.trim().toLowerCase(),
          'role': role.toUpperCase(),
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode == 200) {
        return Success(_successMessage(response, 'Password reset successful'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[AUTH][FORGOT-EMAIL-VERIFY] unexpected error: $e');
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
        return Success(_successMessage(response, 'OTP sent successfully'));
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
  void _logRequest(String endpoint, {String method = 'POST'}) {
    if (!kDebugMode) return;
    debugPrint(
      '[AUTH][REQ] ${_apiClient.dio.options.baseUrl}$endpoint method=$method',
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

  /// Picks the message to show the user for a non-2xx response.
  ///
  /// The backend sends English text plus a stable machine-readable `code`, so
  /// the `code` is the primary signal (localized by [ErrorHandler.fromCode]).
  /// Field-level `errors` are preferred over a generic message when no code
  /// mapping exists, because they name exactly which input was rejected.
  /// User-facing text for a 2xx body: prefers a localized success `code`
  /// (see [ErrorHandler.successFromCode]), then the backend's English
  /// `message`, then [fallback].
  String _successMessage(Response response, String fallback) {
    final data = response.data;
    if (data is Map) {
      final code = data['code'];
      if (code is String) {
        final localized = ErrorHandler.successFromCode(code);
        if (localized != null) return localized;
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return fallback;
  }

  /// Resolves the user-facing message for a decoded error body.
  ///
  /// Order: machine-readable `code` → field-level `errors` → the backend's
  /// English `message` → HTTP status. Shared by [_extractErrorMessage] and
  /// [_handleDioError] so both paths localize identically. Returns `null`
  /// when the body carries nothing usable, letting the caller fall back to
  /// transport-level logic (timeouts, bare 401s, ...).
  String? _messageFromBody(Object? body) {
    if (body is! Map) return null;
    final code = body['code'];
    if (code is String && code.trim().isNotEmpty) {
      final localized = ErrorHandler.fromCode(code);
      if (localized != null) return localized;
    }
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      return _formatValidationErrors(errors);
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return ErrorHandler.friendly(message);
    }
    return null;
  }

  String _extractErrorMessage(Response response) {
    return _messageFromBody(response.data) ??
        ErrorHandler.getMessage(response.statusCode, null);
  }

  /// Formats Spring-style field validation errors into a readable message.
  ///
  /// The backend sends these in English; [ErrorHandler.field] localizes the
  /// known ones and passes anything unfamiliar through unchanged. Duplicates
  /// are dropped — several fields can collapse onto the same localized text.
  String _formatValidationErrors(Map<dynamic, dynamic> errors) {
    final parts = <String>[];
    for (final message in ErrorHandler.localizeFieldErrors(errors).values) {
      final text = message.trim();
      if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
    }
    return parts.isNotEmpty ? parts.join('\n') : ErrorHandler.defaultError;
  }

  /// Handles network-level failures. Prefers the backend `code`/`errors`/
  /// `message` from the response body, and maps timeouts / connection errors /
  /// 502/503/504 to the server-busy message.
  String _handleDioError(DioException e, {bool isLoginRequest = false}) {
    final response = e.response;
    final statusCode = response?.statusCode;

    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return ErrorHandler.serverBusyMessage;
    }

    final bodyMessage = _messageFromBody(response?.data);
    if (bodyMessage != null) {
      return bodyMessage;
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
