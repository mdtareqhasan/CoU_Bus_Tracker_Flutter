import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/route_card.dart';
import 'route_preference_sheet.dart';
import 'routes_provider.dart';

/// The Route tab: every corridor the app knows, rendered pair-aware.
///
/// Linked directions share one card with two rows; one-way routes carry a
/// badge. The pin icon in the header opens the preference sheet where the
/// rider pins routes to Home and opts in to schedule-change pushes.
class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final notifier = ref.read(routeListProvider.notifier);
    await notifier.loadRoutes();
    // Preferences only matter for the sheet/badges, but they're cheap and
    // let a returning rider see their pins without opening anything.
    await notifier.loadPreferences();
  }

  Future<void> _refresh() async {
    final notifier = ref.read(routeListProvider.notifier);
    await notifier.loadRoutes(force: true);
    await notifier.refreshPreferences();
  }

  void _openRoute(int routeId) => context.push('/route/$routeId');

  void _openPreferences() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RoutePreferenceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeListProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.space24,
        left: AppTheme.space24,
        right: AppTheme.space16,
        bottom: AppTheme.space24,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradientFor(context),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusExtraLarge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.navRoute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _openPreferences,
            tooltip: context.l10n.routeMyRoutes,
            icon: const Icon(Icons.push_pin_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RouteListState state) {
    if (state.isLoading && state.routes.isEmpty) {
      return _buildLoadingSkeleton();
    }
    if (state.error != null && state.routes.isEmpty) {
      return _buildErrorState(state.error!);
    }
    if (state.groups.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space24,
          vertical: AppTheme.space16,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: state.groups.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space12),
          child: RouteCard(group: state.groups[index], onTap: _openRoute),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space24),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refresh,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_rounded,
            size: 80,
            color: AppTheme.textHint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.routeEmpty,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
