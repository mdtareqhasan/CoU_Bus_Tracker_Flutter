import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/app_bar_language_switcher.dart';
import '../../shared/widgets/glass_card.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space12,
                    AppTheme.space16,
                    AppTheme.space16,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          context.l10n.roleSelectTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1, end: 0),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radius2XL),
                        topRight: Radius.circular(AppTheme.radius2XL),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.space24),
                      child: Column(
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AppBarLanguageSwitcher(),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          _buildIllustration(),
                          const SizedBox(height: AppTheme.space24),
                          Text(
                            context.l10n.roleChoosePrompt,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(
                                begin: 0.15,
                                end: 0,
                              ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            context.l10n.roleLoginRegisterHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: AppTheme.space32),
                          AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 360),
                                childAnimationBuilder: (widget) => SlideAnimation(
                                  verticalOffset: 18,
                                  child: FadeInAnimation(child: widget),
                                ),
                                children: [
                                  _buildRoleCard(
                                    context,
                                    icon: Icons.school_rounded,
                                    label: context.l10n.roleStudent,
                                    subtitle: context.l10n.roleStudentSubtitle,
                                    accent: AppTheme.catBlue,
                                    onTap: () => context.go(
                                      '/auth/google-signin?role=student',
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space12),
                                  _buildRoleCard(
                                    context,
                                    icon: Icons.psychology_rounded,
                                    label: context.l10n.roleTeacher,
                                    subtitle: context.l10n.roleTeacherSubtitle,
                                    accent: AppTheme.catTeacher,
                                    onTap: () => context.go(
                                      '/auth/google-signin?role=teacher',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.blueVivid.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.10, 1.10),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.indigoDeep,
                  AppTheme.blueVivid,
                  AppTheme.cyanBright,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      elevation: GlassCardElevation.soft,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
