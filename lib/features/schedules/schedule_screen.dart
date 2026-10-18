import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import 'schedules_provider.dart';
import '../auth/auth_provider.dart';
import '../buses/buses_provider.dart';
import '../../shared/models/schedule.dart';
import '../../core/utils/time_utils.dart';
import '../../shared/widgets/schedule_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleListProvider.notifier).loadSchedules();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleListProvider);
    final role = ref.watch(authProvider).role;
    final allowedCategories = allowedCategoriesForRole(role);

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
              _buildRoleBanner(allowedCategories),
              Expanded(child: _buildScheduleList(state, allowedCategories)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBanner(Set<String> allowedCategories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space12,
        AppTheme.space24,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        elevation: GlassCardElevation.soft,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.bluePrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                size: 18,
                color: AppTheme.bluePrimary,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                allowedCategories.contains('TEACHER')
                    ? context.l10n.scheduleTeacherBus
                    : context.l10n.scheduleStudentBus,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildSearchBar(ScheduleListState state) {
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
            top: -50,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.indigoDeep.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.scheduleTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Container(
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
                            .read(scheduleListProvider.notifier)
                            .setSearchQuery(v),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.scheduleSearchHint,
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
                              .read(scheduleListProvider.notifier)
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
              const SizedBox(height: AppTheme.space12),
              SizedBox(
                height: 36,
                child: _buildDayTypeFilter(state),
              ),
              const SizedBox(height: AppTheme.space8),
              SizedBox(
                height: 36,
                child: _buildDirectionFilter(state),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _buildDayTypeFilter(ScheduleListState state) {
    final dayTypes = <String?, (String, Color)>{
      null: (context.l10n.scheduleFilterToday, AppTheme.bluePrimary),
      'WORKING': (context.l10n.scheduleFilterWorking, AppTheme.success),
      'WEEKEND': (context.l10n.scheduleFilterWeekend, AppTheme.warning),
    };

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      itemCount: dayTypes.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
      itemBuilder: (context, i) {
        final entry = dayTypes.entries.elementAt(i);
        final isSelected = state.dayTypeFilter == entry.key;
        final (label, color) = entry.value;
        return AnimatedScale(
          scale: isSelected ? 1.04 : 1.0,
          duration: Motion.durFast,
          curve: Motion.enter,
          child: AppPill(
            label: label,
            color: color,
            tonal: !isSelected,
            dense: true,
            selected: isSelected,
            onTap: () => ref
                .read(scheduleListProvider.notifier)
                .setDayTypeFilter(entry.key),
          ),
        );
      },
    );
  }

  Widget _buildDirectionFilter(ScheduleListState state) {
    final directions = {
      null: (context.l10n.filterAll, AppTheme.bluePrimary),
      'UP': (context.l10n.scheduleDirectionToCampus, AppTheme.success),
      'DOWN': (context.l10n.scheduleDirectionFromCampus, AppTheme.warning),
    };

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      itemCount: directions.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
      itemBuilder: (context, i) {
        final entry = directions.entries.elementAt(i);
        final isSelected = state.directionFilter == entry.key;
        final (label, color) = entry.value;
        return AnimatedScale(
          scale: isSelected ? 1.04 : 1.0,
          duration: Motion.durFast,
          curve: Motion.enter,
          child: AppPill(
            label: label,
            color: color,
            tonal: !isSelected,
            dense: true,
            selected: isSelected,
            onTap: () => ref
                .read(scheduleListProvider.notifier)
                .setDirectionFilter(entry.key),
          ),
        );
      },
    );
  }

  Widget _buildScheduleList(
    ScheduleListState state,
    Set<String> allowedCategories,
  ) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.schedules.isEmpty) {
      return ErrorState(
        title: context.l10n.commonError,
        body: state.error,
        ctaLabel: context.l10n.commonRetry,
        onCtaPressed: () =>
            ref.read(scheduleListProvider.notifier).loadSchedules(),
      );
    }

    final allFiltered = state.filteredSchedules;
    final schedules = allFiltered.where((s) {
      final category = s.category?.toUpperCase() ?? '';
      return allowedCategories.contains(category);
    }).toList();

    if (schedules.isEmpty) {
      return EmptyState(
        icon: Icons.schedule_rounded,
        title: context.l10n.scheduleEmpty,
      );
    }

    // Grouping by departure time
    final groupedSchedules = <String, List<Schedule>>{};
    for (var s in schedules) {
      final time = s.departureTime ?? 'N/A';
      groupedSchedules.putIfAbsent(time, () => []).add(s);
    }

    final sortedTimes = groupedSchedules.keys.toList()..sort();

    return RefreshIndicator(
      color: AppTheme.bluePrimary,
      onRefresh: () => ref.read(scheduleListProvider.notifier).loadSchedules(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space12,
          AppTheme.space24,
          AppTheme.space40,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: sortedTimes.length,
        itemBuilder: (context, index) {
          final time = sortedTimes[index];
          final timeSchedules = groupedSchedules[time]!;
          return _buildTimeGroup(time, timeSchedules, index);
        },
      ),
    );
  }

  Widget _buildTimeGroup(String time, List<Schedule> schedules, int index) {
    final bengaliTime = TimeUtils.formatTime(time);

    return GlassCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      elevation: GlassCardElevation.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header — time + count
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space12,
              AppTheme.space16,
              AppTheme.space8,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.bluePrimary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppTheme.bluePrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bengaliTime,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.countBuses(schedules.length),
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            color: AppTheme.bluePrimary.withValues(alpha: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space8,
              AppTheme.space8,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: AnimationLimiter(
              child: Column(
                children: List.generate(schedules.length, (i) {
                  final s = schedules[i];
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 320),
                    child: SlideAnimation(
                      verticalOffset: 16,
                      child: FadeInAnimation(
                        child: ScheduleCard(
                          schedule: s,
                          onTap: () => context.push(
                            '/bus/${s.busId}?scheduleId=${s.id}',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 380.ms).slideY(
          begin: 0.08,
          end: 0,
          curve: Motion.enter,
        );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space12,
        AppTheme.space24,
        AppTheme.space40,
      ),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space16),
      itemBuilder: (_, __) => const LoadingShimmer(height: 100),
    );
  }
}
