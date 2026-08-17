import 'dart:io';
import 'package:dio/dio.dart';
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

  Future<Result<AuthResponse>> _login(String endpoint, LoginRequest request) async {
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
    final formData = FormData.fromMap({
      'name': name,
      'email': email,
      'password': password ?? '',
      'googleIdToken': googleIdToken ?? '',
      'studentId': studentId,
      'department': department,
      'varsityBatch': varsityBatch,
      'idCard': await _createFilePart(idCard),
    });

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
    final formData = FormData.fromMap({
      'name': name,
      'email': email,
      'password': password ?? '',
      'googleIdToken': googleIdToken ?? '',
      'teacherId': teacherId,
      'department': department,
      'designation': designation ?? '',
      'phone': phone ?? '',
      'idCard': await _createFilePart(idCard),
    });

    return _register(ApiEndpoints.teacherRegister, formData);
  }

  Future<Result<AuthResponse>> _register(String endpoint, FormData data) async {
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
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
    if (response.data is Map && response.data['message'] != null) {
      return response.data['message'];
    }
    return ErrorHandler.getMessage(response.statusCode, null);
  }

  String _handleDioError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data;
      if (data['message'] != null) return data['message'];
      if (data['error'] != null) return data['error'];
      if (data['errors'] is Map) {
        final Map errors = data['errors'];
        return errors.values.first.toString();
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorHandler.timeoutMessage;
      case DioExceptionType.connectionError:
        return ErrorHandler.networkMessage;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return ErrorHandler.sessionExpired;
        }
        return ErrorHandler.getMessage(statusCode, null);
      default:
        return ErrorHandler.defaultError;
    }
  }
}
