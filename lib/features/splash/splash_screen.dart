import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    var authState = ref.read(authProvider);
    if (authState.status == AuthStateStatus.initial) {
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
      context.go('/auth/role');
    }
  }

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
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.auroraHeaderGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Aurora glow blobs
              Positioned(
                top: -120,
                right: -90,
                child: _Glow(
                  size: 320,
                  color: AppTheme.cyanBright.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                bottom: -140,
                left: -90,
                child: _Glow(
                  size: 360,
                  color: AppTheme.indigoDeep.withValues(alpha: 0.55),
                ),
              ),
              // Subtle sheen
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
              ),
              Center(child: _buildHero()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Soft rotating halo
        Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              duration: 1800.ms,
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.05, 1.05),
              curve: Curves.easeInOut,
            ),
        // Logo
        Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppTheme.cyanBright.withValues(alpha: 0.45),
                    blurRadius: 50,
                    offset: const Offset(0, 0),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/buslogo.jpeg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
            .animate()
            .scale(
              duration: 700.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
            )
            .fadeIn(duration: 600.ms),
        const SizedBox(height: AppTheme.space32),
        Text(
          'CoU Bus Tracker',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Real-time for Comilla University',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ).animate().fadeIn(delay: 450.ms, duration: 600.ms),
        const SizedBox(height: AppTheme.space48),
        SizedBox(
          width: 160,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyanBright),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            minHeight: 3,
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
