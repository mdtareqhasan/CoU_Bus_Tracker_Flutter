import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../core/result.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../shared/models/bus_detail.dart';
import '../../shared/models/schedule.dart';
import '../providers.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
// ... existing code ...
  final int busId;
  final int? initialScheduleId;
  const BusDetailScreen({super.key, required this.busId, this.initialScheduleId});

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
    // 1. Try to load from cache first for instant UI
    final storage = ref.read(storageServiceProvider);
    final cachedData = storage.getCache(StorageKeys.cachedBusDetail(widget.busId));
    
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

    // 2. Fetch fresh data from network
    final repo = ref.read(busRepositoryProvider);
    final result = await repo.getBusDetail(widget.busId);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        // Save to cache for next time
        await storage.saveCache(StorageKeys.cachedBusDetail(widget.busId), jsonEncode(data.toJson()));
        setState(() {
          _busDetail = data;
          _isLoading = false;
          _error = null;
        });
      case Failure(:final message):
        setState(() {
          // Only show error if we don't even have cached data
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
    return Scaffold(
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
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
                  title: 'ড্রাইভার তথ্য',
                  icon: Icons.person_pin_rounded,
                  content: _buildDriverInfo(bus),
                ),
                const SizedBox(height: AppTheme.space24),
                if (bus.schedules != null && bus.schedules!.isNotEmpty)
                  _buildInfoSection(
                    title: 'শিডিউল ও রুট',
                    icon: Icons.schedule_rounded,
                    content: _buildSchedules(bus),
                  ),
                const SizedBox(height: AppTheme.space32),
                if (bus.trackerUrl != null && bus.trackerUrl!.isNotEmpty)
                  _buildTrackerButton(bus),
                const SizedBox(height: AppTheme.space48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BusDetail bus) {
    final hasTracker = bus.trackerUrl != null && bus.trackerUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: FlexibleSpaceBar(
          stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
          background: Stack(
            children: [
              // Abstract background decoration
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeroIcon(bus),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bus.busNumber ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        if (hasTracker) ...[
                          const SizedBox(width: 8),
                          _buildLiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bus.categoryLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fade(duration: 800.ms, begin: 0.3, end: 1),
          const SizedBox(width: 4),
          const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(BusDetail bus) {
    return Hero(
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/buslogo.jpeg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildInfoSection({required String title, required IconData icon, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.softShadow,
          ),
          child: content,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRouteInfo(BusDetail bus) {
    final route = (bus.schedules != null && bus.schedules!.isNotEmpty)
        ? bus.schedules!.first.routeDisplay
        : bus.route ?? 'রুট তথ্য নেই';

    return Row(
      children: [
        const Icon(Icons.route_rounded, size: 18, color: AppTheme.textHint),
        const SizedBox(width: 12),
        Expanded(child: Text(route, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _buildDriverInfo(BusDetail bus) {
    return Column(
      children: [
        if (bus.driverName != null)
          _buildInfoRow(Icons.person_rounded, bus.driverName!),
        if (bus.driverPhone != null) ...[
          const Divider(height: 24, thickness: 0.5),
          _buildInfoRow(Icons.phone_rounded, bus.driverPhone!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textHint),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSchedules(BusDetail bus) {
    var schedules = bus.schedules ?? [];
    
    // Filter by initialScheduleId if coming from Schedule page
    if (widget.initialScheduleId != null) {
      schedules = schedules.where((s) => s.id == widget.initialScheduleId).toList();
    }

    return Column(
      children: schedules.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Text(s.displayDeparture, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                if (s.days != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.days!,
                      style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                const Spacer(),
                _buildDirectionBadge(s),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 16, color: AppTheme.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.routeDisplay,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
            if (schedules.indexOf(s) != schedules.length - 1)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Divider(height: 1, thickness: 0.5),
              ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDirectionBadge(Schedule s) {
    final isUp = s.direction?.toUpperCase() == 'UP';
    final color = isUp ? AppTheme.success : AppTheme.warning;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        s.directionLabel,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTrackerButton(BusDetail bus) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ElevatedButton(
        onPressed: () {
          final url = bus.trackerUrl!;
          final name = bus.busNumber ?? bus.busName ?? 'বাস ট্র্যাকিং';
          context.push(
            Uri(
              path: '/bus/live/${bus.id}',
              queryParameters: {'url': url, 'name': name},
            ).toString(),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('লাইভ লোকেশন দেখুন', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(_error ?? 'ত্রুটি'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadBusDetail, child: const Text('আবার চেষ্টা করুন')),
        ],
      ),
    );
  }
}

