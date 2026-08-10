import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../shared/models/auth_response.dart';
import '../../shared/models/student.dart';
import '../../shared/models/login_request.dart';
import '../../shared/models/student_register_request.dart';
import '../../shared/models/teacher_register_request.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Result<AuthResponse>> studentLogin(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.studentLogin,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> teacherLogin(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.teacherLogin,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> studentRegister(StudentRegisterRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.studentRegister,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<AuthResponse>> teacherRegister(TeacherRegisterRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.teacherRegister,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(AuthResponse.fromJson(response.data));
      }
      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<Student>> getStudentProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.studentProfile);
      if (response.statusCode == 200) {
        return Success(Student.fromJson(response.data));
      }
      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  String _handleDioError(DioException e) {
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
