import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/schedule_card.dart';
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
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 28),
            const SizedBox(width: AppTheme.space12),
            const Expanded(
              child: Text(
                'ইন্টারনেট সংযোগ নেই',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'ইন্টারনেট সংযোগ চালু করে রিলোড করুন।\n\n'
          'আপনার আগের ডেটা ক্যাশে সংরক্ষিত আছে।',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _connectionDialogShown = false;
              ref.read(dashboardProvider.notifier).refresh();
            },
            child: const Text(
              'রিলোড করুন',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Text(
          'অ্যাপ বন্ধ করুন',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'আপনি কি নিশ্চিত যে অ্যাপ থেকে বের হতে চান?',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('না', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _showExitDialog();
        },
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernHeader(context, state),
                _buildConnectionStrip(state),
                _buildModernStatGrid(context, state),
                _buildSectionHeader(
                  context,
                  title: 'আজকের সময়সূচি',
                  onSeeAll: () => context.go('/schedules'),
                ),
                _buildSchedulePreviewList(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, DashboardState state) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppTheme.space24,
          left: AppTheme.space24,
          right: AppTheme.space24,
          bottom: AppTheme.space32,
        ),
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radiusExtraLarge),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/buslogo.jpeg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আসসালামু আলাইকুম,',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'CoU Bus Tracker',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildMenuButton(context),
              ],
            ),
            const SizedBox(height: AppTheme.space24),
            _buildHeaderInfoCard(state),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      tooltip: 'মেনু',
      icon: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
      ),
      onSelected: (value) {
        if (value == 'about') {
          context.push('/about');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 12),
              Text('About Us', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfoCard(DashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/buslogo.jpeg',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              state.hasData
                  ? '${state.activeBusCount} টি বাস সক্রিয় আছে'
                  : 'CoU যাত্রী',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatGrid(BuildContext context, DashboardState state) {
    if (state.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppTheme.space24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.space16,
            crossAxisSpacing: AppTheme.space16,
            childAspectRatio: 1.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
            ),
            childCount: 4,
          ),
        ),
      );
    }

    final stats = [
      {
        'label': 'সক্রিয় বাস',
        'value': state.activeBusCount.toString(),
        'icon': Icons.directions_bus_rounded,
        'color': AppTheme.primaryBlue,
      },
      {
        'label': 'আজকের ট্রিপ',
        'value': state.todayScheduleCount.toString(),
        'icon': Icons.schedule_rounded,
        'color': Colors.deepPurple,
      },
      {
        'label': 'লাইভ ট্র্যাকিং',
        'value': state.trackingBusCount.toString(),
        'icon': Icons.location_on_rounded,
        'color': Colors.teal,
      },
      {
        'label': 'জরুরি নোটিশ',
        'value': state.activeNoticeCount.toString(),
        'icon': Icons.notifications_rounded,
        'color': Colors.orange,
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space24,
        vertical: AppTheme.space24,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.space16,
          crossAxisSpacing: AppTheme.space16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final stat = stats[index];
          return StatCard(
            label: stat['label'] as String,
            value: stat['value'] as String,
            icon: stat['icon'] as IconData,
            color: stat['color'] as Color,
            onTap: () {
              final label = stat['label'];
              if (label == 'সক্রিয় বাস' || label == 'লাইভ ট্র্যাকিং')
                context.go('/buses');
              else if (label == 'আজকের ট্রিপ')
                context.go('/schedules');
              else
                context.go('/notices');
            },
          );
        }, childCount: stats.length),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space24,
          vertical: AppTheme.space8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                children: [
                  Text('সব দেখুন'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePreviewList(BuildContext context, DashboardState state) {
    final schedules = state.filteredSchedules;
    if (schedules.isEmpty) {
      if (state.isLoading) return _buildSchedulesLoading();
      return _buildEmptySchedules();
    }

    // Grouping by departure time (limiting to 2-3 groups for preview)
    final groupedSchedules = <String, List<Schedule>>{};
    for (var s in schedules) {
      final time = s.departureTime ?? 'N/A';
      groupedSchedules.putIfAbsent(time, () => []).add(s);
    }

    final sortedTimes = groupedSchedules.keys.toList()..sort();
    final displayTimes = sortedTimes.take(2).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final time = displayTimes[index];
          final timeSchedules = groupedSchedules[time]!;
          return _buildTimeGroup(time, timeSchedules, index);
        }, childCount: displayTimes.length),
      ),
    );
  }

  Widget _buildTimeGroup(String time, List<Schedule> schedules, int index) {
    final bengaliTime = TimeUtils.formatTimeBengali(time);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bengaliTime,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${schedules.length} টি বাস',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              child: AnimationLimiter(
                child: Column(
                  children: List.generate(schedules.length, (i) {
                    final s = schedules[i];
                    return AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 20.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ScheduleCard(
                              schedule: s,
                              onTap: () => context.push(
                                '/bus/${s.busId}?scheduleId=${s.id}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSchedulesLoading() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySchedules() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 48, color: AppTheme.textHint.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('আজকে আর কোনো শিডিউল নেই',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStrip(DashboardState state) {
    if (!state.hasError)
      return const SliverToBoxAdapter(child: SizedBox(height: 12));
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.space24),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 20),
            const SizedBox(width: AppTheme.space12),
            const Expanded(
              child: Text(
                'অফলাইন • সংরক্ষিত তথ্য দেখানো হচ্ছে',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
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
