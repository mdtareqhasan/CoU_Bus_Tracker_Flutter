import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Destructive action button (logout, delete, exit). Outlined red.
class DangerButton extends StatefulWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.logout_rounded,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final double height;

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.durFast,
      curve: Motion.press,
      height: widget.height,
      width: double.infinity,
      transform: Matrix4.identity()..scale(_down ? Motion.cardPress : 1.0),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4), width: 1.4),
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
                Icon(widget.icon, color: AppTheme.error, size: 18),
                const SizedBox(width: AppTheme.space8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppTheme.error,
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
