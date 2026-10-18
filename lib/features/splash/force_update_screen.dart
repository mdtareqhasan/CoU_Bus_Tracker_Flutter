import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/glass_card.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String message;
  final String playStoreUrl;
  final bool forceUpdate;
  final VoidCallback? onSkip;

  const ForceUpdateScreen({
    super.key,
    required this.message,
    required this.playStoreUrl,
    required this.forceUpdate,
    this.onSkip,
  });

  Future<void> _launchStore() async {
    final uri = Uri.parse(playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !forceUpdate) {
          onSkip?.call();
        }
      },
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
                            Icons.system_update_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            )
                            .then()
                            .shimmer(
                              duration: 2400.ms,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                        const SizedBox(height: AppTheme.space24),
                        Text(
                          forceUpdate
                              ? context.l10n.forceUpdateTitle
                              : context.l10n.newVersionTitle,
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
                              : context.l10n.newVersionBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: AppTheme.space24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _launchStore,
                            icon: const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              context.l10n.updateNow,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.blueVivid,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMD),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(
                              begin: 0.15,
                              end: 0,
                            ),
                        if (!forceUpdate) ...[
                          const SizedBox(height: AppTheme.space12),
                          TextButton(
                            onPressed: onSkip,
                            child: Text(
                              context.l10n.updateLater,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),
                        ],
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
