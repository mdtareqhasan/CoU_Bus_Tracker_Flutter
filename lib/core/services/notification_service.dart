import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static Future<void> initialize() async {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed: $token');
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
        title: const Text('বাস আপডেট পেতে নোটিফিকেশন চালু করুন'),
        content: const Text(
          'আপনার বাসের সময়সূচি, রুট বা জরুরি কোনো পরিবর্তন হলে আমরা '
          'নোটিফিকেশনের মাধ্যমে আপনাকে জানাতে চাই। এতে গুরুত্বপূর্ণ আপডেট '
          'মিস হওয়ার সম্ভাবনা কমবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('পরে করব'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('অনুমতি দিন'),
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

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      payload: message.data['route'] ?? message.data['screen'],
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
