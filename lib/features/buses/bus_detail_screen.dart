import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/result.dart';
import '../../core/constants.dart';
import '../../shared/models/bus_detail.dart';
import '../../shared/models/schedule.dart';
import '../providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/live_dot.dart';
import '../../shared/widgets/app_pill.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/info_row.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  final int busId;
  final int? initialScheduleId;
  const BusDetailScreen({
    super.key,
    required this.busId,
    this.initialScheduleId,
  });

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  BusDetail? _busDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBusDetail();
  }

  Future<void> _loadBusDetail() async {
    final storage = ref.read(storageServiceProvider);
    final cachedData = storage.getCache(
      StorageKeys.cachedBusDetail(widget.busId),
    );

    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData);
        setState(() {
          _busDetail = BusDetail.fromJson(decoded);
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Cache parsing error: $e');
      }
    }

    final repo = ref.read(busRepositoryProvider);
    final result = await repo.getBusDetail(widget.busId);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        await storage.saveCache(
          StorageKeys.cachedBusDetail(widget.busId),
          jsonEncode(data.toJson()),
        );
        setState(() {
          _busDetail = data;
          _isLoading = false;
          _error = null;
        });
      case Failure(:final message):
        setState(() {
          if (_busDetail == null) {
            _error = message;
          }
          _isLoading = false;
        });
      default:
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildLoadingAppBar(context),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.space24),
          children: const [
            LoadingShimmer(height: 180, borderRadius: AppTheme.radiusLG),
            SizedBox(height: AppTheme.space16),
            LoadingShimmer(height: 100),
            SizedBox(height: AppTheme.space12),
            LoadingShimmer(height: 100),
            SizedBox(height: AppTheme.space12),
            LoadingShimmer(height: 100),
          ],
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.blueVivid),
        body: ErrorState(
          title: context.l10n.commonError,
          body: _error,
          ctaLabel: context.l10n.commonRetry,
          onCtaPressed: _loadBusDetail,
        ),
      );
    }
    return _buildContent();
  }

  PreferredSizeWidget _buildLoadingAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.blueVivid,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildContent() {
    final bus = _busDetail;
    if (bus == null) return const SizedBox.shrink();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(bus),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  title: context.l10n.driverInfoTitle,
                  icon: Icons.person_pin_rounded,
                  content: _buildDriverInfo(bus),
                ),
                const SizedBox(height: AppTheme.space16),
                if (bus.schedules != null && bus.schedules!.isNotEmpty)
                  _buildInfoSection(
                    title: context.l10n.scheduleRouteTitle,
                    icon: Icons.schedule_rounded,
                    content: _buildSchedules(bus),
                  ),
                const SizedBox(height: AppTheme.space24),
                if (bus.trackerUrl != null && bus.trackerUrl!.isNotEmpty)
                  _buildTrackerButton(bus),
                const SizedBox(height: AppTheme.space40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BusDetail bus) {
    final hasTracker = bus.trackerUrl != null && bus.trackerUrl!.isNotEmpty;
    final color = AppTheme.colorForCategory(bus.category);

    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.blueVivid,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (hasTracker)
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space16),
            child: Center(child: const AppPill.live()),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
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
              bottom: -60,
              left: -50,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Hero(
                    tag: 'bus_icon_${bus.id}',
                    child: Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.50),
                            blurRadius: 32,
                            offset: const Offset(0, 0),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/buslogo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.85, 0.85),
                      ),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bus.busNumber ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (hasTracker) ...[
                        const SizedBox(width: AppTheme.space8),
                        const LiveDot(color: Color(0xFFFF5252), size: 9),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      bus.categoryLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.bluePrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, size: 18, color: AppTheme.bluePrimary),
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: AppTheme.space12),
        GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space8,
            vertical: AppTheme.space8,
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildDriverInfo(BusDetail bus) {
    return Column(
      children: [
        if (bus.driverName != null)
          InfoRow(
            icon: Icons.person_rounded,
            label: 'Driver',
            value: bus.driverName!,
            maxLines: 2,
          ),
        if (bus.driverName != null && bus.driverPhone != null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space8),
            child: Divider(height: 1, thickness: 0.5),
          ),
        if (bus.driverPhone != null)
          InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: bus.driverPhone!,
          ),
      ],
    );
  }

  Widget _buildSchedules(BusDetail bus) {
    var schedules = bus.schedules ?? [];
    if (widget.initialScheduleId != null) {
      schedules = schedules
          .where((s) => s.id == widget.initialScheduleId)
          .toList();
    }
    return Column(
      children: schedules.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final isUp = s.direction?.toUpperCase() == 'UP';
        final directionColor = isUp ? AppTheme.success : AppTheme.warning;
        return _buildScheduleRow(s, directionColor, isUp, i);
      }).toList(),
    );
  }

  Widget _buildScheduleRow(
    Schedule s,
    Color directionColor,
    bool isUp,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                size: 16,
                color: AppTheme.bluePrimary,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                s.displayDeparture,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              if (s.days != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bluePrimary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    s.days!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.bluePrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              const Spacer(),
              AppPill(
                label: s.directionLabel,
                icon: isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: directionColor,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: AppTheme.space24),
            child: Text(
              s.routeDisplay,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: (index * 60).ms,
          duration: 320.ms,
        ).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrackerButton(BusDetail bus) {
    return PrimaryButton(
      label: context.l10n.busSeeLiveLocation,
      icon: Icons.location_on_rounded,
      onPressed: () {
        final url = bus.trackerUrl!;
        final name = bus.busNumber ??
            bus.busName ??
            context.l10n.busTrackingTitle;
        context.push(
          '/bus/live/${bus.id}',
          extra: {'url': url, 'name': name},
        );
      },
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.15, end: 0);
  }
}
