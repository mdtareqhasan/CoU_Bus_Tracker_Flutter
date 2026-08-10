import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../shared/models/notice.dart';

class NoticeRepository {
  final ApiClient _apiClient;

  NoticeRepository(this._apiClient);

  Future<Result<List<Notice>>> getActiveNotices() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.activeNotices);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final notices = data.map((json) => Notice.fromJson(json)).toList();
        return Success(notices);
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
