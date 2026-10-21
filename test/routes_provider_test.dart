import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/core/api_client.dart';
import 'package:cou_bus_tracker/core/constants.dart';
import 'package:cou_bus_tracker/core/result.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/routes/route_repository.dart';
import 'package:cou_bus_tracker/features/routes/routes_provider.dart';
import 'package:cou_bus_tracker/shared/models/bus_route.dart';
import 'package:cou_bus_tracker/shared/models/route_preference.dart';

/// Canned routes/preferences plus recording of every write, following the
/// house style of fakes that subclass the repository (no mocking framework).
class _FakeRouteRepository extends RouteRepository {
  _FakeRouteRepository(StorageService storage) : super(ApiClient(storage));

  List<BusRoute> routes = const [];
  List<RoutePreference> preferences = const [];
  RoutePreference? writeResult;
  String? failRoutesWith;
  String? failPreferencesWith;
  String? failWriteWith;

  int routeRequests = 0;
  int preferenceRequests = 0;
  final List<Map<String, dynamic>> writes = [];

  @override
  Future<Result<List<BusRoute>>> getRoutes() async {
    routeRequests += 1;
    final failure = failRoutesWith;
    if (failure != null) return Failure(message: failure);
    return Success(routes);
  }

  @override
  Future<Result<List<RoutePreference>>> getMyPreferences() async {
    preferenceRequests += 1;
    final failure = failPreferencesWith;
    if (failure != null) return Failure(message: failure);
    return Success(preferences);
  }

  @override
  Future<Result<RoutePreference>> setPreference(
    int routeId, {
    bool? isPinned,
    bool? scheduleAlertsEnabled,
  }) async {
    writes.add({
      'routeId': routeId,
      'isPinned': isPinned,
      'scheduleAlertsEnabled': scheduleAlertsEnabled,
    });
    final failure = failWriteWith;
    if (failure != null) return Failure(message: failure);
    return Success(writeResult!);
  }
}

BusRoute _route(int id, {int? opposite}) =>
    BusRoute(id: id, nameBn: 'রুট $id', nameEn: 'Route $id', oppositeRouteId: opposite);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late _FakeRouteRepository repo;
  late RouteListNotifier notifier;

  setUp(() async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({StorageKeys.userId: 10});
    storage = await StorageService.getInstance();
    repo = _FakeRouteRepository(storage);
    notifier = RouteListNotifier(repo, storage);
  });

  group('setPinned / setAlerts writes', () {
    test('a pin write sends ONLY the pin field (partial-body contract)', () async {
      repo.writeResult = const RoutePreference(routeId: 4, isPinned: true);

      final result = await notifier.setPinned(4, true);

      expect(result, isA<Success<RoutePreference>>());
      final write = repo.writes.single;
      expect(write['routeId'], 4);
      expect(write['isPinned'], true);
      expect(
        write['scheduleAlertsEnabled'],
        isNull,
        reason: 'the provider passes the untouched flag as null — '
            'RouteRepository builds the PUT body only from non-null fields, '
            'so the server keeps its current value',
      );
      // The response is authoritative: state now carries the pin.
      expect(notifier.state.preferences[4]!.isPinned, isTrue);
    });

    test('server answering both flags off removes the row from state', () async {
      // Existing pin + alerts; unpinning one at a time keeps the row alive —
      // until a write comes back with both flags off.
      repo.writeResult = const RoutePreference(routeId: 4, isPinned: true);
      await notifier.setPinned(4, true);
      repo.writeResult = const RoutePreference(
        routeId: 4,
        isPinned: true,
        scheduleAlertsEnabled: true,
      );
      await notifier.setAlerts(4, true);
      expect(notifier.state.preferences[4]!.scheduleAlertsEnabled, isTrue);

      // Both cleared → server deleted the row; mirror the removal.
      repo.writeResult = const RoutePreference(routeId: 4);
      await notifier.setPinned(4, false);
      await notifier.setAlerts(4, false);

      expect(
        notifier.state.preferences.containsKey(4),
        isFalse,
        reason: 'a (false, false) response means no preference at all',
      );
    });

    test('a failed write leaves the previous value untouched', () async {
      repo.writeResult = const RoutePreference(routeId: 4, isPinned: true);
      await notifier.setPinned(4, true);

      repo.failWriteWith = 'network down';
      final result = await notifier.setPinned(4, false);

      expect(result, isA<Failure<RoutePreference>>());
      expect(
        notifier.state.preferences[4]!.isPinned,
        isTrue,
        reason: 'the server is authoritative — no optimistic flip on failure',
      );
    });

    test('the rider\'s per-user cache mirrors the latest write', () async {
      repo.writeResult = const RoutePreference(routeId: 4, isPinned: true);
      await notifier.setPinned(4, true);
      await pumpEventQueue();

      final cached = storage.getCache(
        StorageKeys.cachedRoutePreferences(10),
      );
      expect(cached, isNotNull);
      final List<dynamic> list = jsonDecode(cached!);
      expect(list, hasLength(1));
      expect(list.first['routeId'], 4);
    });
  });

  group('loadPreferences', () {
    test('drops flag-less rows so they never count as a preference', () async {
      repo.preferences = const [
        RoutePreference(routeId: 1, isPinned: true),
        RoutePreference(routeId: 2), // both off — nothing stored
      ];

      await notifier.loadPreferences();

      expect(notifier.state.preferencesLoaded, isTrue);
      expect(notifier.state.preferences.keys, [1]);
    });

    test('a failed fetch marks the load attempted instead of looping', () async {
      repo.failPreferencesWith = 'offline';

      await notifier.loadPreferences();

      expect(notifier.state.preferencesLoaded, isTrue);
      expect(notifier.state.preferences, isEmpty);
      expect(repo.preferenceRequests, 1);
    });

    test('cached pins survive an offline fetch (Home must still paint them)',
        () async {
      await storage.saveCache(
        StorageKeys.cachedRoutePreferences(10),
        jsonEncode([
          const RoutePreference(routeId: 7, isPinned: true).toJson(),
        ]),
      );
      repo.failPreferencesWith = 'offline';

      await notifier.loadPreferences();

      expect(
        notifier.state.preferencesLoaded,
        isTrue,
        reason: 'otherwise Home hides cached pins exactly when they are '
            'needed most — offline',
      );
      expect(notifier.state.preferences[7]!.isPinned, isTrue);
    });

    test('a successful fetch replaces the cached picture', () async {
      // Previous session's pins, stored per user id.
      await storage.saveCache(
        StorageKeys.cachedRoutePreferences(10),
        jsonEncode([
          const RoutePreference(routeId: 7, isPinned: true).toJson(),
        ]),
      );
      repo.preferences = const [
        RoutePreference(routeId: 7, isPinned: true, scheduleAlertsEnabled: true),
      ];

      await notifier.loadPreferences();

      // Network answer wins: the bell added elsewhere shows up.
      expect(notifier.state.preferences[7]!.scheduleAlertsEnabled, isTrue);
    });
  });

  group('loadRoutes', () {
    test('falls back to the cached listing when the network fails', () async {
      await storage.saveCache(
        StorageKeys.cachedRoutes,
        jsonEncode([_route(1, opposite: 8), _route(8, opposite: 1)]),
      );
      repo.failRoutesWith = 'offline';

      await notifier.loadRoutes();

      expect(notifier.state.routes, hasLength(2));
      expect(
        notifier.state.error,
        isNull,
        reason: 'something to show — cache beats a loud error',
      );
      expect(notifier.state.groups, hasLength(1), reason: 'still pair-grouped');
    });

    test('a network failure with no cache surfaces the error', () async {
      repo.failRoutesWith = 'server down';

      await notifier.loadRoutes();

      expect(notifier.state.routes, isEmpty);
      expect(notifier.state.error, 'server down');
    });

    test('already-loaded listing skips the network unless forced', () async {
      repo.routes = [_route(1)];
      await notifier.loadRoutes();
      expect(repo.routeRequests, 1);

      await notifier.loadRoutes();
      expect(repo.routeRequests, 1);

      await notifier.loadRoutes(force: true);
      expect(repo.routeRequests, 2);
    });
  });
}
