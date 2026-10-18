import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import 'notices_provider.dart';
import '../../shared/models/notice.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/home');
        },
        child: Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                  child: _buildBody(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      backgroundColor: AppTheme.blueVivid,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.go('/home'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            context.l10n.noticeTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
            ),
            Positioned(
              top: -40,
              right: -30,
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
              left: -40,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NoticeListState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.notices.isEmpty) {
      return ErrorState(
        title: context.l10n.commonError,
        body: state.error,
        ctaLabel: context.l10n.commonRetry,
        onCtaPressed: () =>
            ref.read(noticeListProvider.notifier).loadNotices(),
      );
    }

    if (state.notices.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none_rounded,
        title: context.l10n.noticeEmpty,
      );
    }

    return RefreshIndicator(
      color: AppTheme.bluePrimary,
      onRefresh: () => ref.read(noticeListProvider.notifier).loadNotices(),
      child: AnimationLimiter(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space12,
            AppTheme.space24,
            AppTheme.space40,
          ),
          itemCount: state.notices.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (context, index) {
            final notice = state.notices[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 360),
              child: SlideAnimation(
                verticalOffset: 18,
                child: FadeInAnimation(
                  child: _buildNoticeCard(notice, index),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice, int index) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isExpired = notice.isExpired;
    final statusColor = isExpired ? AppTheme.error : AppTheme.success;

    return GlassCard(
      padding: EdgeInsets.zero,
      elevation: GlassCardElevation.soft,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left rail — category color band
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLG),
                  bottomLeft: Radius.circular(AppTheme.radiusLG),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Text(
                            notice.title ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.1,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((notice.body ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        notice.body!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notice.createdAt != null
                              ? dateFormat.format(notice.createdAt!)
                              : '',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        if (notice.expiresAt != null)
                          AppPill(
                            label: isExpired
                                ? context.l10n.noticeExpired
                                : context.l10n.noticeActive,
                            icon: isExpired
                                ? Icons.timer_off_rounded
                                : Icons.timer_rounded,
                            color: statusColor,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space12,
        AppTheme.space24,
        AppTheme.space40,
      ),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
      itemBuilder: (_, __) => const LoadingShimmer(height: 140),
    );
  }
}
