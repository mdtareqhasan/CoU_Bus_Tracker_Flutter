import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import 'shell_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/buses/bus_list_screen.dart';
import '../features/buses/bus_detail_screen.dart';
import '../features/buses/live_tracking_screen.dart';
import '../features/schedules/schedule_screen.dart';
import '../features/notices/notice_screen.dart';
import '../features/auth/role_screen.dart';
import '../features/auth/academic_details_screen.dart';
import '../features/auth/google_signin_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/about/about_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// Used by the app (and the session-expiry handler) to show SnackBars from
/// anywhere, including non-widget Dio interceptor callbacks.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// App navigation graph.
///
/// Sign-in is **Google-only**: the flow is `/auth/role` (pick student or
/// teacher) → `/auth/google-signin` → `/home`, with a detour through
/// `/auth/academic-details` when the freshly-created profile is still missing
/// the write-once department/roll/session (or department/employee ID/
/// designation) that product policy requires. Phone/SMS, e-mail and ID-card
/// screens were removed — see the auth feature for the surviving trio.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
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
        final extra = state.extra as Map<String, String>?;
        final url = extra?['url'] ?? '';
        final name = extra?['name'] ?? context.l10n.busTrackingTitle;
        return LiveTrackingScreen(url: url, busName: name);
      },
    ),
    GoRoute(
      path: '/auth/role',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RoleScreen(),
    ),
    GoRoute(
      path: '/auth/google-signin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'student';
        return GoogleSigninScreen(role: role);
      },
    ),
    // Forced completion form: a signed-in user whose profile is still missing
    // the write-once academic details lands here before the app shell.
    GoRoute(
      path: '/auth/academic-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'student';
        return AcademicDetailsScreen(role: role);
      },
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
