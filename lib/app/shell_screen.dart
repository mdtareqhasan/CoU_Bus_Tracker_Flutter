import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import 'theme.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  static const _tabs = [
    '/home',
    '/buses',
    '/schedules',
    '/notices',
    '/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    context.go(_tabs[index]);
  }

  bool _isHomeTab(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/home';
  }

  Future<bool> _onWillPop() async {
    if (_isHomeTab(context)) {
      // On home tab — show exit confirmation dialog
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            ctx.l10n.exitAppTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(ctx.l10n.exitAppMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.commonNo),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.commonYes,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return false;
    } else {
      // On other tabs — go to home
      context.go('/home');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onTap(index, context),
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: isDark ? Colors.white24 : AppTheme.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 15,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: context.l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions_bus_outlined),
              activeIcon: const Icon(Icons.directions_bus_rounded),
              label: context.l10n.navBuses,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.schedule_outlined),
              activeIcon: const Icon(Icons.schedule_rounded),
              label: context.l10n.navSchedules,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: context.l10n.navNotices,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: context.l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
