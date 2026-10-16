import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';

/// Registers / removes the calling user's FCM device token on the backend.
///
/// The user is always resolved server-side from the JWT (the Dio
/// [AuthInterceptor] attaches it), so the client only ever sends the token and
/// optional device metadata — never a user id.
class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// Upserts the FCM token for the current user.
  ///
  /// Pass a stable [deviceId] so a rotated token for the same device overwrites
  /// its row on the backend rather than inserting a duplicate. Returns
  /// [Success] with a message, or [Failure]. Callers should treat a failure as
  /// non-fatal — push registration is best-effort and must never block login.
  Future<Result<String>> registerFcmToken({
    required String token,
    String? platform,
    String? deviceId,
  }) async {
    _logRequest(ApiEndpoints.registerFcmToken);
    try {
      final response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.registerFcmToken,
        data: {
          'token': token,
          if (platform != null && platform.isNotEmpty) 'platform': platform,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(_extractMessage(response, 'FCM token registered'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[NOTIF][FCM] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  /// Removes the given FCM token for the current user. Only deletes tokens the
  /// caller owns, so this is safe to call on logout.
  Future<Result<String>> unregisterFcmToken(String token) async {
    _logRequest(ApiEndpoints.unregisterFcmToken);
    try {
      final response = await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.unregisterFcmToken,
        queryParameters: {'token': token},
      );

      if (response.statusCode == 200) {
        return Success(_extractMessage(response, 'FCM token removed'));
      }
      return Failure(message: _extractErrorMessage(response));
    } on DioException catch (e) {
      _logDioError(e);
      return Failure(message: _handleDioError(e));
    } catch (e) {
      debugPrint('[NOTIF][FCM] unexpected error: $e');
      return Failure(message: ErrorHandler.defaultError);
    }
  }

  String _extractMessage(Response response, String fallback) {
    final data = response.data;
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ErrorHandler.friendly(message);
      }
    }
    return ErrorHandler.getMessage(response.statusCode, null);
  }

  String _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return ErrorHandler.serverBusyMessage;
    }
    return ErrorHandler.getMessage(statusCode, e);
  }

  void _logRequest(String endpoint) {
    if (!kDebugMode) return;
    debugPrint(
      '[NOTIF][REQ] ${_apiClient.dio.options.baseUrl}$endpoint method=POST',
    );
  }

  void _logDioError(DioException e) {
    if (!kDebugMode) return;
    debugPrint(
      '[NOTIF][DIO] type=${e.type} status=${e.response?.statusCode} '
      'uri=${e.requestOptions.uri}',
    );
  }
}
