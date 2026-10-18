import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

/// One tab in the animated bottom navigation. Holds an icon pair
/// (outlined + filled), a label, and derives the active style from the
/// parent. Kept simple and tagged for animation.
class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Custom animated bottom navigation. Replaces the default Material
/// `BottomNavigationBar` with an active pill indicator, a smooth
/// icon morph between outlined/filled, and a glow under the active item.
class AnimatedBottomNav extends StatefulWidget {
  const AnimatedBottomNav({
    super.key,
    required this.routes,
    required this.currentIndex,
    required this.onTap,
    this.height = 70,
  });

  final List<_NavTab> routes;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav> {
  int _pressedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final inactiveColor = isDark ? Colors.white38 : AppTheme.textHint;
    final activeColor = isDark ? AppTheme.cyanBright : AppTheme.bluePrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : AppTheme.textHint.withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / widget.routes.length;
              return Stack(
                children: [
                  // Animated pill indicator (slides behind the active item)
                  AnimatedPositioned(
                    duration: Motion.durMed,
                    curve: Motion.enter,
                    left: tabWidth * widget.currentIndex +
                        tabWidth * 0.18,
                    top: 8,
                    bottom: 14,
                    width: tabWidth * 0.64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                    ),
                  ),
                  Row(
                    children: widget.routes.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      final isActive = i == widget.currentIndex;
                      final isPressed = i == _pressedIndex;
                      return _NavItem(
                        label: r.label,
                        icon: r.icon,
                        activeIcon: r.activeIcon,
                        active: isActive,
                        pressed: isPressed,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTapDown: () => setState(() => _pressedIndex = i),
                        onTapCancel: () =>
                            setState(() => _pressedIndex = -1),
                        onTap: () {
                          setState(() => _pressedIndex = -1);
                          widget.onTap(i);
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.pressed,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final bool pressed;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: label + (active ? ', selected' : ''),
        selected: active,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onTapDown: (_) => onTapDown(),
            onTapCancel: onTapCancel,
            onTapUp: (_) => onTapCancel(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: Motion.durFast,
                    curve: Motion.press,
                    scale: pressed ? Motion.navPress : 1.0,
                    child: AnimatedSwitcher(
                      duration: Motion.durMed,
                      switchInCurve: Motion.bounce,
                      switchOutCurve: Motion.exit,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        active ? activeIcon : icon,
                        key: ValueKey<bool>(active),
                        size: 24,
                        color: active ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: Motion.durMed,
                    curve: Motion.enter,
                    style: TextStyle(
                      color: active ? activeColor : inactiveColor,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Public helper — wraps the AnimatedBottomNav with the canonical tab
// definitions used across the app.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = <_NavTab>[
    _NavTab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavTab(label: 'Buses', icon: Icons.directions_bus_outlined, activeIcon: Icons.directions_bus_rounded),
    _NavTab(label: 'Schedules', icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded),
    _NavTab(label: 'Notices', icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded),
    _NavTab(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNav(
      routes: _tabs,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
