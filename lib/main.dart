import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/storage_service.dart';
import 'features/providers.dart';
import 'firebase_options.dart';

import 'core/services/notification_service.dart';
import 'core/services/pending_notification_route.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Data-only pushes arrive here silently; display them so the user sees an
  // update even when the app is closed.
  await NotificationService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the FCM background handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Wire the tap callback BEFORE initialize(): a cold-start tap delivers its
  // route through getInitialMessage() inside initialize(), long before runApp
  // builds the router — so this early callback may only park the route.
  // CoUBusTrackerApp upgrades it to store-and-navigate once the app is up.
  NotificationService.onNotificationTap = PendingNotificationRoute.set;

  await NotificationService.initialize();

  try {
    final t = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 10),
    );
    debugPrint('FCM token (startup): $t');
  } catch (e) {
    debugPrint('FCM getToken failed: $e');
  }

  // Preserve your existing storage initialization.
  final storageService = await StorageService.getInstance();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const CoUBusTrackerApp(),
    ),
  );
}
