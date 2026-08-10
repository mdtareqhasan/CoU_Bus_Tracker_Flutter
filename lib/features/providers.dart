import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import './buses/bus_repository.dart';
import './schedules/schedule_repository.dart';
import './notices/notice_repository.dart';
import './auth/auth_repository.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in ProviderScope');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepository(ref.watch(apiClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(apiClientProvider));
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
