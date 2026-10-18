import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

/// Primary action button. Gradient-filled with aurora glow, press-scale
/// animation, and a built-in loading state.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.isLoading = false,
    this.height = 56,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final bool isLoading;
  final double height;
  final bool fullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppTheme.auroraHeaderGradient;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final btn = AnimatedContainer(
      duration: Motion.durFast,
      curve: Motion.press,
      height: widget.height,
      width: widget.fullWidth ? double.infinity : null,
      transform: Matrix4.identity()..scale(_down ? Motion.cardPress : 1.0),
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppTheme.textHint.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: enabled ? AppTheme.auroraGlow : const <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: AppTheme.space12),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return btn;
  }
}
