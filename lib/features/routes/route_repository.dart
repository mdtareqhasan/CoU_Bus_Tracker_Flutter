import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';
import '../../shared/models/bus_route.dart';
import '../../shared/models/route_preference.dart';
import '../../shared/models/schedule.dart';

/// Route-feature API access: the public route listing, one direction's
/// trips, and the signed-in rider's pin/alert preferences.
class RouteRepository {
  RouteRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Every active route, each direction as its own row. Public — no auth
  /// needed, so a stale token must never be attached (see `_publicPaths`).
  Future<Result<List<BusRoute>>> getRoutes() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.routes);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Success(data.map((json) => BusRoute.fromJson(json)).toList());
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
      );
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (_) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Active trips on one direction — what a Route tab row and the route
  /// detail screen render.
  Future<Result<List<Schedule>>> getSchedulesByRoute(int routeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.schedulesByRoute(routeId),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Success(data.map((json) => Schedule.fromJson(json)).toList());
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
      );
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (_) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// The rider's saved pins/alerts. Only routes with at least one flag on
  /// come back, so an empty list is a normal answer, not an error.
  Future<Result<List<RoutePreference>>> getMyPreferences() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.routePreferences);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Success(
          data.map((json) => RoutePreference.fromJson(json)).toList(),
        );
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
      );
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (_) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Partial update: pass only the flags being changed; omitted (null) fields
  /// keep their server-side value. Setting both to false deletes the row, and
  /// the response still reports the final state.
  Future<Result<RoutePreference>> setPreference(
    int routeId, {
    bool? isPinned,
    bool? scheduleAlertsEnabled,
  }) async {
    try {
      final body = <String, dynamic>{
        if (isPinned != null) 'isPinned': isPinned,
        if (scheduleAlertsEnabled != null)
          'scheduleAlertsEnabled': scheduleAlertsEnabled,
      };
      final response = await _apiClient.dio.put(
        ApiEndpoints.routePreference(routeId),
        data: body,
      );
      if (response.statusCode == 200) {
        return Success(RoutePreference.fromJson(response.data));
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
      );
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (_) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Idempotent: forgets the route entirely (unpins, disables alerts). The
  /// endpoint answers 200 with an empty body, so success carries a fixed ack.
  Future<Result<String>> removePreference(int routeId) async {
    try {
      final response = await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.routePreference(routeId),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return Success('Preference removed');
      }
      return Failure(
        message: ErrorHandler.getMessage(response.statusCode, null),
      );
    } on DioException catch (e) {
      return Failure(message: _handleDioError(e));
    } catch (_) {
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  static String _handleDioError(DioException e) {
    return ErrorHandler.getMessage(e.response?.statusCode, e);
  }
}
