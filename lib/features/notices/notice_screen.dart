import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import 'notices_provider.dart';
import '../../shared/models/notice.dart';

class NoticeScreen extends ConsumerStatefulWidget {
  const NoticeScreen({super.key});

  @override
  ConsumerState<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends ConsumerState<NoticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noticeListProvider.notifier).loadNotices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noticeListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('নোটিশ'),
        leading: const SizedBox.shrink(),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NoticeListState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.notices.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.notices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(noticeListProvider.notifier).loadNotices(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.notices.length,
        itemBuilder: (context, index) => _buildNoticeCard(state.notices[index]),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notice.title ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.body ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  notice.createdAt != null
                      ? dateFormat.format(notice.createdAt!)
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
                const Spacer(),
                if (notice.expiresAt != null) ...[
                  Icon(
                    notice.isExpired ? Icons.timer_off : Icons.timer,
                    size: 14,
                    color: notice.isExpired ? AppTheme.error : AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.isExpired ? 'মেয়াদোত্তীর্ণ' : 'সক্রিয়',
                    style: TextStyle(
                      fontSize: 12,
                      color: notice.isExpired
                          ? AppTheme.error
                          : AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(noticeListProvider.notifier).loadNotices(),
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppTheme.textHint),
          SizedBox(height: 16),
          Text(
            'এখন কোনো সক্রিয় নোটিশ নেই',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
