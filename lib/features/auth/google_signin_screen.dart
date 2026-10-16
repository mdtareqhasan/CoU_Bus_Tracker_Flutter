import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app/theme.dart';
import '../../core/error_handler.dart';
import '../../core/services/google_signin_service.dart';
import 'auth_notification_permission.dart';
import 'auth_provider.dart';

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
      } else if (next.status == AuthStateStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
      }
    });

    final roleTitle = widget.role == 'student'
        ? 'শিক্ষার্থী লগইন'
        : 'শিক্ষক ও কর্মকর্তাবৃন্দ লগইন';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/auth/role');
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: AppTheme.backgroundLight,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(context, roleTitle),
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
                          const SizedBox(height: AppTheme.space24),
                          _buildHeaderIllustration(),
                          const SizedBox(height: AppTheme.space32),
                          Text(
                                roleTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          const Text(
                            'বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্ট দিয়ে প্রবেশ করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: AppTheme.space32),
                          _buildInfoCard()
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space32),
                          _buildGoogleButton(authState)
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .scale(begin: const Offset(0.95, 0.95)),
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

  Widget _buildSliverAppBar(BuildContext context, String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
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
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
    );
  }

  Widget _buildHeaderIllustration() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আপনার বিশ্ববিদ্যালয়ের প্রাতিষ্ঠানিক ইমেইল ব্যবহার করে প্রবেশ করুন।',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          const Text(
            'প্রয়োজনীয় ইমেইল ফরমেট:',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              _buildFormatChip('name@cou.ac.bd'),
              const Text(
                'অথবা',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildFormatChip('name@stud.cou.ac.bd'),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
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
                    'আপনার প্রাতিষ্ঠানিক ইমেইল না থাকলে অনুগ্রহ করে বিশ্ববিদ্যালয়ের আইসিটি সেলের সঙ্গে যোগাযোগ করুন।',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.textSecondary.withValues(alpha: 0.95),
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

  Widget _buildFormatChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthState authState) {
    final isLoading =
        _isSigningIn || authState.status == AuthStateStatus.loading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'গুগল অ্যাকাউন্ট দিয়ে প্রবেশ করুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      final idToken = await GoogleSignInService.instance.signIn();

      // null means the user dismissed the account picker — nothing to do.
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
        return 'প্রবেশ বাতিল করা হয়েছে।';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'গুগল সাইন-ইন কনফিগারেশনে সমস্যা হয়েছে। যোগাযোগ করুন।';
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
