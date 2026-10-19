import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import 'buses_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/widgets/bus_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';

class BusListScreen extends ConsumerStatefulWidget {
  const BusListScreen({super.key});

  @override
  ConsumerState<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends ConsumerState<BusListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      ref.read(busListProvider.notifier).setUserRole(authState.role);
      ref.read(busListProvider.notifier).loadBuses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(busListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          context.go('/home');
        },
        child: Scaffold(
          body: Column(
            children: [
              _buildSearchBar(state),
              _buildCategoryChips(state),
              Expanded(child: _buildBusList(state, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BusListState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.space12,
        left: AppTheme.space12,
        right: AppTheme.space24,
        bottom: AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.auroraHeaderGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radius2XL),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppTheme.bluePrimary,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => ref
                              .read(busListProvider.notifier)
                              .setSearchQuery(v),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.busSearchHint,
                            hintStyle: const TextStyle(
                              color: AppTheme.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space12,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            ref
                                .read(busListProvider.notifier)
                                .setSearchQuery('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textHint,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _buildCategoryChips(BusListState state) {
    final allCategories = <String?, String>{
      null: context.l10n.filterAll,
      'BLUE': context.l10n.busCategoryBlue,
      'RED': context.l10n.busCategoryRed,
      'TEACHER': context.l10n.busCategoryTeacher,
      'OFFICER': context.l10n.busCategoryOfficer,
      'STAFF': context.l10n.busCategoryStaff,
    };

    final allowed = allowedCategoriesForRole(state.userRole);
    final categories = <String?, String>{null: context.l10n.filterAll};
    for (final entry in allCategories.entries) {
      if (entry.key == null || allowed.contains(entry.key)) {
        categories[entry.key] = entry.value;
      }
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        physics: const BouncingScrollPhysics(),
        children: categories.entries.map((entry) {
          final isSelected = state.selectedCategory == entry.key;
          final color = AppTheme.colorForCategory(entry.key);
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: AnimatedScale(
              duration: Motion.durFast,
              curve: Motion.press,
              scale: isSelected ? 1.04 : 1.0,
              child: AppPill(
                label: entry.value,
                color: color,
                tonal: !isSelected,
                outline: false,
                selected: isSelected,
                onTap: () => ref
                    .read(busListProvider.notifier)
                    .setCategory(entry.key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusList(BusListState state, bool isDark) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space8,
          AppTheme.space24,
          AppTheme.space24,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppTheme.space12),
          child: LoadingShimmer(height: 96),
        ),
      );
    }

    if (state.error != null && state.buses.isEmpty) {
      return ErrorState(
        title: context.l10n.commonError,
        body: state.error,
        ctaLabel: context.l10n.commonRetry,
        onCtaPressed: () =>
            ref.read(busListProvider.notifier).loadBuses(),
      );
    }

    final buses = state.filteredBuses;

    if (buses.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: context.l10n.busListEmpty,
      );
    }

    return RefreshIndicator(
      color: AppTheme.bluePrimary,
      onRefresh: () => ref.read(busListProvider.notifier).loadBuses(),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space8,
            AppTheme.space24,
            AppTheme.space40,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];
            final busSchedules = state.schedules.where(
              (s) => s.busId == bus.id,
            );
            final route = busSchedules.isNotEmpty
                ? busSchedules.first.routeDisplay
                : bus.route ?? context.l10n.busRouteMissing;

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 320),
              child: SlideAnimation(
                verticalOffset: 18,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: BusCard(
                      bus: bus,
                      route: route,
                      onTap: () => context.push('/bus/${bus.id}'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
