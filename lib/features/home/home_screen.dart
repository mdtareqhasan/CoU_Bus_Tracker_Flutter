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
import '../../app/theme_mode_provider.dart';
import '../../app/locale_provider.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/app_bar_language_switcher.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/schedule_card.dart';
import '../../core/utils/time_utils.dart';
import '../../shared/models/schedule.dart';
import 'home_provider.dart';
import '../auth/auth_provider.dart';
import '../buses/buses_provider.dart';
import '../routes/routes_provider.dart';
import '../../shared/widgets/route_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _connectionDialogShown = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Overlay-based menu state (non-modal so the page stays scrollable).
  OverlayEntry? _menuOverlay;
  final LayerLink _menuLayerLink = LayerLink();
  bool _menuOpen = false;

  void _openMenu(BuildContext context) {
    if (_menuOpen) {
      _closeMenu();
      return;
    }
    _menuOpen = true;

    _menuOverlay = OverlayEntry(
      builder: (overlayCtx) => _NonModalMenu(
        layerLink: _menuLayerLink,
        onClose: _closeMenu,
        onSelected: (value) {
          _closeMenu();
          switch (value) {
            case 'profile':
              context.push('/profile');
            case 'about':
              context.push('/about');
          }
        },
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  void _closeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    _menuOpen = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      ref.read(dashboardProvider.notifier).setUserRole(authState.role);
      ref.read(dashboardProvider.notifier).loadAll();
      // "My Routes" on Home is the shared listing + this rider's pins. Both
      // are cache-first and guarded inside the notifier, so a re-landing is
      // cheap and the section can appear without waiting for the Route tab.
      unawaited(ref.read(routeListProvider.notifier).loadRoutes());
      unawaited(ref.read(routeListProvider.notifier).loadPreferences());
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
            Expanded(
              child: Text(
                ctx.l10n.noInternetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          ctx.l10n.noInternetBody,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _connectionDialogShown = false;
              ref.read(dashboardProvider.notifier).refresh();
            },
            child: Text(
              ctx.l10n.homeReload,
              style: const TextStyle(
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
          ctx.l10n.homeCloseApp,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          ctx.l10n.homeExitMessage,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              ctx.l10n.commonNo,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(80, 40),
            ),
            child: Text(
              ctx.l10n.commonYes,
              style: const TextStyle(color: Colors.white),
            ),
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
    _closeMenu();
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
            onRefresh: () async {
              await Future.wait([
                ref.read(dashboardProvider.notifier).refresh(),
                ref.read(routeListProvider.notifier).loadRoutes(force: true),
                ref.read(routeListProvider.notifier).refreshPreferences(),
              ]);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernHeader(context, state),
                _buildConnectionStrip(context, state),
                _buildModernStatGrid(context, state),
                // Pinned routes only — the section (header included) is
                // omitted entirely while nothing is pinned.
                ..._buildMyRoutesSlivers(context),
                _buildSectionHeader(
                  context,
                  title: context.l10n.todayScheduleTitle,
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
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradientFor(context),
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
                          context.l10n.homeGreeting,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          context.l10n.appName,
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
            _buildHeaderInfoCard(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSmall);
    return CompositedTransformTarget(
      link: _menuLayerLink,
      child: Tooltip(
        message: context.l10n.menuTooltip,
        child: Material(
          // Transparent so the Ink decoration's colour shows through.
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: () => _openMenu(context),
            borderRadius: radius,
            // White ripple that reads well on the gradient header.
            splashColor: Colors.white.withValues(alpha: 0.35),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Ink(
              // Ink carries the decoration so the splash paints above it.
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: radius,
              ),
              padding: const EdgeInsets.all(AppTheme.space8),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfoCard(BuildContext context, DashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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
                  ? context.l10n.homeActiveBusCount(state.activeBusCount)
                  : context.l10n.homeBrandTagline,
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

    // `label` is display-only (localized); navigation keys off `route`, never
    // off the translated text — see docs/localization.md, rule 1.
    final stats = <Map<String, Object>>[
      {
        'label': context.l10n.homeStatActiveBuses,
        'route': '/buses',
        'value': state.activeBusCount.toString(),
        'icon': Icons.directions_bus_rounded,
        'color': AppTheme.primaryBlue,
      },
      {
        'label': context.l10n.homeStatTodayTrips,
        'route': '/schedules',
        'value': state.todayScheduleCount.toString(),
        'icon': Icons.schedule_rounded,
        'color': Colors.deepPurple,
      },
      {
        'label': context.l10n.homeStatLiveTracking,
        'route': '/buses',
        'value': state.trackingBusCount.toString(),
        'icon': Icons.location_on_rounded,
        'color': Colors.teal,
      },
      {
        'label': context.l10n.homeStatUrgentNotice,
        'route': '/notices',
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
            onTap: () => context.go(stat['route'] as String),
          );
        }, childCount: stats.length),
      ),
    );
  }

  /// Pinned routes as one sliver group, or nothing at all while the rider
  /// has no pins (an empty "My Routes" header would just be noise). Rows are
  /// pair-aware like the Route tab: pinning both directions of a corridor
  /// shows one card with two rows; pinning one shows that direction alone —
  /// with no "One way" badge, since the corridor genuinely runs both ways.
  List<Widget> _buildMyRoutesSlivers(BuildContext context) {
    final routeState = ref.watch(routeListProvider);
    // A pin left over from the other role's shift (or from before a role
    // change) — or one whose corridor now has no trips at all — carries no
    // trips this rider can take: keep it off Home rather than render a card
    // that says "No trips yet".
    final allowed = allowedCategoriesForRole(ref.watch(authProvider).role);
    final pinned = routeState.pinnedGroups
        .where((group) => group.shouldListFor(allowed))
        .toList();
    if (!routeState.preferencesLoaded || pinned.isEmpty) {
      return const <Widget>[];
    }

    return [
      _buildSectionHeader(
        context,
        title: context.l10n.routeMyRoutes,
        onSeeAll: () => context.go('/route'),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        sliver: SliverList.builder(
          itemCount: pinned.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space8),
            child: RouteCard(
              group: pinned[index],
              onTap: (routeId) => context.push('/route/$routeId'),
            ),
          ),
        ),
      ),
    ];
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
              child: Row(
                children: [
                  Text(context.l10n.seeAll),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12),
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
      return _buildEmptySchedules(context);
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
    final bengaliTime = TimeUtils.formatTime(time);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(bengaliTime, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                context.l10n.countBuses(schedules.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.space12),
          AnimationLimiter(
            child: Column(
              children: List.generate(schedules.length, (i) {
                final s = schedules[i];
                return AnimationConfiguration.staggeredList(
                  position: i,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ScheduleCard(
                              schedule: s,
                              flat: true,
                              onTap: () => context.push(
                                '/bus/${s.busId}?scheduleId=${s.id}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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

  Widget _buildEmptySchedules(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 48,
                color: AppTheme.textHint.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.noScheduleToday,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStrip(BuildContext context, DashboardState state) {
    if (!state.hasError) {
      return const SliverToBoxAdapter(child: SizedBox(height: 12));
    }
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.space24),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 20),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                context.l10n.offlineBanner,
                style: const TextStyle(
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

/// Plain row used by the navigational entries in the home menu.
///
/// A ConsumerWidget watching [localeProvider] on purpose: the popup is a
/// separate route, so [PopupMenuButton] does not rebuild while it is open —
/// switching language from the menu's own switcher would otherwise leave
/// these rows stuck in the previous language until the menu is reopened.
class _MenuItemRow extends ConsumerWidget {
  const _MenuItemRow({required this.icon, required this.label});

  final IconData icon;
  final String Function(AppLocalizations) label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Text(
          label(context.l10n),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Dark/light switch inside the home menu.
///
/// A [ConsumerWidget] on purpose: the menu is a separate route, so the
/// surrounding [PopupMenuButton] does not rebuild while it is open. Watching
/// the provider here keeps the switch's thumb in sync immediately.
class _ThemeMenuTile extends ConsumerWidget {
  const _ThemeMenuTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild on language change as well: the open popup doesn't rebuild
    // itself, so the label would otherwise stay in the previous language.
    ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Row(
      children: [
        Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.profileDarkMode,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Switch(
          value: isDark,
          onChanged: (enabled) => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light),
        ),
      ],
    );
  }
}

/// Language row inside the home menu: label + current language, switched
/// with the same segmented বাং/EN pill used on the login/registration screens.
class _LanguageMenuTile extends ConsumerWidget {
  const _LanguageMenuTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = ref.watch(localeProvider).languageCode == 'en';

    return Row(
      children: [
        const Icon(
          Icons.translate_rounded,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.profileLanguage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                isEnglish
                    ? context.l10n.languageEnglish
                    : context.l10n.languageBengali,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        // Same segmented বাং/EN switcher as the login/registration screens.
        const SizedBox(width: 16),
        const AppBarLanguageSwitcher(),
      ],
    );
  }
}

/// Non-modal overlay menu shown when the hamburger icon is tapped.
///
/// Unlike [PopupMenuButton] (which pushes a [ModalRoute] and blocks all
/// touch/scroll input behind it), this widget is inserted into the [Overlay]
/// without a modal barrier, so the home page remains fully scrollable while
/// the menu is open. A transparent barrier widget still listens for taps
/// *outside* the menu card to close it, but it lets scroll events pass
/// through to the content underneath.
class _NonModalMenu extends ConsumerWidget {
  const _NonModalMenu({
    required this.layerLink,
    required this.onClose,
    required this.onSelected,
  });

  final LayerLink layerLink;
  final VoidCallback onClose;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Transparent barrier — closes the menu on tap outside, but does NOT
        // block scroll events (no ModalBarrier, no AbsorbPointer).
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            // Allow scroll gestures to pass through to the page behind.
            child: const SizedBox.expand(),
          ),
        ),

        // The menu card itself, anchored below the hamburger button.
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topRight,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile
                  _MenuTile(
                    onTap: () => onSelected('profile'),
                    child: _MenuItemRow(
                      icon: Icons.person_outline_rounded,
                      label: (l10n) => l10n.profileTitle,
                    ),
                  ),
                  const Divider(height: 1),
                  // Theme switch
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _ThemeMenuTile(),
                  ),
                  // Language switch
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _LanguageMenuTile(),
                  ),
                  const Divider(height: 1),
                  // About
                  _MenuTile(
                    onTap: () => onSelected('about'),
                    child: _MenuItemRow(
                      icon: Icons.info_outline_rounded,
                      label: (l10n) => l10n.aboutUsTitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tappable row inside [_NonModalMenu].
class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }
}
