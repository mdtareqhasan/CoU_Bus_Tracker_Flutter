import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space24,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surfaceDark
            : AppTheme.accentBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_filled_rounded,
            size: 18,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: AppTheme.space8),
          Flexible(
            child: Text(
              allowedCategories.contains('TEACHER')
                  ? context.l10n.scheduleTeacherBus
                  : context.l10n.scheduleStudentBus,
              overflow: TextOverflow.ellipsis,
              // Theme-aware: AppTheme.textPrimary is the same slate as the
              // dark-mode banner (surfaceDark), so it vanished in dark mode.
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ScheduleListState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.space12,
        left: AppTheme.space24,
        right: AppTheme.space24,
        bottom: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusExtraLarge),
        ),
      ),
      child: Column(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balancing back button
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(scheduleListProvider.notifier).setSearchQuery(v),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.scheduleSearchHint,
                hintStyle: const TextStyle(color: AppTheme.textHint),
                border: InputBorder.none,
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          _buildDayTypeFilter(state),
          const SizedBox(height: AppTheme.space8),
          _buildDirectionFilter(state),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildDayTypeFilter(ScheduleListState state) {
    final dayTypes = <String?, (String, Color)>{
      null: (context.l10n.scheduleFilterToday, AppTheme.primaryBlue),
      'WORKING': (context.l10n.scheduleFilterWorking, AppTheme.successGreen),
      'WEEKEND': (context.l10n.scheduleFilterWeekend, AppTheme.warningAmber),
    };

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: dayTypes.entries.map((entry) {
          final isSelected = state.dayTypeFilter == entry.key;
          final (label, color) = entry.value;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(scheduleListProvider.notifier)
                  .setDayTypeFilter(entry.key),
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.15),
              side: BorderSide(color: color, width: isSelected ? 2 : 1.5),
              showCheckmark: false,
              elevation: isSelected ? 3 : 1,
              pressElevation: 4,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDirectionFilter(ScheduleListState state) {
    final directions = {
      null: context.l10n.filterAll,
      'UP': context.l10n.scheduleDirectionToCampus,
      'DOWN': context.l10n.scheduleDirectionFromCampus,
    };

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: directions.entries.map((entry) {
          final isSelected = state.directionFilter == entry.key;

          Color chipColor;
          if (entry.key == 'UP') {
            chipColor = AppTheme.success;
          } else if (entry.key == 'DOWN') {
            chipColor = AppTheme.warning;
          } else {
            chipColor = AppTheme.primaryBlue;
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: ChoiceChip(
              label: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(scheduleListProvider.notifier)
                      .setDirectionFilter(entry.key);
                }
              },
              selectedColor: chipColor,
              backgroundColor: chipColor.withValues(alpha: 0.15),
              side: BorderSide(
                color: isSelected
                    ? chipColor
                    : chipColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
            ),
          );
        }).toList(),
      ),
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
      return _buildErrorState(state.error!);
    }

    final allFiltered = state.filteredSchedules;
    final schedules = allFiltered.where((s) {
      final category = s.category?.toUpperCase() ?? '';
      return allowedCategories.contains(category);
    }).toList();

    if (schedules.isEmpty) {
      return _buildEmptyState();
    }

    // Grouping by departure time
    final groupedSchedules = <String, List<Schedule>>{};
    for (var s in schedules) {
      final time = s.departureTime ?? 'N/A';
      groupedSchedules.putIfAbsent(time, () => []).add(s);
    }

    final sortedTimes = groupedSchedules.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).loadSchedules(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space24,
          vertical: AppTheme.space8,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bengaliTime,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    context.l10n.countBuses(schedules.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              child: AnimationLimiter(
                child: Column(
                  children: List.generate(schedules.length, (i) {
                    final s = schedules[i];
                    return AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 20.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ScheduleCard(
                              schedule: s,
                              onTap: () => context.push(
                                '/bus/${s.busId}?scheduleId=${s.id}',
                              ),
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
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space24),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
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
            onPressed: () =>
                ref.read(scheduleListProvider.notifier).loadSchedules(),
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
            Icons.schedule_rounded,
            size: 80,
            color: AppTheme.textHint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.scheduleEmpty,
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
