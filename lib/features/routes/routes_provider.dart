import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../shared/models/bus_route.dart';
import '../../shared/models/route_preference.dart';
import '../providers.dart';
import 'route_repository.dart';

/// A route as the Route tab renders it: one card that may hold both
/// directions of a corridor.
///
/// Pairs render as a single card with two rows (never labeled "Both ways" —
/// each row is one physical direction). A route whose [oppositeRouteId]
/// points nowhere in the loaded listing (one-way, or a retired partner) is
/// [opposite] == null and gets the "One way" badge only when the server says
/// it is genuinely one-way ([BusRoute.isOneWay]).
@immutable
class RouteGroup {
  const RouteGroup({required this.route, this.opposite});

  final BusRoute route;
  final BusRoute? opposite;

  bool get hasPartner => opposite != null;

  /// Badge rule: only a server-declared one-way route is labeled as such —
  /// a linked route whose partner happens to be missing from the listing
  /// must not be mislabeled.
  bool get isOneWay => route.isOneWay;
}

/// Pairs up a flat listing: walks routes in order, and when a route declares
/// an [BusRoute.oppositeRouteId] that exists in the same list, both are
/// consumed into one group (so the partner never renders a second card).
///
/// The first route of a pair becomes [RouteGroup.route]; order is otherwise
/// preserved, and routes whose partner isn't in the list render alone.
List<RouteGroup> groupRoutes(List<BusRoute> routes) {
  final byId = <int, BusRoute>{for (final r in routes) r.id: r};
  final consumed = <int>{};
  final groups = <RouteGroup>[];

  for (final route in routes) {
    if (consumed.contains(route.id)) continue;
    consumed.add(route.id);

    final partnerId = route.oppositeRouteId;
    BusRoute? partner;
    if (partnerId != null && partnerId != route.id) {
      partner = byId[partnerId];
      if (partner != null) consumed.add(partner.id);
    }
    groups.add(RouteGroup(route: route, opposite: partner));
  }
  return groups;
}

class RouteListState {
  const RouteListState({
    this.routes = const [],
    this.groups = const [],
    this.preferences = const {},
    this.isLoading = false,
    this.error,
    this.preferencesLoaded = false,
  });

  /// Flat listing as served (each direction its own row).
  final List<BusRoute> routes;

  /// The same data paired for display — what cards are built from.
  final List<RouteGroup> groups;

  /// routeId → saved flags. Missing entry = no preference on the server.
  final Map<int, RoutePreference> preferences;

  final bool isLoading;
  final String? error;

  /// Whether the rider's preferences have been fetched this session (an
  /// empty map before that is "unknown", not "nothing pinned").
  final bool preferencesLoaded;

  RouteListState copyWith({
    List<BusRoute>? routes,
    List<RouteGroup>? groups,
    Map<int, RoutePreference>? preferences,
    bool? isLoading,
    String? error,
    bool? preferencesLoaded,
  }) {
    return RouteListState(
      routes: routes ?? this.routes,
      groups: groups ?? this.groups,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      preferencesLoaded: preferencesLoaded ?? this.preferencesLoaded,
    );
  }

  /// Pinned routes paired for the home screen's "My Routes" section.
  /// Built from the pinned subset only — a pair where just one side is
  /// pinned shows that one row (its partner may still be linked, so the
  /// badge follows the server flag, not the subset).
  List<RouteGroup> get pinnedGroups {
    final pinnedIds = preferences.entries
        .where((e) => e.value.isPinned)
        .map((e) => e.key)
        .toSet();
    return groupRoutes(routes.where((r) => pinnedIds.contains(r.id)).toList());
  }

  RoutePreference preferenceFor(int routeId) =>
      preferences[routeId] ?? const RoutePreference(routeId: -1);
}

class RouteListNotifier extends StateNotifier<RouteListState> {
  RouteListNotifier(this._repo, this._storage) : super(const RouteListState());

  final RouteRepository _repo;
  final StorageService _storage;

  /// Cache-first load of the public listing: cached routes render instantly,
  /// the network refresh writes back. Safe to call repeatedly — a load in
  /// flight or data already fresh skips the network.
  Future<void> loadRoutes({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.routes.isNotEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    _loadRoutesFromCache();

    final result = await _repo.getRoutes();
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        final groups = groupRoutes(data);
        state = state.copyWith(
          routes: data,
          groups: groups,
          isLoading: false,
          error: null,
        );
        //ignore: unawaited_futures
        _storage.saveCache(StorageKeys.cachedRoutes, jsonEncode(data));
      case Failure(:final message):
        // Keep whatever the cache showed; only surface an error when there
        // is nothing at all to display.
        state = state.copyWith(
          isLoading: false,
          error: state.routes.isEmpty ? message : null,
        );
      default:
        state = state.copyWith(isLoading: false);
    }
  }

  void _loadRoutesFromCache() {
    final cached = _storage.getCache(StorageKeys.cachedRoutes);
    if (cached == null || state.routes.isNotEmpty) return;
    try {
      final List<dynamic> list = jsonDecode(cached);
      final routes = list.map((e) => BusRoute.fromJson(e)).toList();
      state = state.copyWith(routes: routes, groups: groupRoutes(routes));
    } catch (e) {
      debugPrint('Route cache parse error: $e');
    }
  }

  /// Loads the rider's pins/alerts, cache-first. Never surfaces an error —
  /// a failed preferences fetch must not break the Route tab, it just means
  /// toggles render as off until a successful load.
  Future<void> loadPreferences() async {
    if (state.preferencesLoaded) return;

    final userId = _storage.getUserId();
    if (userId != null) _loadPreferencesFromCache(userId);

    final result = await _repo.getMyPreferences();
    if (!mounted) return;

    if (result is Success<List<RoutePreference>>) {
      final map = <int, RoutePreference>{
        for (final p in result.data)
          if (!p.isNone) p.routeId: p,
      };
      state = state.copyWith(preferences: map, preferencesLoaded: true);
      if (userId != null) {
        //ignore: unawaited_futures
        _storage.saveCache(
          StorageKeys.cachedRoutePreferences(userId),
          jsonEncode(result.data),
        );
      }
    } else {
      // Any completed attempt counts: cached pins painted above must be
      // shown even offline (otherwise Home hides them exactly when the rider
      // has no network). A refresh via pull-to-refresh retries.
      state = state.copyWith(preferencesLoaded: true);
    }
  }

  void _loadPreferencesFromCache(int userId) {
    final cached = _storage.getCache(
      StorageKeys.cachedRoutePreferences(userId),
    );
    if (cached == null) return;
    try {
      final List<dynamic> list = jsonDecode(cached);
      final map = <int, RoutePreference>{};
      for (final item in list) {
        final preference = RoutePreference.fromJson(item);
        if (!preference.isNone) {
          map[preference.routeId] = preference;
        }
      }
      state = state.copyWith(preferences: map);
    } catch (e) {
      debugPrint('Route preference cache parse error: $e');
    }
  }

  /// Toggles one flag for one route. The server is authoritative: state is
  /// updated only from its response, and a failure leaves the old value in
  /// place with the error left for the caller to surface.
  Future<Result<RoutePreference>> setPinned(int routeId, bool value) async {
    return _setFlag(routeId, isPinned: value);
  }

  Future<Result<RoutePreference>> setAlerts(int routeId, bool value) async {
    return _setFlag(routeId, scheduleAlertsEnabled: value);
  }

  Future<Result<RoutePreference>> _setFlag(
    int routeId, {
    bool? isPinned,
    bool? scheduleAlertsEnabled,
  }) async {
    final result = await _repo.setPreference(
      routeId,
      isPinned: isPinned,
      scheduleAlertsEnabled: scheduleAlertsEnabled,
    );
    if (!mounted) return result;

    if (result is Success<RoutePreference>) {
      final updated = result.data;
      final next = Map<int, RoutePreference>.from(state.preferences);
      if (updated.isNone) {
        // Both flags off — the server deleted the row; mirror that.
        next.remove(routeId);
      } else {
        next[routeId] = updated;
      }
      state = state.copyWith(preferences: next);
      _persistPreferences();
    }
    return result;
  }

  /// Refreshes preferences from the network, bypassing the loaded guard
  /// (used when another screen may have changed them).
  Future<void> refreshPreferences() async {
    state = state.copyWith(preferencesLoaded: false);
    await loadPreferences();
  }

  void _persistPreferences() {
    final userId = _storage.getUserId();
    if (userId == null) return;
    //ignore: unawaited_futures
    _storage.saveCache(
      StorageKeys.cachedRoutePreferences(userId),
      jsonEncode(state.preferences.values.toList()),
    );
  }

  /// Pinned route ids in display order — handy for tests and the home card.
  List<int> get pinnedRouteIds => state.pinnedGroups
      .expand((g) => [g.route.id, if (g.opposite != null) g.opposite!.id])
      .toList();
}

final routeListProvider =
    StateNotifierProvider<RouteListNotifier, RouteListState>((ref) {
      return RouteListNotifier(
        ref.watch(routeRepositoryProvider),
        ref.watch(storageServiceProvider),
      );
    });
