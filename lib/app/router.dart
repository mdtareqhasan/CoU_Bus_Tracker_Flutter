import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/buses/bus_list_screen.dart';
import '../features/buses/bus_detail_screen.dart';
import '../features/buses/live_tracking_screen.dart';
import '../features/schedules/schedule_screen.dart';
import '../features/notices/notice_screen.dart';
import '../features/auth/role_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/upload_id_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/about/about_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/buses',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BusListScreen()),
        ),
        GoRoute(
          path: '/schedules',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ScheduleScreen()),
        ),
        GoRoute(
          path: '/notices',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NoticeScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/bus/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final scheduleId = state.uri.queryParameters['scheduleId'] != null 
            ? int.parse(state.uri.queryParameters['scheduleId']!) 
            : null;
        return BusDetailScreen(busId: id, initialScheduleId: scheduleId);
      },
    ),
    GoRoute(
      path: '/bus/live/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final url = state.uri.queryParameters['url'] ?? '';
        final name = state.uri.queryParameters['name'] ?? 'বাস ট্র্যাকিং';
        return LiveTrackingScreen(url: url, busName: name);
      },
    ),
    GoRoute(
      path: '/auth/role',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RoleScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'student';
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/auth/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'student';
        return RegisterScreen(role: role);
      },
    ),
    GoRoute(
      path: '/auth/upload-id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UploadIdScreen(),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
