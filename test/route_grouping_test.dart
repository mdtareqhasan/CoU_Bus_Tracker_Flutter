import 'package:flutter_test/flutter_test.dart';

import 'package:cou_bus_tracker/features/routes/routes_provider.dart';
import 'package:cou_bus_tracker/shared/models/bus_route.dart';
import 'package:cou_bus_tracker/shared/models/route_preference.dart';

/// Pins the pairing rules behind the pair-aware Route tab:
///
///  * a linked corridor renders as ONE group with two rows (never two cards,
///    and never a "Both ways" label),
///  * the "One way" badge follows the SERVER flag (`oppositeRouteId == null`),
///    not merely "no partner in this listing" — a retired partner must not
///    make a two-way corridor claim it only runs one way,
///  * a partner row is consumed exactly once no matter the listing order.
BusRoute _route(int id, {int? opposite, int? trips}) => BusRoute(
      id: id,
      nameBn: 'রুট $id',
      nameEn: 'Route $id',
      oppositeRouteId: opposite,
      activeScheduleCount: trips,
    );

void main() {
  group('groupRoutes', () {
    test('both directions of a corridor become ONE group with two rows', () {
      final groups = groupRoutes([
        _route(1, opposite: 8),
        _route(8, opposite: 1),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.route.id, 1);
      expect(groups.single.opposite!.id, 8);
      expect(groups.single.isOneWay, isFalse);
      expect(groups.single.hasPartner, isTrue);
    });

    test('partner is consumed exactly once regardless of listing order', () {
      final reversed = groupRoutes([
        _route(8, opposite: 1),
        _route(1, opposite: 8),
      ]);

      expect(reversed, hasLength(1));
      expect(reversed.single.route.id, 8);
      expect(reversed.single.opposite!.id, 1);
    });

    test('a server-declared one-way route carries the badge', () {
      final groups = groupRoutes([_route(5, trips: 0)]);

      expect(groups.single.isOneWay, isTrue);
      expect(groups.single.opposite, isNull);
    });

    test('linked route with a missing (retired) partner is NOT labeled one-way',
        () {
      final groups = groupRoutes([_route(1, opposite: 99)]);

      expect(groups.single.opposite, isNull);
      expect(
        groups.single.isOneWay,
        isFalse,
        reason: 'the corridor runs both ways — only the partner row is absent',
      );
    });

    test('a self-referential opposite never swallows the route', () {
      final groups = groupRoutes([_route(1, opposite: 1)]);

      expect(groups, hasLength(1));
      expect(groups.single.opposite, isNull);
    });

    test('independent routes and other pairs stay separate cards', () {
      final groups = groupRoutes([
        _route(1),
        _route(2, opposite: 3),
        _route(3, opposite: 2),
      ]);

      expect(groups, hasLength(2));
      expect(groups[0].route.id, 1);
      expect(groups[0].isOneWay, isTrue);
      expect(groups[1].route.id, 2);
      expect(groups[1].opposite!.id, 3);
    });

    test('an empty listing yields no groups', () {
      expect(groupRoutes(const []), isEmpty);
    });
  });

  group('RouteListState.pinnedGroups', () {
    RouteListState stateWith(
      List<BusRoute> routes,
      Map<int, RoutePreference> preferences,
    ) =>
        RouteListState(
          routes: routes,
          groups: groupRoutes(routes),
          preferences: preferences,
          preferencesLoaded: true,
        );

    test('pinning both directions renders one paired card', () {
      final state = stateWith(
        [_route(1, opposite: 8), _route(8, opposite: 1)],
        {
          1: const RoutePreference(routeId: 1, isPinned: true),
          8: const RoutePreference(routeId: 8, isPinned: true),
        },
      );

      expect(state.pinnedGroups, hasLength(1));
      expect(state.pinnedGroups.single.route.id, 1);
      expect(state.pinnedGroups.single.opposite!.id, 8);
    });

    test('pinning one direction shows that row alone, with NO one-way badge',
        () {
      final state = stateWith(
        [_route(1, opposite: 8), _route(8, opposite: 1)],
        {1: const RoutePreference(routeId: 1, isPinned: true)},
      );

      final pinned = state.pinnedGroups;
      expect(pinned, hasLength(1));
      expect(pinned.single.route.id, 1);
      expect(pinned.single.opposite, isNull);
      expect(
        pinned.single.isOneWay,
        isFalse,
        reason: 'the corridor is linked — only this side is pinned',
      );
    });

    test('no pins yields no groups, so Home hides the section entirely', () {
      final state = stateWith(
        [_route(1, opposite: 8), _route(8, opposite: 1), _route(5)],
        {
          // Alert-only preference: opted into pushes but NOT pinned must
          // never surface the route on Home.
          5: const RoutePreference(
            routeId: 5,
            scheduleAlertsEnabled: true,
          ),
        },
      );

      expect(state.pinnedGroups, isEmpty);
    });
  });

  group('BusRoute parsing and naming', () {
    test('older cached JSON without the new fields still parses', () {
      final route = BusRoute.fromJson({
        'id': 3,
        'nameBn': 'রুট ৩',
        'nameEn': 'Route 3',
      });

      expect(route.isActive, isTrue, reason: 'defaultValue keeps old caches alive');
      expect(route.oppositeRouteId, isNull);
      expect(route.activeScheduleCount, isNull);
      expect(route.isOneWay, isTrue);
    });

    test('full response parses the pairing and trip-count fields', () {
      final route = BusRoute.fromJson({
        'id': 1,
        'nameBn': 'কান্দিরপাড় → ক্যাম্পাস',
        'nameEn': 'Kandirpar → Campus',
        'isActive': true,
        'oppositeRouteId': 8,
        'activeScheduleCount': 4,
      });

      expect(route.oppositeRouteId, 8);
      expect(route.activeScheduleCount, 4);
      expect(route.isOneWay, isFalse);
    });

    test('preference with both flags off is "no preference"', () {
      const none = RoutePreference(routeId: 1);
      expect(none.isNone, isTrue);

      const pinnedOnly = RoutePreference(routeId: 1, isPinned: true);
      expect(pinnedOnly.isNone, isFalse);

      final roundTrip = RoutePreference.fromJson(pinnedOnly.toJson());
      expect(roundTrip.routeId, pinnedOnly.routeId);
      expect(roundTrip.isPinned, isTrue);
      expect(roundTrip.scheduleAlertsEnabled, isFalse);
    });
  });
}
