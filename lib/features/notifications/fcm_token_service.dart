import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../providers.dart';
import 'notification_repository.dart';

/// Fetches the device's FCM token and registers it with the backend.
///
/// Push registration is entirely best-effort: every method swallows errors and
/// never throws, so a flaky network or a logged-out user can't break login or
/// app startup. Registration is a no-op when there is no stored JWT — the
/// backend route requires authentication.
class FcmTokenService {
  FcmTokenService(this._repository, this._storage);

  final NotificationRepository _repository;
  final StorageService _storage;

  /// The current platform, sent so the backend can target sends later.
  static String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name; // android / iOS / etc.
  }

  /// Fetches the token and registers it if the user is logged in.
  ///
  /// Safe to call repeatedly and from multiple places — the backend upserts on
  /// (user, device), so re-registering the same token is idempotent.
  Future<void> registerIfAuthenticated() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[NOTIF][FCM] no token available yet');
        return;
      }
      await registerToken(token);
    } catch (e) {
      // Never let push registration break the calling flow.
      debugPrint('[NOTIF][FCM] registration error: $e');
    }
  }

  /// Registers an already-known [token] if the user is logged in. Used by both
  /// the startup path and the `onTokenRefresh` callback. Best-effort: returns
  /// without throwing when logged out or on any failure.
  Future<void> registerToken(String token) async {
    try {
      if (token.isEmpty) return;

      // Skip silently when logged out; the route would 401 anyway.
      final jwt = await _storage.getAccessToken();
      if (jwt == null || jwt.isEmpty) return;

      final deviceId = await _storage.getOrCreateFcmDeviceId();
      final result = await _repository.registerFcmToken(
        token: token,
        platform: _platform,
        deviceId: deviceId,
      );

      switch (result) {
        case Success(:final data):
          debugPrint('[NOTIF][FCM] registered: $data');
        case Failure(:final message):
          // Non-fatal — the app works without push.
          debugPrint('[NOTIF][FCM] registration failed: $message');
        default:
          break;
      }
    } catch (e) {
      // Never let push registration break the calling flow.
      debugPrint('[NOTIF][FCM] registration error: $e');
    }
  }

  /// Removes the current device's token on logout. Best-effort.
  Future<void> unregisterCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final result = await _repository.unregisterFcmToken(token);
      switch (result) {
        case Success(:final data):
          debugPrint('[NOTIF][FCM] unregistered: $data');
        case Failure(:final message):
          debugPrint('[NOTIF][FCM] unregister failed: $message');
        default:
          break;
      }
    } catch (e) {
      debugPrint('[NOTIF][FCM] unregister error: $e');
    }
  }
}

/// Riverpod provider for [FcmTokenService]. It only needs the shared
/// [NotificationRepository] and [StorageService], both already provided.
final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  return FcmTokenService(
    ref.watch(notificationRepositoryProvider),
    ref.watch(storageServiceProvider),
  );
});
