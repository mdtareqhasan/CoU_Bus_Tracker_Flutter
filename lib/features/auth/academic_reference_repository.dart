import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';
import '../../shared/models/academic_reference_option.dart';

/// Read-only access to the public academic reference data
/// (`/api/academic/**`) that the registration pickers are built from.
///
/// These lists used to be hardcoded in the app (`department_options.dart`,
/// `session_options.dart`); they now come from the database, so adding a
/// department or a session is an admin-panel row rather than an app release.
/// The endpoints are unauthenticated, which matters because the completion
/// screen runs before the profile exists.
class AcademicReferenceRepository {
  final ApiClient _apiClient;

  AcademicReferenceRepository(this._apiClient);

  /// All active units — departments first, then offices, which is exactly the
  /// teacher picker's order. Students filter this down to `DEPARTMENT`
  /// themselves (`AcademicOptions.unitsForRole`).
  Future<Result<List<AcademicReferenceOption>>> getUnits() =>
      _getList(ApiEndpoints.academicUnits);

  /// All active sessions — the student picker.
  Future<Result<List<AcademicReferenceOption>>> getSessions() =>
      _getList(ApiEndpoints.academicSessions);

  Future<Result<List<AcademicReferenceOption>>> _getList(
    String endpoint,
  ) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final options = response.data!
            .whereType<Map<String, dynamic>>()
            .map(AcademicReferenceOption.fromJson)
            .toList(growable: false);
        return Success(options);
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
        error: e.response?.data,
      );
    } catch (_) {
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
        return ErrorHandler.getMessage(e.response?.statusCode, null);
      default:
        return ErrorHandler.defaultError;
    }
  }
}
