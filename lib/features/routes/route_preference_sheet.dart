import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/result.dart';
import '../../l10n/l10n.dart';
import '../../shared/models/bus_route.dart';
import '../../shared/models/route_preference.dart';
import '../auth/auth_notification_permission.dart';
import 'routes_provider.dart';

/// Per-route pins and schedule-alert bells for the signed-in rider.
///
/// Two independent toggles per row: the pin puts the route on the Home
/// screen's "My Routes"; the bell opts the rider into push notifications
/// when that route's schedules change (server-side audience — turning it on
/// is what makes `schedule_alerts_enabled` true). The notification permission
/// prompt fires only the first time a bell is enabled; afterwards the OS
/// already knows the answer.
class RoutePreferenceSheet extends ConsumerStatefulWidget {
  const RoutePreferenceSheet({super.key});

  @override
  ConsumerState<RoutePreferenceSheet> createState() =>
      _RoutePreferenceSheetState();
}

class _RoutePreferenceSheetState extends ConsumerState<RoutePreferenceSheet> {
  /// Route ids with a write in flight — rows disable their toggles so a slow
  /// network can't queue conflicting updates.
  final Set<int> _busy = <int>{};

  bool _permissionPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The sheet is reachable before any load has kicked off — make sure it
      // never sits on a blank list waiting for someone else's fetch.
      final notifier = ref.read(routeListProvider.notifier);
      notifier.loadRoutes();
      notifier.loadPreferences();
    });
  }

  Future<void> _togglePin(int routeId) async {
    final current = ref.read(routeListProvider).preferenceFor(routeId).isPinned;
    await _write(routeId, () {
      return ref.read(routeListProvider.notifier).setPinned(routeId, !current);
    });
  }

  Future<void> _toggleAlerts(int routeId) async {
    final enabling = !ref
        .read(routeListProvider)
        .preferenceFor(routeId)
        .scheduleAlertsEnabled;
    final ok = await _write(routeId, () {
      return ref.read(routeListProvider.notifier).setAlerts(routeId, enabling);
    });
    // Prompt only when a bell was just switched on, and only the first time —
    // requestPermissionWithRationale itself no-ops once the OS has an answer.
    if (ok && enabling && mounted && !_permissionPrompted) {
      _permissionPrompted = true;
      await requestPostAuthNotificationPermission(context);
    }
  }

  /// Runs one write, guarding the row against re-entry and surfacing failures
  /// as a snackbar (the server's answer is authoritative — on failure the
  /// toggle simply stays where it was).
  Future<bool> _write(int routeId, Future<dynamic> Function() run) async {
    if (_busy.contains(routeId)) return false;
    setState(() => _busy.add(routeId));
    final result = await run();
    if (!mounted) return false;
    setState(() => _busy.remove(routeId));

    if (result is Failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeListProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space24,
                AppTheme.space24,
                AppTheme.space24,
                AppTheme.space8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.routeMyRoutes,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    context.l10n.routeMyRoutesHint,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Flexible(
              child: state.groups.isEmpty && state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppTheme.space24),
                      child: CircularProgressIndicator(),
                    )
                  : state.groups.isEmpty
                  // No routes configured at all — say so instead of
                  // handing back a silently blank sheet.
                  ? Padding(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      child: Text(
                        context.l10n.routeEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space24,
                      ),
                      itemCount: state.groups.length,
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        return Column(
                          children: [
                            _PreferenceRow(
                              route: group.route,
                              preference: state.preferenceFor(group.route.id),
                              busy: _busy.contains(group.route.id),
                              onPin: () => _togglePin(group.route.id),
                              onAlerts: () => _toggleAlerts(group.route.id),
                            ),
                            if (group.opposite != null)
                              _PreferenceRow(
                                route: group.opposite!,
                                preference: state.preferenceFor(
                                  group.opposite!.id,
                                ),
                                busy: _busy.contains(group.opposite!.id),
                                onPin: () => _togglePin(group.opposite!.id),
                                onAlerts: () =>
                                    _toggleAlerts(group.opposite!.id),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppTheme.space16),
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.route,
    required this.preference,
    required this.busy,
    required this.onPin,
    required this.onAlerts,
  });

  final BusRoute route;
  final RoutePreference preference;
  final bool busy;
  final VoidCallback onPin;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final name = route.localizedName ?? '—';
    final pinned = preference.isPinned;
    final alerts = preference.scheduleAlertsEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            onPressed: busy ? null : onPin,
            tooltip: context.l10n.routePinTooltip,
            icon: Icon(
              pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: pinned ? AppTheme.primaryBlue : AppTheme.textHint,
            ),
          ),
          IconButton(
            onPressed: busy ? null : onAlerts,
            tooltip: context.l10n.routeAlertTooltip,
            icon: Icon(
              alerts
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: alerts ? AppTheme.primaryBlue : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
