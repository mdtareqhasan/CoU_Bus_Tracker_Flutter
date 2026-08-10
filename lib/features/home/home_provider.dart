import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../shared/models/bus.dart';
import '../../shared/models/schedule.dart';
import '../../shared/models/notice.dart';
import '../providers.dart';
import '../buses/bus_repository.dart';
import '../schedules/schedule_repository.dart';
import '../notices/notice_repository.dart';
import '../../core/utils/time_utils.dart';

class DashboardState {
  final AsyncValue<List<Bus>> buses;
  final AsyncValue<List<Schedule>> schedules;
  final AsyncValue<List<Notice>> notices;
  final DateTime? lastUpdated;

  const DashboardState({
    this.buses = const AsyncValue.loading(),
    this.schedules = const AsyncValue.loading(),
    this.notices = const AsyncValue.loading(),
    this.lastUpdated,
  });

  DashboardState copyWith({
    AsyncValue<List<Bus>>? buses,
    AsyncValue<List<Schedule>>? schedules,
    AsyncValue<List<Notice>>? notices,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      buses: buses ?? this.buses,
      schedules: schedules ?? this.schedules,
      notices: notices ?? this.notices,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  int get activeBusCount => buses.valueOrNull?.length ?? 0;
  int get todayScheduleCount => schedules.valueOrNull?.length ?? 0;
  int get trackingBusCount =>
      buses.valueOrNull?.where((b) => b.trackerUrl != null && b.trackerUrl!.isNotEmpty).length ?? 0;
  int get activeNoticeCount => notices.valueOrNull?.length ?? 0;

  bool get isLoading =>
      buses is AsyncLoading || schedules is AsyncLoading || notices is AsyncLoading;

  bool get hasError =>
      buses is AsyncError || schedules is AsyncError || notices is AsyncError;

  bool get hasData =>
      buses.hasValue || schedules.hasValue || notices.hasValue;
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final BusRepository _busRepo;
  final ScheduleRepository _scheduleRepo;
  final NoticeRepository _noticeRepo;
  final StorageService _storage;

  DashboardNotifier(this._busRepo, this._scheduleRepo, this._noticeRepo, this._storage)
      : super(const DashboardState());

  Future<void> loadAll() async {
    // 1. Try loading from cache first
    _loadFromCache();

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  void _loadFromCache() {
    final cachedBuses = _storage.getCache(StorageKeys.cachedBuses);
    final cachedSchedules = _storage.getCache(StorageKeys.cachedSchedules);
    final cachedNotices = _storage.getCache(StorageKeys.cachedNotices);

    List<Bus>? buses;
    List<Schedule>? schedules;
    List<Notice>? notices;

    if (cachedBuses != null) {
      final List<dynamic> list = jsonDecode(cachedBuses);
      buses = list.map((e) => Bus.fromJson(e)).toList();
    }
    if (cachedSchedules != null) {
      final List<dynamic> list = jsonDecode(cachedSchedules);
      schedules = list.map((e) => Schedule.fromJson(e)).toList();
    }
    if (cachedNotices != null) {
      final List<dynamic> list = jsonDecode(cachedNotices);
      notices = list.map((e) => Notice.fromJson(e)).toList();
    }

    if (buses != null || schedules != null || notices != null) {
      state = state.copyWith(
        buses: buses != null ? AsyncValue.data(buses) : state.buses,
        schedules: schedules != null ? AsyncValue.data(schedules.where((s) => TimeUtils.isScheduleForToday(s.days)).toList()) : state.schedules,
        notices: notices != null ? AsyncValue.data(notices) : state.notices,
      );
    }
  }

  Future<void> _fetchFromNetwork() async {
    // Handling individual results to prevent fail-fast behavior
    final results = await Future.wait([
      _busRepo.getBuses().then((r) => r),
      _scheduleRepo.getSchedules().then((r) => r),
      _noticeRepo.getActiveNotices().then((r) => r),
    ]);

    final busResult = results[0] as Result<List<Bus>>;
    final scheduleResult = results[1] as Result<List<Schedule>>;
    final noticeResult = results[2] as Result<List<Notice>>;

    if (busResult is Success) {
      final data = (busResult as Success<List<Bus>>).data;
      await _storage.saveCache(StorageKeys.cachedBuses, jsonEncode(data));
      state = state.copyWith(buses: AsyncValue.data(data));
    }

    if (scheduleResult is Success) {
      final data = (scheduleResult as Success<List<Schedule>>).data;
      await _storage.saveCache(StorageKeys.cachedSchedules, jsonEncode(data));
      state = state.copyWith(
          schedules: AsyncValue.data(data.where((s) => TimeUtils.isScheduleForToday(s.days)).toList()));
    }

    if (noticeResult is Success) {
      final data = (noticeResult as Success<List<Notice>>).data;
      await _storage.saveCache(StorageKeys.cachedNotices, jsonEncode(data));
      state = state.copyWith(notices: AsyncValue.data(data));
    }

    state = state.copyWith(lastUpdated: DateTime.now());
  }

  Future<void> refresh() async => _fetchFromNetwork();
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.watch(busRepositoryProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(noticeRepositoryProvider),
    ref.watch(storageServiceProvider),
  );
});
