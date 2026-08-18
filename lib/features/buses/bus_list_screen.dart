import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import 'buses_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/widgets/bus_card.dart';

class BusListScreen extends ConsumerStatefulWidget {
  const BusListScreen({super.key});

  @override
  ConsumerState<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends ConsumerState<BusListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      ref.read(busListProvider.notifier).setUserRole(authState.role);
      ref.read(busListProvider.notifier).loadBuses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(busListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            _buildSearchBar(state),
            _buildCategoryChips(state),
            Expanded(child: _buildBusList(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BusListState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.space12,
        left: AppTheme.space24,
        right: AppTheme.space24,
        bottom: AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radiusExtraLarge)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) =>
              ref.read(busListProvider.notifier).setSearchQuery(v),
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'বাস খুঁজুন...',
            hintStyle: TextStyle(color: AppTheme.textHint),
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildCategoryChips(BusListState state) {
    final allCategories = {
      null: 'সব',
      'BLUE': 'নীল',
      'RED': 'লাল',
      'TEACHER': 'শিক্ষক',
      'OFFICER': 'অফিসার',
      'STAFF': 'স্টাফ',
    };

    final allowed = allowedCategoriesForRole(state.userRole);
    final categories = <String?, String>{null: 'সব'};
    for (final entry in allCategories.entries) {
      if (entry.key == null || allowed.contains(entry.key)) {
        categories[entry.key] = entry.value;
      }
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        physics: const BouncingScrollPhysics(),
        children: categories.entries.map((entry) {
          final isSelected = state.selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(busListProvider.notifier).setCategory(entry.key),
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.surfaceDark
                  : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 200.ms),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusList(BusListState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.buses.isEmpty) {
      return _buildErrorState(state.error!);
    }

    final buses = state.filteredBuses;

    if (buses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(busListProvider.notifier).loadBuses(),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24, vertical: AppTheme.space8),
          physics: const BouncingScrollPhysics(),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];
            final busSchedules =
                state.schedules.where((s) => s.busId == bus.id);
            final route = busSchedules.isNotEmpty
                ? busSchedules.first.routeDisplay
                : bus.route ?? 'রুট তথ্য নেই';

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: BusCard(
                    bus: bus,
                    route: route,
                    onTap: () => context.push('/bus/${bus.id}'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space24),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: AppTheme.space12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(busListProvider.notifier).loadBuses(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_rounded,
              size: 80, color: AppTheme.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'কোনো বাস পাওয়া যায়নি',
            style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
