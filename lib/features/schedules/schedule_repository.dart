import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../shared/models/schedule.dart';

class ScheduleRepository {
  final ApiClient _apiClient;

  ScheduleRepository(this._apiClient);

  Future<Result<List<Schedule>>> getSchedules() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.schedules);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final schedules = data.map((json) => Schedule.fromJson(json)).toList();
        return Success(schedules);
      }

      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<List<Schedule>>> getSchedulesByBus(int busId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.schedulesByBus(busId));

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final schedules = data.map((json) => Schedule.fromJson(json)).toList();
        return Success(schedules);
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
        return ErrorHandler.getMessage(e.response?.statusCode, null);
      default:
        return ErrorHandler.defaultError;
    }
  }
}
