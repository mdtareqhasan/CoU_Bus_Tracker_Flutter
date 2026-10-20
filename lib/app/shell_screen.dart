import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import 'theme.dart';

/// Bottom-navigation shell around the five main tabs.
///
/// The tabs themselves live in the [StatefulShellRoute] branches (see
/// `router.dart`), so each keeps its own navigation stack and state. This
/// widget draws the tab bar around them; the branch navigators are hosted by
/// [buildShellNavigatorContainer], a pager that also lets the user swipe
/// left/right between tabs.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.navigationShell});

  /// The shell state from the [StatefulShellRoute] — owns the per-tab
  /// navigators and is what actually switches branch when a tab is tapped,
  /// swiped, or reached through a deep link / the back button.
  final StatefulNavigationShell navigationShell;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  StatefulNavigationShell get _shell => widget.navigationShell;

  bool _isHomeTab() => _shell.currentIndex == 0;

  Future<bool> _onWillPop() async {
    if (_isHomeTab()) {
      // On home tab — show exit confirmation dialog
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            ctx.l10n.exitAppTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(ctx.l10n.exitAppMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.commonNo),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.commonYes,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return false;
    } else {
      // On other tabs — go to home
      _shell.goBranch(0);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        // The shell builds [buildShellNavigatorContainer], i.e. the pager
        // holding every tab navigator.
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _shell.currentIndex,
          onTap: (index) => _shell.goBranch(index),
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          // Not `Colors.white24` in dark mode: that is white at 24% opacity,
          // which renders ~2.2:1 on the dark bar and is barely readable.
          // `textHint` lands at ~5.7:1 there (and is unchanged in light).
          unselectedItemColor: AppTheme.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 15,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: context.l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions_bus_outlined),
              activeIcon: const Icon(Icons.directions_bus_rounded),
              label: context.l10n.navBuses,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.schedule_outlined),
              activeIcon: const Icon(Icons.schedule_rounded),
              label: context.l10n.navSchedules,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: context.l10n.navNotices,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: context.l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Container for the branch navigators of the [StatefulShellRoute]: a
/// [PageView], so tabs can also be swiped left/right instead of only tapped.
///
/// Wired up as the route's `navigatorContainerBuilder`; the shell passes one
/// child per branch, in branch order, so page index == branch index.
Widget buildShellNavigatorContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  return _ShellPager(navigationShell: navigationShell, children: children);
}

class _ShellPager extends StatefulWidget {
  const _ShellPager({required this.navigationShell, required this.children});

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<_ShellPager> createState() => _ShellPagerState();
}

class _ShellPagerState extends State<_ShellPager> {
  static const _tabSwitchDuration = Duration(milliseconds: 250);
  static const _tabSwitchCurve = Curves.easeOutCubic;

  late final PageController _controller = PageController();

  /// The tab this pager last moved to *by itself* (a swipe). Branch changes
  /// that came from somewhere else — tab tap, back button, deep link — have
  /// to be reflected here, but syncing to our own swipe would fight the
  /// gesture.
  int _lastSwipedTo = 0;

  /// Whether the current scroll is driven by a finger. A tab tap animates the
  /// pager over several pages, and `onPageChanged` reports each page it flies
  /// past — without this flag the shell would hop through every tab in
  /// between (and the URL and tab bar with it).
  bool _userScrolling = false;

  /// Whether the pager has been aligned to the shell once. The first
  /// alignment jumps: a deep link straight to /notices must not visibly swipe
  /// across the tabs before it on the very first frame.
  bool _alignedOnce = false;

  @override
  void initState() {
    super.initState();
    // The pager can be built on a branch that isn't the first one (deep link
    // straight into e.g. /notices).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncToShell());
  }

  @override
  void didUpdateWidget(covariant _ShellPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncToShell();
  }

  void _syncToShell() {
    if (!mounted || !_controller.hasClients) return;

    final firstAlignment = !_alignedOnce;
    _alignedOnce = true;

    final target = widget.navigationShell.currentIndex;
    if (target == _lastSwipedTo) return;
    _lastSwipedTo = target;
    _userScrolling = false; // we take the pager over from here

    if (firstAlignment) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: _tabSwitchDuration,
        curve: _tabSwitchCurve,
      );
    }
  }

  /// Re-aligns the shell with whatever page the pager actually settles on.
  ///
  /// Normally [onPageChanged] does this as the page changes, but a finger can
  /// interrupt a running tab animation, and then the pager may come to rest
  /// somewhere other than the tab the shell points at.
  void _settle(ScrollEndNotification notification) {
    _userScrolling = false;
    final settled = _controller.page?.round();
    if (settled != null && settled != widget.navigationShell.currentIndex) {
      _lastSwipedTo = settled;
      widget.navigationShell.goBranch(settled);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          // `dragDetails` is only set for real gestures; our own
          // animateToPage carries none, so its pages are never mistaken for
          // swipes.
          _userScrolling = notification.dragDetails != null;
        } else if (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) {
          _userScrolling = true;
        } else if (notification is ScrollEndNotification) {
          _settle(notification);
        }
        return false;
      },
      child: PageView(
        controller: _controller,
        onPageChanged: (index) {
          if (!_userScrolling) return;
          _lastSwipedTo = index;
          if (index != widget.navigationShell.currentIndex) {
            widget.navigationShell.goBranch(index);
          }
        },
        children: [
          for (final child in widget.children) _KeepAlivePage(child: child),
        ],
      ),
    );
  }
}

/// Keeps a visited tab in the tree so swiping away and back does not throw
/// away scroll position, search text or any other per-tab state — the same
/// trick `TabBarView` uses. Without this, [PageView] would dispose pages that
/// are more than one step away, where the old [IndexedStack] shell kept them.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
