import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _warmUpServer();
    _handleNavigation();
  }

  /// Fires a lightweight request at app launch so the Render server starts
  /// booting while the user is still on the splash / registration screens.
  Future<void> _warmUpServer() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.get<dynamic>(
        ApiEndpoints.activeNotices,
        options: Options(
          extra: {'_maxRetries': 1},
          headers: {'Accept': 'application/json'},
        ),
      );
    } catch (_) {
      // Warm-up is best-effort; a failure here must never block navigation.
    }
  }

  Future<void> _handleNavigation() async {
    // Wait for splash animation (3s)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check auth state from provider
    final authState = ref.read(authProvider);

    // If auth is still initializing (token validation running in background),
    // use cached role to route — validation will handle 401/403 later.
    if (authState.status == AuthStateStatus.initial) {
      final storage = ref.read(storageServiceProvider);
      if (storage.isLoggedIn()) {
        context.go('/home');
      } else {
        context.go('/auth/role');
      }
      return;
    }

    if (authState.status == AuthStateStatus.authenticated) {
      context.go('/home');
    } else if (authState.status == AuthStateStatus.needsVerification) {
      context.go(
        '/auth/otp?email=${authState.email}&role=${authState.pendingRole ?? authState.role}',
      );
    } else {
      context.go('/auth/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlue,
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/splashpage.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
