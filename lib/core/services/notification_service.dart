import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../l10n/l10n.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'bus_tracker_notifications';
  static const String _channelName = 'Bus Tracker Notifications';
  static const String _channelDescription = 'Bus route updates and alerts';

  /// Optional callback invoked when a notification is tapped. The payload is
  /// the `route` (or `screen`) value from the FCM data map, when present.
  /// Wire this in [main.dart] or the app widget to navigate on tap.
  static void Function(String? payload)? onNotificationTap;

  /// Optional callback invoked whenever a fresh FCM token is available (on
  /// init and on every refresh). Wire this to upload the token to the backend.
  /// Kept as a static callback so the service stays Riverpod-free.
  static Future<void> Function(String token)? onTokenAvailable;

  static Future<void> initialize() async {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed: $token');
      _notifyTokenAvailable(token);
    });

    // --- Local notifications (needed for foreground display) ---
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // The permission prompt is shown after authentication, so don't prompt
    // again while initializing local notifications.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initialized = await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    debugPrint('Local notifications initialized: $initialized');

    // Create the channel with high importance *before* the first notification
    // is shown, and keep its id in sync with the
    // `com.google.firebase.messaging.default_notification_channel_id` value in
    // AndroidManifest.xml. Without this, messages delivered while the app is
    // backgrounded or closed fall back to the FCM SDK's auto-created
    // `fcm_fallback_notification_channel` (low importance) — no heads-up, and
    // often suppressed entirely on MIUI.
    await _ensureAndroidChannel();

    // --- FCM message handling ---
    // App in foreground: Firebase won't display anything automatically, so
    // show a local notification instead.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App in background, user taps the system tray notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.messageId}');
      _handleRoute(message.data['route'] ?? message.data['screen']);
    });

    // App was terminated completely, then launched via a notification.
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'App opened from notification: '
        '${initialMessage.messageId}',
      );
      _handleRoute(
        initialMessage.data['route'] ?? initialMessage.data['screen'],
      );
    }
  }

  /// Creates (or updates) the Android channel used for every notification the
  /// app posts itself, and as the FCM default channel via the manifest
  /// meta-data. Creating it here means it exists even if the first message
  /// arrives while the app is closed.
  static Future<void> _ensureAndroidChannel() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
    debugPrint('Notification channel created: $_channelId');
  }

  static Future<void> requestPermissionWithRationale(
    BuildContext context,
  ) async {
    final currentSettings = await _messaging.getNotificationSettings();
    if (currentSettings.authorizationStatus !=
        AuthorizationStatus.notDetermined) {
      await _logToken();
      return;
    }

    if (!context.mounted) return;

    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.notifPermissionTitle),
        content: Text(context.l10n.notifPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.notifLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.notifAllow),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    await _logToken();
  }

  static Future<void> _logToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');
    if (token != null && token.isNotEmpty) {
      await _notifyTokenAvailable(token);
    }
  }

  /// Hands the token to the registered uploader, if any. Never throws — push
  /// registration must not break the calling flow (e.g. login).
  static Future<void> _notifyTokenAvailable(String token) async {
    final callback = onTokenAvailable;
    if (callback == null) return;
    try {
      await callback(token);
    } catch (e) {
      debugPrint('FCM token upload failed: $e');
    }
  }

  /// Displays a local notification for an FCM message received while the app
  /// is in the foreground. Data-only messages (no `notification` payload) are
  /// skipped so the app can handle them silently.
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('Foreground notification received');
    debugPrint('Title: ${notification.title}');
    debugPrint('Body: ${notification.body}');

    await _postNotification(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      route: message.data['route'] ?? message.data['screen'],
    );
  }

  /// Entry point for the background isolate (`onBackgroundMessage`).
  ///
  /// Runs for every message while the app is backgrounded OR closed. For
  /// **notification-type** messages the OS already posts a tray notification,
  /// so we return early to avoid showing it twice. This path exists for
  /// **data-only** pushes (which the OS never displays) — the kind the backend
  /// would send to control title/body/route. The isolate has its own copy of
  /// the statics, so local notifications must be initialized here before use.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message ID: ${message.messageId}');

    // OS handled it (background tray notification) — nothing to do.
    if (message.notification != null) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // No permission prompts here — the post-auth flow owns that. Just make
    // sure the plugin (and thus the channel) exists in this isolate.
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    await _ensureAndroidChannel();

    final title = message.data['title']?.toString();
    final body = message.data['body']?.toString();

    // Nothing displayable (e.g. a pure data ping) — swallow it silently.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _postNotification(
      id: message.hashCode,
      title: title,
      body: body,
      route:
          message.data['route']?.toString() ??
          message.data['screen']?.toString(),
    );
  }

  /// Single place that turns a title/body into a posted local notification on
  /// the shared high-importance channel.
  static Future<void> _postNotification({
    required int id,
    String? title,
    String? body,
    String? route,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title ?? 'CoU Bus Tracker',
      body: body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'New notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: route,
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    _handleRoute(response.payload);
  }

  static void _handleRoute(String? route) {
    if (route == null || route.isEmpty) return;
    onNotificationTap?.call(route);
  }
}
