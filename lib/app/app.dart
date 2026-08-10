import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import 'theme.dart';

class CoUBusTrackerApp extends StatelessWidget {
  const CoUBusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CoU Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
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
