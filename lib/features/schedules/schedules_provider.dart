import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../shared/models/schedule.dart';
import 'schedule_repository.dart';
import '../providers.dart';

import '../../core/utils/time_utils.dart';

class ScheduleListState {
  // ... (keeping existing ScheduleListState class)
  final List<Schedule> schedules;
  final String? directionFilter;
  final String?
  dayTypeFilter; // null=today, 'WORKING'=Sat-Thu, 'WEEKEND'=Fri-Sat
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ScheduleListState({
    this.schedules = const [],
    this.directionFilter,
    this.dayTypeFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  ScheduleListState copyWith({
    List<Schedule>? schedules,
    String? Function()? directionFilter,
    String? Function()? dayTypeFilter,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleListState(
      schedules: schedules ?? this.schedules,
      directionFilter: directionFilter != null
          ? directionFilter()
          : this.directionFilter,
      dayTypeFilter: dayTypeFilter != null
          ? dayTypeFilter()
          : this.dayTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Schedule> get filteredSchedules {
    return schedules.where((schedule) {
      // Filter by day type
      final days = (schedule.days ?? '').toUpperCase().trim();
      if (dayTypeFilter == 'WORKING') {
        if (isWeekendSchedule(days)) return false;
      } else if (dayTypeFilter == 'WEEKEND') {
        if (!isWeekendSchedule(days)) return false;
      } else {
        // Default: Today's schedules
        if (!TimeUtils.isScheduleForToday(schedule.days)) return false;
      }

      final matchesDirection =
          directionFilter == null ||
          directionFilter!.isEmpty ||
          schedule.direction?.toUpperCase() == directionFilter!.toUpperCase();

      final rawQuery = searchQuery.trim();
      if (rawQuery.isEmpty) return matchesDirection;

      final query = rawQuery.toLowerCase();
      final englishQuery = TimeUtils.toEnglishDigits(query);

      final time = schedule.departureTime ?? '';
      final bengaliTime = TimeUtils.formatTimeBengali(time).toLowerCase();

      final matchesSearch =
          (schedule.busNumber?.toLowerCase().contains(query) ?? false) ||
          (schedule.busName?.toLowerCase().contains(query) ?? false) ||
          (schedule.startPoint?.toLowerCase().contains(query) ?? false) ||
          (schedule.endPoint?.toLowerCase().contains(query) ?? false) ||
          (time.contains(englishQuery)) ||
          (bengaliTime.contains(query));

      return matchesDirection && matchesSearch;
    }).toList();
  }

  bool isWeekendSchedule(String days) {
    if (days.isEmpty) return false;
    if (days == 'SAT-THU' || days == 'SUN-THU') return false;
    if (days == 'FRI-SAT') return true;

    const workingCodes = ['SUN', 'MON', 'TUE', 'WED', 'THU'];
    const weekendCodes = ['FRI', 'SAT'];
    final hasWorking = workingCodes.any((d) => days.contains(d));
    final hasWeekend = weekendCodes.any((d) => days.contains(d));

    return hasWeekend && !hasWorking;
  }
}

class ScheduleListNotifier extends StateNotifier<ScheduleListState> {
  final ScheduleRepository _repo;
  final StorageService _storage;

  ScheduleListNotifier(this._repo, this._storage)
    : super(const ScheduleListState());

  Future<void> loadSchedules() async {
    // 1. Load from cache
    _loadFromCache();

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  void _loadFromCache() {
    final cached = _storage.getCache(StorageKeys.cachedSchedules);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        final schedules = list.map((e) => Schedule.fromJson(e)).toList();
        state = state.copyWith(schedules: schedules);
      } catch (e) {
        // Ignore cache error
      }
    }
  }

  Future<void> _fetchFromNetwork() async {
    state = state.copyWith(isLoading: state.schedules.isEmpty);

    final result = await _repo.getSchedules();

    switch (result) {
      case Success(:final data):
        await _storage.saveCache(StorageKeys.cachedSchedules, jsonEncode(data));
        state = state.copyWith(schedules: data, isLoading: false);
      case Failure(:final message):
        state = state.copyWith(
          isLoading: false,
          error: state.schedules.isEmpty ? message : null,
        );
      default:
        state = state.copyWith(isLoading: false);
    }
  }

  void setDirectionFilter(String? direction) {
    state = state.copyWith(directionFilter: () => direction);
  }

  void setDayTypeFilter(String? dayType) {
    state = state.copyWith(dayTypeFilter: () => dayType);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final scheduleListProvider =
    StateNotifierProvider<ScheduleListNotifier, ScheduleListState>((ref) {
      return ScheduleListNotifier(
        ref.watch(scheduleRepositoryProvider),
        ref.watch(storageServiceProvider),
      );
    });
