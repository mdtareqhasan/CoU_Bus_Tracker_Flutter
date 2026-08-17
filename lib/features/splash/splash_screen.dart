import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Wait for splash animation (3s)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check auth state from provider
    final authState = ref.read(authProvider);
    
    // If auth is still initializing, wait a bit more
    if (authState.status == AuthStateStatus.initial) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;
    
    final finalState = ref.read(authProvider);
    if (finalState.isLoggedIn) {
      context.go('/home');
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

