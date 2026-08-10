import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/schedule_card.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(context, state),
              _buildConnectionStrip(state),
              if (state.hasError && !state.hasData)
                _buildErrorCard(state)
              else ...[
                _buildModernStatGrid(context, state),
                _buildSectionHeader(
                  context, 
                  title: 'আজকের সময়সূচি', 
                  onSeeAll: () => context.go('/schedules')
                ),
                _buildSchedulePreviewList(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
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
              Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.primaryBlue),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                  ? '${state.buses.valueOrNull?.length ?? 0} টি বাস সক্রিয় আছে'
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
      {'label': 'সক্রিয় বাস', 'value': state.activeBusCount.toString(), 'icon': Icons.directions_bus_rounded, 'color': AppTheme.primaryBlue},
      {'label': 'আজকের ট্রিপ', 'value': state.todayScheduleCount.toString(), 'icon': Icons.schedule_rounded, 'color': Colors.deepPurple},
      {'label': 'লাইভ ট্র্যাকিং', 'value': state.trackingBusCount.toString(), 'icon': Icons.location_on_rounded, 'color': Colors.teal},
      {'label': 'জরুরি নোটিশ', 'value': state.activeNoticeCount.toString(), 'icon': Icons.notifications_rounded, 'color': Colors.orange},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.space16,
          crossAxisSpacing: AppTheme.space16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat['label'] as String,
              value: stat['value'] as String,
              icon: stat['icon'] as IconData,
              color: stat['color'] as Color,
              onTap: () {
                final label = stat['label'];
                if (label == 'সক্রিয় বাস' || label == 'লাইভ ট্র্যাকিং') context.go('/buses');
                else if (label == 'আজকের ট্রিপ') context.go('/schedules');
                else context.go('/notices');
              },
            );
          },
          childCount: stats.length,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required VoidCallback onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space8),
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
    final schedules = state.schedules.valueOrNull ?? [];
    if (schedules.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final s = schedules[index];
            return ScheduleCard(
              schedule: s, 
              onTap: () => context.push('/bus/${s.busId}?scheduleId=${s.id}')
            ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
          },
          childCount: schedules.length > 5 ? 5 : schedules.length,
        ),
      ),
    );
  }

  Widget _buildConnectionStrip(DashboardState state) {
    if (!state.hasError) return const SliverToBoxAdapter(child: SizedBox(height: 12));
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
                style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(DashboardState state) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 64),
            const SizedBox(height: 16),
            const Text('তথ্য লোড করা যায়নি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ইন্টারনেট সংযোগ পরীক্ষা করুন', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
