import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Outlined/tonal secondary button.
class GhostButton extends StatefulWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppTheme.bluePrimary,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = enabled ? widget.color : AppTheme.textHint;

    return AnimatedContainer(
      duration: Motion.durFast,
      curve: Motion.press,
      height: widget.height,
      width: double.infinity,
      transform: Matrix4.identity()..scale(_down ? Motion.cardPress : 1.0),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: widget.color.withValues(alpha: enabled ? 0.40 : 0.18),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 18),
                  const SizedBox(width: AppTheme.space8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
