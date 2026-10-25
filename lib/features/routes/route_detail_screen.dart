import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/result.dart';
import '../../l10n/l10n.dart';
import '../../shared/models/bus_route.dart';
import '../../shared/models/schedule.dart';
import '../../shared/widgets/schedule_card.dart';
import '../auth/auth_provider.dart';
import '../buses/buses_provider.dart';
import '../providers.dart';
import 'routes_provider.dart';

/// One direction's detail page — the push target for `/route/:id` (the deep
/// link backend notifications carry) and for tapping a row on the Route tab.
///
/// Pair-aware: when the route has a linked opposite direction the header
/// offers a switcher, so a rider can turn around without going back to the
/// list. Trips come from `GET /schedules/route/{id}`; when that fails (or the
/// device is offline) the globally cached schedule list is filtered by
/// `routeId` instead, so a deep link still renders something honest offline.
class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final int routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  List<Schedule> _schedules = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // The route row itself comes from the shared listing (cache-first).
    await ref.read(routeListProvider.notifier).loadRoutes();
    if (!mounted) return;

    final result = await ref
        .read(routeRepositoryProvider)
        .getSchedulesByRoute(widget.routeId);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _schedules = data;
          _isLoading = false;
        });
      case Failure(:final message):
        final offline = _schedulesFromCache();
        if (offline.isNotEmpty) {
          // Offline: the globally cached schedule list carries the same rows.
          setState(() {
            _schedules = offline;
            _isLoading = false;
            _error = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = message;
          });
        }
      default:
        setState(() => _isLoading = false);
    }
  }

  List<Schedule> _schedulesFromCache() {
    try {
      final cached = ref
          .read(storageServiceProvider)
          .getCache(StorageKeys.cachedSchedules);
      if (cached == null) return const [];
      final List<dynamic> list = jsonDecode(cached);
      return list
          .map((e) => Schedule.fromJson(e))
          .where((s) => s.routeId == widget.routeId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  BusRoute? _findRoute(int id) {
    for (final route in ref.watch(routeListProvider).routes) {
      if (route.id == id) return route;
    }
    return null;
  }

  /// A route carries every category's trips — student, staff and teacher buses
  /// run it at different times — and the endpoint is public, so the rider's
  /// role has to be applied here. Same gate as the Home, Buses and Schedules
  /// tabs; without it a teacher sees student trips and vice versa.
  List<Schedule> get _visibleSchedules {
    final allowed = allowedCategoriesForRole(ref.watch(authProvider).role);
    return _schedules.where((s) {
      final category = s.category?.toUpperCase();
      return category != null && allowed.contains(category);
    }).toList();
  }

  /// Only offer the switch when the partner is actually in the listing — a
  /// retired partner must not produce a dead link.
  BusRoute? _findOpposite(BusRoute route) {
    final oppositeId = route.oppositeRouteId;
    if (oppositeId == null) return null;
    return _findRoute(oppositeId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final route = _findRoute(widget.routeId);
    if (route == null) {
      // Routes finished loading (loadRoutes is awaited) but this id isn't in
      // them: retired or unknown — refuse to guess rather than show stale rows.
      final routesLoaded = ref.watch(
        routeListProvider.select((s) => s.routes.isNotEmpty),
      );
      if (!routesLoaded) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _buildRouteMissing();
    }

    return _buildContent(route);
  }

  /// Deep link pointed at a route we cannot resolve (retired or unknown id).
  Widget _buildRouteMissing() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_rounded,
              size: 80,
              color: AppTheme.textHint.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              context.l10n.errorNotFound,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.space24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(context.l10n.navHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BusRoute route) {
    final opposite = _findOpposite(route);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(route, opposite),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BusRoute route, BusRoute? opposite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.space16,
        left: AppTheme.space8,
        right: AppTheme.space24,
        bottom: AppTheme.space16,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradientFor(context),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusExtraLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Text(
                  route.localizedName ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (route.isOneWay) _buildOneWayBadge(),
            ],
          ),
          if (opposite != null) _buildOppositeSwitch(opposite),
        ],
      ),
    );
  }

  Widget _buildOneWayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        context.l10n.routeOneWay,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Turns around to the partner direction. `pushReplacement` keeps the stack
  /// shallow while flipping back and forth.
  Widget _buildOppositeSwitch(BusRoute opposite) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.space48,
        top: AppTheme.space4,
      ),
      child: InkWell(
        onTap: () => context.pushReplacement('/route/${opposite.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: AppTheme.space8),
              Flexible(
                child: Text(
                  opposite.localizedName ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _schedules.isEmpty) {
      return _buildErrorState(_error!);
    }
    final schedules = _visibleSchedules;
    if (schedules.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space16,
          AppTheme.space24,
          AppTheme.space48,
        ),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return ScheduleCard(
            schedule: schedule,
            flat: true,
            onTap: () => context.push(
              '/bus/${schedule.busId}?scheduleId=${schedule.id}',
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: AppTheme.space16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space24),
          ElevatedButton(
            onPressed: _load,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 64,
            color: AppTheme.textHint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            context.l10n.routeNoTrips,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
