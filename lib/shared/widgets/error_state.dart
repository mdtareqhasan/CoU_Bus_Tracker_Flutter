import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import 'empty_state.dart';

/// Error state — used in place of `EmptyState` when a list failed to load.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.error_outline_rounded,
    this.ctaLabel,
    this.onCtaPressed,
  });

  final String title;
  final String? body;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      body: body,
      icon: icon,
      iconColor: AppTheme.error,
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
    ).animate().fadeIn(duration: 300.ms);
  }
}
