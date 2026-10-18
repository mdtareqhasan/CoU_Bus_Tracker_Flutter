import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app/theme.dart';
import '../../core/error_handler.dart';
import '../../core/services/google_signin_service.dart';
import '../../l10n/l10n.dart';
import 'auth_notification_permission.dart';
import 'auth_provider.dart';
import '../../shared/widgets/app_bar_language_switcher.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';
import '../../shared/widgets/primary_button.dart';

/// Google Sign-In entry screen.
///
/// The user signs in with their institutional Google account
/// (`name@cou.ac.bd` / `name@stud.cou.ac.bd`); the ID token returned by Google
/// is sent to the backend for verification. The existing email/SMS sign-in and
/// sign-up routes are kept and remain reachable directly.
class GoogleSigninScreen extends ConsumerStatefulWidget {
  final String role;
  const GoogleSigninScreen({super.key, required this.role});

  @override
  ConsumerState<GoogleSigninScreen> createState() => _GoogleSigninScreenState();
}

class _GoogleSigninScreenState extends ConsumerState<GoogleSigninScreen> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStateStatus.authenticated) {
        requestPostAuthNotificationPermissionAfterNavigation(context);
        context.go('/home');
      } else if (next.status == AuthStateStatus.needsProfileDetails) {
        context.go('/auth/academic-details?role=${next.role ?? widget.role}');
      } else if (next.status == AuthStateStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
      }
    });

    final roleTitle = widget.role == 'student'
        ? context.l10n.authStudentLogin
        : context.l10n.authTeacherOfficerLogin;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/auth/role');
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.bgLight,
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: AppTheme.bgLight,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(roleTitle),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space24,
                        AppTheme.space24,
                        AppTheme.space24,
                        AppTheme.space48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AppBarLanguageSwitcher(),
                          ),
                          const SizedBox(height: AppTheme.space24),
                          Text(
                            roleTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            context.l10n.googleSignInSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: AppTheme.space24),
                          _buildInfoCard()
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space24),
                          PrimaryButton(
                            label: context.l10n.googleSignInButton,
                            icon: Icons.login_rounded,
                            isLoading: _isSigningIn ||
                                authState.status == AuthStateStatus.loading,
                            onPressed: _signInWithGoogle,
                          ).animate().fadeIn(delay: 500.ms).slideY(
                                begin: 0.15,
                                end: 0,
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.blueVivid,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.go('/auth/role'),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      elevation: GlassCardElevation.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGmailReminderCard(),
          const SizedBox(height: AppTheme.space16),
          Text(
            context.l10n.googleEmailFormatLabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: widget.role == 'student'
                ? [
                    _buildFormatChip('example@stud.cou.ac.bd'),
                    _buildFormatChip('example@cou.ac.bd'),
                  ]
                : [_buildFormatChip('example@cou.ac.bd')],
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    context.l10n.googleIctHelp,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGmailReminderCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.bluePrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: AppTheme.bluePrimary.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 18,
            color: AppTheme.bluePrimary,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.googleGmailReminderTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.bluePrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  context.l10n.googleGmailReminderMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String value) {
    return AppPill(
      label: value,
      icon: Icons.alternate_email_rounded,
      color: AppTheme.bluePrimary,
      dense: true,
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      final idToken = await GoogleSignInService.instance.signIn();
      if (idToken == null || !mounted) return;

      await ref
          .read(authProvider.notifier)
          .loginWithGoogle(idToken: idToken, role: widget.role);
    } on GoogleSignInException catch (e) {
      if (mounted) _showError(_googleErrorMessage(e));
    } catch (_) {
      if (mounted) _showError(ErrorHandler.defaultError);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  String _googleErrorMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return context.l10n.googleSignInCancelled;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return context.l10n.googleSignInConfigError;
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return ErrorHandler.defaultError;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }
}