import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../shared/models/bus.dart';
import '../../shared/models/schedule.dart';
import '../../shared/models/bus_detail.dart';
import 'bus_repository.dart';
import '../schedules/schedule_repository.dart';
import '../providers.dart';

const studentBusCategories = {'BLUE', 'RED', 'STAFF'};
const teacherBusCategories = {'TEACHER', 'OFFICER'};

Set<String> allowedCategoriesForRole(String? role) {
  if (role == 'teacher') return teacherBusCategories;
  return studentBusCategories;
}

class BusListState {
  // ... (keeping existing BusListState class)
  final List<Bus> buses;
  final List<Schedule> schedules;
  final String? selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final String? userRole;

  const BusListState({
    this.buses = const [],
    this.schedules = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.userRole,
  });

  BusListState copyWith({
    List<Bus>? buses,
    List<Schedule>? schedules,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? error,
    String? userRole,
  }) {
    return BusListState(
      buses: buses ?? this.buses,
      schedules: schedules ?? this.schedules,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRole: userRole ?? this.userRole,
    );
  }

  List<Bus> get filteredBuses {
    final allowed = allowedCategoriesForRole(userRole);
    return buses.where((bus) {
      final category = bus.category?.toUpperCase();
      if (category == null || !allowed.contains(category)) return false;

      final matchesCategory =
          selectedCategory == null ||
          selectedCategory!.isEmpty ||
          category == selectedCategory!.toUpperCase();

      final query = searchQuery.toLowerCase();

      // Get route from schedules if available
      final busSchedules = schedules.where((s) => s.busId == bus.id);
      final route = busSchedules.isNotEmpty
          ? busSchedules.first.routeDisplay
          : bus.route ?? '';

      final matchesSearch =
          query.isEmpty ||
          (bus.busNumber?.toLowerCase().contains(query) ?? false) ||
          (bus.busName?.toLowerCase().contains(query) ?? false) ||
          (route.toLowerCase().contains(query));

      return matchesCategory && matchesSearch;
    }).toList();
  }
}

class BusListNotifier extends StateNotifier<BusListState> {
  final BusRepository _busRepo;
  final ScheduleRepository _scheduleRepo;
  final StorageService _storage;

  BusListNotifier(this._busRepo, this._scheduleRepo, this._storage)
    : super(const BusListState());

  void setUserRole(String? role) {
    state = state.copyWith(userRole: role);
  }

  Future<void> loadBuses() async {
    // 1. Load from cache
    _loadFromCache();

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  void _loadFromCache() {
    final cachedBuses = _storage.getCache(StorageKeys.cachedBuses);
    final cachedSchedules = _storage.getCache(StorageKeys.cachedSchedules);

    List<Bus>? buses;
    List<Schedule>? schedules;

    if (cachedBuses != null) {
      final List<dynamic> list = jsonDecode(cachedBuses);
      buses = list.map((e) => Bus.fromJson(e)).toList();
    }
    if (cachedSchedules != null) {
      final List<dynamic> list = jsonDecode(cachedSchedules);
      schedules = list.map((e) => Schedule.fromJson(e)).toList();
    }

    if (buses != null || schedules != null) {
      state = state.copyWith(
        buses: buses ?? state.buses,
        schedules: schedules ?? state.schedules,
      );
    }
  }

  Future<void> _fetchFromNetwork() async {
    state = state.copyWith(isLoading: state.buses.isEmpty);

    final results = await Future.wait([
      _busRepo.getBuses().then((r) => r),
      _scheduleRepo.getSchedules().then((r) => r),
    ]);

    final busResult = results[0] as Result<List<Bus>>;
    final scheduleResult = results[1] as Result<List<Schedule>>;

    if (busResult is Success && scheduleResult is Success) {
      final buses = (busResult as Success<List<Bus>>).data;
      final schedules = (scheduleResult as Success<List<Schedule>>).data;

      await _storage.saveCache(StorageKeys.cachedBuses, jsonEncode(buses));
      await _storage.saveCache(
        StorageKeys.cachedSchedules,
        jsonEncode(schedules),
      );

      state = state.copyWith(
        buses: buses,
        schedules: schedules,
        isLoading: false,
      );

      // Start background pre-caching for all bus details
      _preCacheBusDetails(buses);
    } else if (busResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: state.buses.isEmpty ? (busResult as Failure).message : null,
      );
    } else if (scheduleResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: state.buses.isEmpty ? (scheduleResult as Failure).message : null,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Background task to fetch and cache details for every bus
  Future<void> _preCacheBusDetails(List<Bus> buses) async {
    for (final bus in buses) {
      if (bus.id == null) continue;

      try {
        final result = await _busRepo.getBusDetail(bus.id!);
        if (result is Success) {
          final detail = (result as Success<BusDetail>).data;
          await _storage.saveCache(
            StorageKeys.cachedBusDetail(bus.id!),
            jsonEncode(detail.toJson()),
          );
        }
      } catch (e) {
        // Silently fail for background tasks
      }
      // Small delay to avoid hammering the server
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final busListProvider = StateNotifierProvider<BusListNotifier, BusListState>((
  ref,
) {
  return BusListNotifier(
    ref.watch(busRepositoryProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(storageServiceProvider),
  );
});
