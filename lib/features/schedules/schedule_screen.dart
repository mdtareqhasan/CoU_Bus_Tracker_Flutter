import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import 'schedules_provider.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildSearchBar(state),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildScheduleList(state, isTeacher: false),
                    _buildScheduleList(state, isTeacher: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.surfaceDark 
            : AppTheme.accentBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          gradient: AppTheme.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'শিক্ষার্থী বাস'),
          Tab(text: 'শিক্ষক বাস'),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusExtraLarge)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              const Expanded(
                child: Text(
                  'সময়সূচি',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              onChanged: (v) => ref.read(scheduleListProvider.notifier).setSearchQuery(v),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'শিডিউল খুঁজুন (সময় বা রুট)...',
                hintStyle: TextStyle(color: AppTheme.textHint),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
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
      null: ('আজকের তালিকা', AppTheme.primaryBlue),
      'WORKING': ('কর্মদিবস', AppTheme.successGreen),
      'WEEKEND': ('শুক্র ও শনিবার', AppTheme.warningAmber),
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
              onSelected: (_) => ref.read(scheduleListProvider.notifier).setDayTypeFilter(entry.key),
              selectedColor: color,
              backgroundColor: color.withOpacity(0.15),
              side: BorderSide(
                color: color,
                width: isSelected ? 2 : 1.5,
              ),
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
      null: 'সব',
      'UP': 'ক্যাম্পাস অভিমুখে',
      'DOWN': 'ক্যাম্পাস থেকে',
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

          final isAllButton = entry.key == null;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: ChoiceChip(
              label: Text(
                entry.value, 
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected 
                      ? Colors.white
                      : chipColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(scheduleListProvider.notifier).setDirectionFilter(entry.key);
                }
              },
              selectedColor: chipColor,
              backgroundColor: chipColor.withOpacity(0.15),
              side: BorderSide(
                color: isSelected ? chipColor : chipColor.withOpacity(0.4),
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

  Widget _buildScheduleList(ScheduleListState state, {required bool isTeacher}) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.schedules.isEmpty) {
      return _buildErrorState(state.error!);
    }

    final allFiltered = state.filteredSchedules;
    final schedules = allFiltered.where((s) {
      final isTeacherBus = s.category?.toUpperCase() == 'TEACHER';
      return isTeacher ? isTeacherBus : !isTeacherBus;
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
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space8),
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
    final bengaliTime = TimeUtils.formatTimeBengali(time);
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
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryBlue, size: 20),
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
                    '${schedules.length} টি বাস',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
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
                              onTap: () => context.push('/bus/${s.busId}?scheduleId=${s.id}')
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
            onPressed: () => ref.read(scheduleListProvider.notifier).loadSchedules(),
            child: const Text('আবার চেষ্টা করুন'),
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
          Icon(Icons.schedule_rounded, size: 80, color: AppTheme.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('আজকে কোনো শিডিউল নেই', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

