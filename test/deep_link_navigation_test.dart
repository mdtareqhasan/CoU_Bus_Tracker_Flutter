import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pins the navigation pattern the notification deep link relies on:
/// `go('/home')` immediately followed by `push('/bus/:id?...')` in the same
/// synchronous block — used by splash (cold-start replay) and by the
/// post-login hooks (`consumePendingRouteForLogin`).
///
/// If go_router ever applies the `go` after the `push` (or drops it), the
/// pushed page would stack on top of a dead `/splash` instead of `/home`,
/// and Back from the bus page would strand the user on splash.
void main() {
  testWidgets('go then push stacks the deep link on /home, not /splash', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const Text('splash'),
        ),
        GoRoute(path: '/home', builder: (context, state) => const Text('home')),
        GoRoute(
          path: '/bus/:id',
          builder: (context, state) =>
              Text('bus ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('splash'), findsOneWidget);

    // Same synchronous block, exactly as splash_screen.dart and
    // consumePendingRouteForLogin() issue it.
    router.go('/home');
    router.push('/bus/1?scheduleId=9');
    await tester.pumpAndSettle();

    expect(find.text('bus 1'), findsOneWidget);
    expect(router.state.uri.path, '/bus/1');
    expect(router.state.uri.queryParameters['scheduleId'], '9');

    // Back from the pushed page must land on /home; a stack based on the
    // stale /splash would strand the user there instead.
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(router.state.uri.path, '/home');

    router.dispose();
  });
}
