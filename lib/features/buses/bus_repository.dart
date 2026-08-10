import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../shared/models/bus.dart';
import '../../shared/models/bus_detail.dart';

class BusRepository {
  final ApiClient _apiClient;

  BusRepository(this._apiClient);

  Future<Result<List<Bus>>> getBuses({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.buses,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final buses = data.map((json) => Bus.fromJson(json)).toList();
        return Success(buses);
      }

      return Failure(message: ErrorHandler.getMessage(response.statusCode, null));
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (e) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  Future<Result<BusDetail>> getBusDetail(int id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.busDetail(id));

      if (response.statusCode == 200) {
        final busDetail = BusDetail.fromJson(response.data);
        return Success(busDetail);
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
