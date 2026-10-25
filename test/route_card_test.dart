import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:cou_bus_tracker/shared/models/bus_route.dart';
import 'package:cou_bus_tracker/shared/widgets/route_card.dart';
import 'package:cou_bus_tracker/features/routes/routes_provider.dart';

/// Pins the pair-aware card contract:
///
///  * a linked corridor is ONE card holding two tappable direction rows —
///    tapping a row reports that direction's id, so each row lands on its
///    own detail page,
///  * the "একদিক/One way" badge appears only for server-declared one-way
///    routes — a linked route whose partner is missing must not claim it,
///  * trips/empty-trip copy counts only the signed-in role's categories (the
///    card watches authProvider itself, so no call site can forget the gate;
///    with no breakdown on the row it falls back to `activeScheduleCount`).
BusRoute _route(
  int id, {
  int? opposite,
  int? trips,
  String bn = 'রুট',
  String en = 'Route',
}) => BusRoute(
  id: id,
  nameBn: '$bn $id',
  nameEn: '$en $id',
  oppositeRouteId: opposite,
  activeScheduleCount: trips,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
  });

  // The card watches authProvider, so it needs a scope (and storage, which
  // authProvider builds against). Role stays unset → student categories.
  Widget wrap(Widget child) => ProviderScope(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp(
      locale: const Locale('bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('a linked corridor renders ONE card with two direction rows', (
    tester,
  ) async {
    final tapped = <int>[];
    final group = groupRoutes([
      _route(1, opposite: 8, trips: 4, bn: 'কান্দিরপাড়'),
      _route(8, opposite: 1, trips: 5, bn: 'ক্যাম্পাস'),
    ]).single;

    await tester.pumpWidget(wrap(RouteCard(group: group, onTap: tapped.add)));

    // One card surface, two rows.
    expect(find.byType(RouteCard), findsOneWidget);
    expect(find.text('কান্দিরপাড় 1'), findsOneWidget);
    expect(find.text('ক্যাম্পাস 8'), findsOneWidget);
    expect(
      find.byType(Divider),
      findsOneWidget,
      reason: 'exactly one divider between the rows',
    );
    expect(find.text('4 টি ট্রিপ'), findsOneWidget);
    expect(find.text('5 টি ট্রিপ'), findsOneWidget);

    // No one-way badge on a pair — pairs are never labeled "Both ways"
    // either, so the badge must simply be absent.
    expect(find.text('একদিক'), findsNothing);

    // Each row reports its own direction id.
    await tester.tap(find.text('কান্দিরপাড় 1'));
    expect(tapped, [1]);
    await tester.tap(find.text('ক্যাম্পাস 8'));
    expect(tapped, [1, 8]);
  });

  testWidgets('a one-way route shows the badge and a single row', (
    tester,
  ) async {
    final group = groupRoutes([_route(5, trips: 0)]).single;

    await tester.pumpWidget(wrap(RouteCard(group: group, onTap: (_) {})));

    expect(find.text('একদিক'), findsOneWidget);
    expect(
      find.byType(Divider),
      findsNothing,
      reason: 'single row, no divider',
    );
    expect(find.text('রুট 5'), findsOneWidget);
    expect(
      find.text('এখনো কোনো ট্রিপ নেই'),
      findsOneWidget,
      reason: 'zero trips says so instead of "0 trips"',
    );
  });

  testWidgets('linked route with a missing partner shows no badge', (
    tester,
  ) async {
    // oppositeRouteId set, but the partner row isn't in this listing
    // (retired meanwhile). One row, and no claim that it's one-way.
    final group = groupRoutes([_route(1, opposite: 99, trips: 2)]).single;

    await tester.pumpWidget(wrap(RouteCard(group: group, onTap: (_) {})));

    expect(find.byType(RouteCard), findsOneWidget);
    expect(find.text('একদিক'), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('missing localized name falls back to a dash, not a crash', (
    tester,
  ) async {
    const route = BusRoute(id: 42); // no names at all
    final group = RouteGroup(route: route);

    await tester.pumpWidget(wrap(RouteCard(group: group, onTap: (_) {})));

    expect(find.text('—'), findsOneWidget);
  });
}
