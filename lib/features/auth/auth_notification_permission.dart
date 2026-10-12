import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';

Future<void> requestPostAuthNotificationPermission(BuildContext context) async {
  try {
    await NotificationService.requestPermissionWithRationale(context);
  } catch (error) {
    debugPrint('Notification permission request failed: $error');
  }
}

void requestPostAuthNotificationPermissionAfterNavigation(
  BuildContext context,
) {
  final navigatorContext = Navigator.of(context, rootNavigator: true).context;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!navigatorContext.mounted) return;
    await requestPostAuthNotificationPermission(navigatorContext);
  });
}
