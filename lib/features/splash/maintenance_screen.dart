import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/glass_card.dart';

class MaintenanceScreen extends StatelessWidget {
  final String message;

  const MaintenanceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.blueVivid,
          body: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
              ),
              Positioned(
                top: -60,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppTheme.cyanBright.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: AppTheme.indigoDeep.withValues(alpha: 0.50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    elevation: GlassCardElevation.large,
                    backgroundColor: Colors.white.withValues(alpha: 0.96),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.indigoDeep,
                                AppTheme.blueVivid,
                                AppTheme.cyanBright,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: AppTheme.auroraGlow,
                          ),
                          child: const Icon(
                            Icons.build_circle_outlined,
                            size: 44,
                            color: Colors.white,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.06, 1.06),
                              duration: 1400.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(height: AppTheme.space24),
                        Text(
                          context.l10n.maintenanceTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(
                              begin: 0.15,
                              end: 0,
                            ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          message.isNotEmpty
                              ? message
                              : context.l10n.maintenanceBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
