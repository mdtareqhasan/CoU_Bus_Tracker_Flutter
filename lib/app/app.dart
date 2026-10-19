import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_provider.dart';
import 'theme_mode_provider.dart';
import 'router.dart';
import 'theme.dart';
import '../core/api_client.dart';
import '../core/services/notification_service.dart';
import '../core/update_service.dart';
import '../features/auth/auth_provider.dart';
import '../features/notifications/fcm_token_service.dart';
import '../features/providers.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/update_dialog.dart';

class CoUBusTrackerApp extends ConsumerStatefulWidget {
  const CoUBusTrackerApp({super.key});

  @override
  ConsumerState<CoUBusTrackerApp> createState() => _CoUBusTrackerAppState();
}

class _CoUBusTrackerAppState extends ConsumerState<CoUBusTrackerApp> {
  bool _updateCheckDone = false;

  @override
  void initState() {
    super.initState();
    AuthInterceptor.onSessionExpired = _handleSessionExpired;
    AuthInterceptor.onProfileIncomplete = _handleProfileIncomplete;

    // Upload the FCM token whenever one becomes available (fresh token or a
    // background refresh). The service no-ops when logged out.
    NotificationService.onTokenAvailable = (token) =>
        ref.read(fcmTokenServiceProvider).registerToken(token);

    // If we restored an existing session on launch, register the token now —
    // the login path won't run in that case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFcmTokenIfAuthenticated();
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    AuthInterceptor.onSessionExpired = null;
    AuthInterceptor.onProfileIncomplete = null;
    NotificationService.onTokenAvailable = null;
    super.dispose();
  }

  /// Registers this device's FCM token on app start when a session already
  /// exists. Best-effort; the service itself no-ops when logged out.
  Future<void> _registerFcmTokenIfAuthenticated() async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) return;
    await ref.read(fcmTokenServiceProvider).registerIfAuthenticated();
  }

  Future<void> _checkForUpdate() async {
    if (_updateCheckDone) return;
    _updateCheckDone = true;

    final updateService = ref.read(updateServiceProvider);
    final updateInfo = await updateService.checkForUpdate();

    if (updateInfo != null && mounted) {
      final storage = ref.read(storageServiceProvider);
      if (!context.mounted) return;
      UpdateDialog.show(
        context,
        updateInfo: updateInfo,
        onSkip: () => storage.setSkippedVersion(updateInfo.latestVersion),
      );
    }
  }

  /// Runs when an authenticated request fails with 401/403 (user deleted or
  /// rejected in the admin panel). Secure storage and caches are already
  /// cleared by the interceptor; here we reset the in-memory auth state,
  /// notify the user, and send them to the login screen.
  void _handleSessionExpired() {
    ref.read(authProvider.notifier).forceLogout();

    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(L10n.current.sessionExpiredMessage),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    appRouter.go('/auth/role');
  }

  /// Runs when an authenticated request gets 403 `PROFILE_INCOMPLETE`: the
  /// session is still valid, the profile just lacks department / roll number
  /// / session (students) or department / employee ID / designation (teachers).
  /// Nothing is cleared — send the user to the completion form.
  void _handleProfileIncomplete(String role) {
    // A burst of 403s must not keep re-navigating and wipe what they typed.
    if (appRouter.state.uri.path == '/auth/academic-details') return;
    appRouter.go('/auth/academic-details?role=$role');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CoU Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // User-selected language; switching this at runtime re-renders the app
      // in the new language without a restart (see lib/app/locale_provider.dart).
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
