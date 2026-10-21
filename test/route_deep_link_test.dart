import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cou_bus_tracker/app/shell_screen.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// Replica of `lib/app/router.dart`'s structure — the five-branch shell plus
/// a SIBLING top-level `/route/:id` — with stub screens so no providers,
/// storage or network are needed.
///
/// This pins the one risky shape in the new router: the shell has a `/route`
/// branch while a top-level `/route/:id` must still resolve for the backend
/// push deep link (`/route/{routeId}`). The branch path matches only the
/// exact location; the sibling pattern must catch the parameterised one —
/// if a future go_router release changes that ordering/precedence, this test
/// fails instead of a rider's notification silently landing on the wrong tab.
GoRouter _buildRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute(
        navigatorContainerBuilder: buildShellNavigatorContainer,
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          for (final path in const [
            '/home',
            '/route',
            '/buses',
            '/schedules',
            '/notices',
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  pageBuilder: (context, state) =>
                      NoTransitionPage(child: Text('tab-$path')),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/route/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            Text('detail-${state.pathParameters['id']}'),
      ),
    ],
  );
}

void main() {
  Future<GoRouter> pump(WidgetTester tester) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the exact /route path still opens the shell tab', (tester) async {
    final router = await pump(tester);

    router.go('/route');
    await tester.pumpAndSettle();

    expect(find.text('tab-/route'), findsOneWidget);
    expect(router.state.uri.path, '/route');
  });

  testWidgets('/route/:id resolves to the detail page over the shell', (
    tester,
  ) async {
    final router = await pump(tester);

    // Backend push deep link: splash does go('/home') then push('/route/4').
    router.go('/home');
    router.push('/route/4');
    await tester.pumpAndSettle();

    expect(find.text('detail-4'), findsOneWidget);
    expect(router.state.uri.path, '/route/4');

    // Back returns to the shell, not to a dead location.
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('tab-/home'), findsOneWidget);
    expect(router.state.uri.path, '/home');
  });

  testWidgets('going straight to /route/:id (cold deep link) does not land '
      'on the tab', (tester) async {
    final router = await pump(tester);

    router.go('/route/7');
    await tester.pumpAndSettle();

    expect(find.text('detail-7'), findsOneWidget);
    expect(find.text('tab-/route'), findsNothing);
    expect(router.state.uri.path, '/route/7');
  });

  testWidgets('flipping between paired directions keeps one detail on top', (
    tester,
  ) async {
    final router = await pump(tester);

    // RouteDetailScreen switches direction with pushReplacement.
    router.go('/home');
    router.push('/route/1');
    await tester.pumpAndSettle();
    expect(find.text('detail-1'), findsOneWidget);

    router.pushReplacement('/route/8');
    await tester.pumpAndSettle();

    expect(find.text('detail-8'), findsOneWidget);
    expect(find.text('detail-1'), findsNothing);

    // Replacement means Back leaves the detail entirely — the stack must not
    // have grown to one-detail-per-flip.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('tab-/home'), findsOneWidget);
  });
}
