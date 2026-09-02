import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../shared/models/notice.dart';
import 'notice_repository.dart';
import '../providers.dart';

class NoticeListState {
  final List<Notice> notices;
  final bool isLoading;
  final String? error;

  const NoticeListState({
    this.notices = const [],
    this.isLoading = false,
    this.error,
  });

  NoticeListState copyWith({
    List<Notice>? notices,
    bool? isLoading,
    String? error,
  }) {
    return NoticeListState(
      notices: notices ?? this.notices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NoticeListNotifier extends StateNotifier<NoticeListState> {
  final NoticeRepository _repo;

  NoticeListNotifier(this._repo) : super(const NoticeListState());

  Future<void> loadNotices() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.getActiveNotices();

    switch (result) {
      case Success(:final data):
        state = state.copyWith(notices: data, isLoading: false);
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
      default:
        state = state.copyWith(isLoading: false);
    }
  }
}

final noticeListProvider =
    StateNotifierProvider<NoticeListNotifier, NoticeListState>((ref) {
      return NoticeListNotifier(ref.watch(noticeRepositoryProvider));
    });
