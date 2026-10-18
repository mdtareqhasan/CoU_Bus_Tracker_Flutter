import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/schedule_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/live_dot.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_pill.dart';
import '../../core/utils/time_utils.dart';
import '../../shared/models/schedule.dart';
import 'home_provider.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _connectionDialogShown = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      ref.read(dashboardProvider.notifier).setUserRole(authState.role);
      ref.read(dashboardProvider.notifier).loadAll();
      _startConnectivityListener();
    });
  }

  void _startConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && mounted) {
        if (_connectionDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
          _connectionDialogShown = false;
        }
        ref.read(dashboardProvider.notifier).refresh();
      } else if (!hasConnection && mounted && !_connectionDialogShown) {
        _showNoInternetDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    _connectionDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                ctx.l10n.noInternetTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          ctx.l10n.noInternetBody,
          style: const TextStyle(height: 1.5, fontSize: 14),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _connectionDialogShown = false;
              ref.read(dashboardProvider.notifier).refresh();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.bluePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Text(ctx.l10n.homeReload),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        color: AppTheme.bluePrimary,
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surface,
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildModernHeader(context, state),
            if (state.hasError) _buildConnectionStrip(context, state),
            SliverToBoxAdapter(
              child: _buildHeroStats(context, state),
            ),
            SliverToBoxAdapter(
              child: _buildNextBusCard(context, state),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: context.l10n.todayScheduleTitle,
                actionLabel: context.l10n.seeAll,
                onAction: () => context.go('/schedules'),
                icon: Icons.schedule_rounded,
              ),
            ),
            _buildSchedulePreviewList(context, state),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space40)),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildModernHeader(BuildContext context, DashboardState state) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppTheme.space16,
          left: AppTheme.space24,
          right: AppTheme.space24,
          bottom: AppTheme.space32,
        ),
        decoration: const BoxDecoration(
          gradient: AppTheme.auroraHeaderGradient,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radius2XL),
          ),
        ),
        child: Stack(
          children: [
            // Soft glow blob top right
            Positioned(
              top: -60,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppTheme.cyanBright.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.indigoDeep.withValues(alpha: 0.40),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/buslogo.jpeg',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.homeGreeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildMenuButton(context),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                const SizedBox(height: AppTheme.space20),
                _buildHeaderInfoCard(context, state).animate().fadeIn(
                      delay: 120.ms,
                      duration: 400.ms,
                    ).slideY(begin: 0.15, end: 0, curve: Motion.enter),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      tooltip: context.l10n.menuTooltip,
      icon: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
      ),
      onSelected: (value) {
        if (value == 'about') context.push('/about');
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'about',
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
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.bluePrimary,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              const Text(
                'About Us',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfoCard(BuildContext context, DashboardState state) {
    final tracking = state.trackingBusCount;
    final hasLive = tracking > 0;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          if (hasLive) const Padding(
            padding: EdgeInsets.only(right: AppTheme.space8),
            child: LiveDot(color: AppTheme.cyanBright, size: 8),
          ),
          Expanded(
            child: Text(
              state.hasData
                  ? context.l10n.homeActiveBusCount(state.activeBusCount)
                  : context.l10n.homeBrandTagline,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (hasLive)
            const AppPill.live(),
        ],
      ),
    );
  }

  // ─── Hero stats (2 prominent + 2 secondary) ────────────────────────────
  Widget _buildHeroStats(BuildContext context, DashboardState state) {
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space8,
        ),
        child: Row(
          children: [
            Expanded(
              child: LoadingShimmer(
                height: 130,
                borderRadius: AppTheme.radiusLG,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: LoadingShimmer(
                height: 130,
                borderRadius: AppTheme.radiusLG,
              ),
            ),
          ],
        ),
      );
    }

    // `label` is display-only (localized); navigation keys off `route`, never
    // off the translated text — see docs/localization.md, rule 1.
    final heroStats = <_Stat>[
      _Stat(
        label: context.l10n.homeStatActiveBuses,
        value: state.activeBusCount.toString(),
        icon: Icons.directions_bus_rounded,
        gradient: AppTheme.auroraHeaderGradient,
        route: '/buses',
        isHero: true,
      ),
      _Stat(
        label: context.l10n.homeStatTodayTrips,
        value: state.todayScheduleCount.toString(),
        icon: Icons.schedule_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/schedules',
        isHero: true,
      ),
    ];
    final secondaryStats = <_Stat>[
      _Stat(
        label: context.l10n.homeStatLiveTracking,
        value: state.trackingBusCount.toString(),
        icon: Icons.location_on_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/buses',
        isHero: false,
      ),
      _Stat(
        label: context.l10n.homeStatUrgentNotice,
        value: state.activeNoticeCount.toString(),
        icon: Icons.notifications_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/notices',
        isHero: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space4,
      ),
      child: AnimationLimiter(
        child: Column(
          children: [
            Row(
              children: [
                for (int i = 0; i < heroStats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: AnimationConfiguration.staggeredList(
                      position: i,
                      duration: Motion.durMed,
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: StatCard(
                            label: heroStats[i].label,
                            value: heroStats[i].value,
                            icon: heroStats[i].icon,
                            gradient: heroStats[i].gradient,
                            isHero: true,
                            onTap: () => context.go(heroStats[i].route),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                for (int i = 0; i < secondaryStats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: AnimationConfiguration.staggeredList(
                      position: i + 2,
                      duration: Motion.durMed,
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: StatCard(
                            label: secondaryStats[i].label,
                            value: secondaryStats[i].value,
                            icon: secondaryStats[i].icon,
                            gradient: secondaryStats[i].gradient,
                            isHero: false,
                            onTap: () => context.go(secondaryStats[i].route),
                          ),
                        ),
                      ),
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

  // ─── Next bus hero card ────────────────────────────────────────────────
  Widget _buildNextBusCard(BuildContext context, DashboardState state) {
    final next = _nextSchedule(state);
    if (next == null) {
      return const SizedBox.shrink();
    }
    final isUp = next.direction?.toUpperCase() == 'UP';
    final categoryColor = AppTheme.colorForCategory(next.category);
    final countdown = _minutesUntil(next.departureTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space8,
      ),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space20,
          AppTheme.space16,
          AppTheme.space16,
          AppTheme.space16,
        ),
        elevation: GlassCardElevation.glow,
        glowColor: AppTheme.blueVivid,
        onTap: () =>
            context.push('/bus/${next.busId}?scheduleId=${next.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bluePrimary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppTheme.bluePrimary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Next bus',
                        style: TextStyle(
                          color: AppTheme.bluePrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppPill(
                  label: next.directionLabel,
                  icon: isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isUp ? AppTheme.success : AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.displayDeparture,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${next.busNumber ?? '—'} · ${next.busName ?? ''}'
                            .replaceAll(' · ', '  ·  '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (countdown != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        countdown,
                        style: const TextStyle(
                          color: AppTheme.bluePrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Text(
                        'min',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 14,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    next.routeDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.textHint,
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 280.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Schedule? _nextSchedule(DashboardState state) {
    final list = state.filteredSchedules;
    if (list.isEmpty) return null;
    final now = TimeOfDay.now();
    int nowMin = now.hour * 60 + now.minute;
    final parsed = list.map((s) {
      final t = s.departureTime?.split(':');
      if (t == null || t.length < 2) return null;
      final h = int.tryParse(t[0]) ?? 0;
      final m = int.tryParse(t[1]) ?? 0;
      return MapEntry(s, h * 60 + m);
    }).whereType<MapEntry<Schedule, int>>().toList();
    if (parsed.isEmpty) return list.first;
    parsed.sort((a, b) => a.value.compareTo(b.value));
    for (final e in parsed) {
      if (e.value >= nowMin) return e.key;
    }
    return parsed.first.key;
  }

  String? _minutesUntil(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, h, m);
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    final diff = dt.difference(now).inMinutes;
    if (diff < 0) return null;
    return diff.toString();
  }

  // ─── Schedule preview ──────────────────────────────────────────────────
  Widget _buildSchedulePreviewList(BuildContext context, DashboardState state) {
    if (state.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space12),
              child: LoadingShimmer(
                height: 84,
                borderRadius: AppTheme.radiusLG,
              ),
            ),
            childCount: 3,
          ),
        ),
      );
    }
    final schedules = state.filteredSchedules;
    if (schedules.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.schedule_rounded,
          title: context.l10n.noScheduleToday,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space48),
        ),
      );
    }

    final grouped = <String, List<Schedule>>{};
    for (var s in schedules) {
      final t = s.departureTime ?? 'N/A';
      grouped.putIfAbsent(t, () => []).add(s);
    }
    final sortedTimes = grouped.keys.toList()..sort();
    final displayTimes = sortedTimes.take(3).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final time = displayTimes[index];
          final list = grouped[time]!;
          return _buildTimeGroup(time, list, index);
        }, childCount: displayTimes.length),
      ),
    );
  }

  Widget _buildTimeGroup(String time, List<Schedule> schedules, int index) {
    final bengaliTime = TimeUtils.formatTime(time);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previews = schedules.take(2).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space8,
                AppTheme.space8,
                AppTheme.space8,
                AppTheme.space4,
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
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
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
                  ),
                ],
              ),
            ),
            AnimationLimiter(
              child: Column(
                children: List.generate(previews.length, (i) {
                  final s = previews[i];
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 280),
                    child: SlideAnimation(
                      verticalOffset: 12,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ScheduleCard(
                            schedule: s,
                            onTap: () => context.push(
                              '/bus/${s.busId}?scheduleId=${s.id}',
                            ),
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
          ],
        ),
      ).animate().fadeIn(delay: (index * 80).ms, duration: 360.ms).slideY(
            begin: 0.1,
            end: 0,
            curve: Motion.enter,
          ),
    );
  }

  // ─── Connection strip ──────────────────────────────────────────────────
  Widget _buildConnectionStrip(BuildContext context, DashboardState state) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space16,
          AppTheme.space24,
          0,
        ),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 18),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                context.l10n.offlineBanner,
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final String route;
  final bool isHero;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.isHero,
  });
}
