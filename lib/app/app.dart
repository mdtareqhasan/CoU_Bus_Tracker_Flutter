import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/api_client.dart';
import '../features/auth/auth_provider.dart';

class CoUBusTrackerApp extends ConsumerStatefulWidget {
  const CoUBusTrackerApp({super.key});

  @override
  ConsumerState<CoUBusTrackerApp> createState() => _CoUBusTrackerAppState();
}

class _CoUBusTrackerAppState extends ConsumerState<CoUBusTrackerApp> {
  @override
  void initState() {
    super.initState();
    AuthInterceptor.onSessionExpired = _handleSessionExpired;
  }

  @override
  void dispose() {
    AuthInterceptor.onSessionExpired = null;
    super.dispose();
  }

  /// Runs when an authenticated request fails with 401/403 (user deleted or
  /// rejected in the admin panel). Secure storage and caches are already
  /// cleared by the interceptor; here we reset the in-memory auth state,
  /// notify the user, and send them to the login screen.
  void _handleSessionExpired() {
    ref.read(authProvider.notifier).forceLogout();

    final messenger = rootScaffoldMessengerKey.currentState;
    final context = messenger?.context;
    final isEnglish =
        context != null && Localizations.localeOf(context).languageCode == 'en';
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          isEnglish
              ? 'Your session has expired. Please log in again.'
              : 'আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার লগইন করুন।',
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    appRouter.go('/auth/role');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CoU Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: const Locale('bn', 'BD'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('bn', 'BD'),
        Locale('en', 'US'),
      ],
    );
  }
}
