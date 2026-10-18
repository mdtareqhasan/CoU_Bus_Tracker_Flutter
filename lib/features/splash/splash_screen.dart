import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/config/remote_config_service.dart';
import '../../core/config/app_version_checker.dart';
import '../auth/auth_provider.dart';
import '../providers.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  AppGateStatus? _gateStatus;
  PublicConfig? _config;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final configService = ref.read(remoteConfigServiceProvider);
    final config = await configService.initConfig();

    if (!mounted) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final status = evaluateAppStatus(
      currentAppVersion: currentVersion,
      config: config,
    );

    if (!mounted) return;

    if (status == AppGateStatus.allowed) {
      _warmUpServer();
      _handleAuthNavigation();
    } else {
      setState(() {
        _config = config;
        _gateStatus = status;
      });
    }
  }

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
    } catch (_) {}
  }

  Future<void> _handleAuthNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    var authState = ref.read(authProvider);
    if (authState.status == AuthStateStatus.initial) {
      // Session restore is still in flight. Wait for it instead of walking
      // into the app shell optimistically, otherwise a profile that is still
      // missing department/roll/session (or department/employee
      // ID/designation) would slip past the gate.
      final restored = await _waitForSessionRestore();
      if (!mounted || restored == null) return;
      authState = restored;
    }

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
    } else if (authState.status == AuthStateStatus.needsProfileDetails) {
      final role = authState.role ?? 'student';
      context.go('/auth/academic-details?role=$role');
    } else {
      // Everything else — including AuthStateStatus.needsVerification — lands
      // back on the role picker. Sign-in is Google-only now, so a pending OTP
      // session (a leftover from the removed phone/e-mail registration flows)
      // has no screen to resume into; restart the flow instead of navigating
      // to a route that no longer exists.
      context.go('/auth/role');
    }
  }

  /// Waits (bounded) for `_checkExistingSession` to leave
  /// `AuthStateStatus.initial`. Returns `null` on timeout or if this screen
  /// was disposed while waiting.
  Future<AuthState?> _waitForSessionRestore({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!mounted) return null;

    final completer = Completer<AuthState?>();
    final subscription = ref.listenManual<AuthState>(
      authProvider,
      (_, next) {
        if (next.status == AuthStateStatus.initial) return;
        if (!completer.isCompleted) completer.complete(next);
      },
      fireImmediately: true,
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      if (!mounted) return null;
      return ref.read(authProvider);
    } finally {
      subscription.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gateStatus == AppGateStatus.maintenance && _config != null) {
      return MaintenanceScreen(message: _config!.maintenanceMessage);
    }
    if (_gateStatus == AppGateStatus.forceUpdate && _config != null) {
      return ForceUpdateScreen(
        message: _config!.updateMessage,
        playStoreUrl: _config!.playStoreUrl,
        forceUpdate: true,
        onSkip: () => setState(() {
          _gateStatus = AppGateStatus.allowed;
          _handleAuthNavigation();
        }),
      );
    }
    if (_gateStatus == AppGateStatus.optionalUpdate && _config != null) {
      return ForceUpdateScreen(
        message: _config!.updateMessage,
        playStoreUrl: _config!.playStoreUrl,
        forceUpdate: false,
        onSkip: () => setState(() {
          _gateStatus = AppGateStatus.allowed;
          _handleAuthNavigation();
        }),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlue,
        body: SizedBox.expand(
          child: Image.asset('assets/images/splashpage.jpeg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
