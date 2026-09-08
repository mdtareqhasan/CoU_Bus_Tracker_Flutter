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

    final authState = ref.read(authProvider);

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
          child: Image.asset('assets/images/splashpage.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
