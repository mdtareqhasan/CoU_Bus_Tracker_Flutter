import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class LiveIndicator extends StatelessWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          duration: 1000.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.5, 1.5),
        )
        .then()
        .scale(
          duration: 1000.ms,
          begin: const Offset(1.5, 1.5),
          end: const Offset(1, 1),
        );
  }
}
