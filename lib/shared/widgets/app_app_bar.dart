import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Sliver-friendly app bar with an aurora gradient background, optional
/// leading icon (defaulting to a back arrow), optional title/subtitle,
/// optional trailing action (a list of widget actions), and a subtle
/// glass overlay sheen. Replaces every hand-rolled `SliverAppBar` in the
/// app with one consistent primitive.
class AppAppBar extends StatelessWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.onLeadingPressed,
    this.actions = const <Widget>[],
    this.height = 140,
    this.pinned = true,
    this.expanded = true,
    this.showGlow = true,
  });

  final String? title;
  final String? subtitle;
  final IconData? leading;
  final VoidCallback? onLeadingPressed;
  final List<Widget> actions;
  final double height;
  final bool pinned;
  final bool expanded;
  final bool showGlow;

  /// Wraps this bar in a `SliverAppBar` so it stays pinned during
  /// scroll. Use this in `CustomScrollView`s — but in practice the widget
  /// is a `Widget` already, just put it in a `SliverAppBar`-shaped host
  /// from your screen.
  SliverAppBar toSliver(BuildContext context) => _sliver(context);

  @override
  Widget build(BuildContext context) => _sliver(context);

  SliverAppBar _sliver(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      expandedHeight: expanded ? height : kToolbarHeight,
      backgroundColor: AppTheme.blueVivid,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leading: leading == null
          ? null
          : IconButton(
              icon: Icon(leading, color: Colors.white, size: 22),
              onPressed: onLeadingPressed ?? () => Navigator.of(context).maybePop(),
            ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: AppTheme.space24,
          end: AppTheme.space24,
          bottom: AppTheme.space16,
        ),
        title: _buildTitle(context),
        background: _Background(showGlow: showGlow),
      ),
      actions: actions,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    if (title == null && subtitle == null) return null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.showGlow});
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
        ),
        if (showGlow)
          Positioned(
            top: -40,
            right: -30,
            child: _GlowBlob(
              size: 200,
              color: AppTheme.cyanBright.withValues(alpha: 0.30),
            ),
          ),
        if (showGlow)
          Positioned(
            bottom: -50,
            left: -40,
            child: _GlowBlob(
              size: 220,
              color: AppTheme.indigoDeep.withValues(alpha: 0.45),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
