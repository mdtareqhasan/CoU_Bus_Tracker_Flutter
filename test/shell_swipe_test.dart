import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cou_bus_tracker/app/shell_screen.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// The five tab routes, in the same order as the app's bottom navigation bar.
const _tabPaths = ['/home', '/buses', '/schedules', '/notices', '/profile'];

/// Replica of the app's shell wiring from `lib/app/router.dart`, with stub
/// screens so no providers, storage or network are needed. It uses the real
/// [ShellScreen] and the real [buildShellNavigatorContainer].
GoRouter _buildShellRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute(
        navigatorContainerBuilder: buildShellNavigatorContainer,
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          for (var i = 0; i < _tabPaths.length; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: _tabPaths[i],
                  pageBuilder: (context, state) =>
                      NoTransitionPage(child: _TabStub(index: i)),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

void main() {
  Future<GoRouter> pumpShell(WidgetTester tester) async {
    final router = _buildShellRouter();
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

  int selectedTab(WidgetTester tester) => tester
      .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
      .currentIndex;

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(400, 0), 800);
    await tester.pumpAndSettle();
  }

  testWidgets('swiping left/right walks through the tabs and keeps the URL '
      'and the tab bar in sync', (tester) async {
    final router = await pumpShell(tester);

    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.text('tab-0:0'), findsOneWidget);
    expect(selectedTab(tester), 0);

    await swipeLeft(tester);
    expect(find.text('tab-1:0'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/buses');
    expect(selectedTab(tester), 1);

    await swipeLeft(tester);
    expect(find.text('tab-2:0'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/schedules');
    expect(selectedTab(tester), 2);

    // Swiping back goes the other way, without skipping a tab.
    await swipeRight(tester);
    expect(find.text('tab-1:0'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/buses');
    expect(selectedTab(tester), 1);

    // A swipe on the first tab must not throw (nothing is before it).
    await swipeRight(tester);
    expect(find.text('tab-0:0'), findsOneWidget);
    expect(selectedTab(tester), 0);
  });

  testWidgets('tapping a tab scrolls the pager to that tab', (tester) async {
    final router = await pumpShell(tester);

    // The bottom-nav labels are localized (bn).
    await tester.tap(find.text('প্রোফাইল'));
    await tester.pumpAndSettle();

    expect(find.text('tab-4:0'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    expect(selectedTab(tester), 4);

    // …and from there, a swipe is relative to the new tab.
    await swipeRight(tester);
    expect(find.text('tab-3:0'), findsOneWidget);
    expect(selectedTab(tester), 3);
  });

  testWidgets('an animated tab tap jumps straight to that tab, without '
      'landing on the tabs in between', (tester) async {
    final router = await pumpShell(tester);

    // Tapping the last tab animates the pager across four pages. The shell
    // must point at /profile the whole time: `onPageChanged` reports every
    // page the pager flies past, and those must not be mistaken for swipes.
    await tester.tap(find.text('প্রোফাইল'));
    // Sample a few times while the 250 ms animation is running.
    for (var step = 0; step < 5; step++) {
      await tester.pump(const Duration(milliseconds: 45));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/profile',
        reason: 'URL changed while the tap animation was in flight',
      );
      expect(selectedTab(tester), 4);
    }

    await tester.pumpAndSettle();
    expect(find.text('tab-4:0'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    expect(selectedTab(tester), 4);
  });

  testWidgets('dragging the pager while a tab animation runs leaves the '
      'shell and the pager on the same tab', (tester) async {
    final router = await pumpShell(tester);

    // Start the (250 ms) animation to the last tab…
    await tester.tap(find.text('প্রোফাইল'));
    await tester.pump(const Duration(milliseconds: 80));

    // …then interrupt it with a swipe, which takes the pager over mid-flight.
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 800);
    await tester.pumpAndSettle();

    final index = selectedTab(tester);
    expect(index, inInclusiveRange(0, 4));
    // The tab bar, the URL and the visible page must all agree.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      _tabPaths[index],
    );
    expect(find.text('tab-$index:0'), findsOneWidget);
  });

  testWidgets('navigating from elsewhere (deep link) moves the pager too', (
    tester,
  ) async {
    final router = await pumpShell(tester);

    router.go('/notices');
    await tester.pumpAndSettle();

    expect(find.text('tab-3:0'), findsOneWidget);
    expect(selectedTab(tester), 3);
  });

  testWidgets('a tab keeps its state when you swipe away and back', (
    tester,
  ) async {
    await pumpShell(tester);

    // Change state on the home tab…
    await tester.tap(find.text('tab-0:0'));
    await tester.pumpAndSettle();
    expect(find.text('tab-0:1'), findsOneWidget);

    // …go two tabs away…
    await swipeLeft(tester);
    await swipeLeft(tester);
    expect(find.text('tab-2:0'), findsOneWidget);

    // …and come back: the page was kept alive, so the state survived.
    await swipeRight(tester);
    await swipeRight(tester);
    expect(find.text('tab-0:1'), findsOneWidget);
  });
}

/// Stub tab screen: labels itself and counts taps, so a test can tell the tabs
/// apart and detect whether a tab's state survived being swiped away.
class _TabStub extends StatefulWidget {
  const _TabStub({required this.index});

  final int index;

  @override
  State<_TabStub> createState() => _TabStubState();
}

class _TabStubState extends State<_TabStub> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => _taps++),
          child: Text(
            'tab-${widget.index}:$_taps',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
