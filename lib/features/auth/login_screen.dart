import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../l10n/l10n.dart';
import 'auth_notification_permission.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStateStatus.authenticated) {
        requestPostAuthNotificationPermissionAfterNavigation(context);
        context.go('/home');
      } else if (next.status == AuthStateStatus.needsProfileDetails) {
        // Signed in, but department/roll number/session are still missing.
        context.go('/auth/academic-details?role=${next.role ?? widget.role}');
      } else if (next.status == AuthStateStatus.needsRegistration) {
        context.go('/auth/register?role=${widget.role}');
      } else if (next.status == AuthStateStatus.needsVerification) {
        final phone = next.phone ?? _phoneController.text.trim();
        if (phone.isEmpty) return;
        context.pushReplacement(
          '/auth/otp?phone=$phone&role=${widget.role.toUpperCase()}',
        );
      } else if (next.status == AuthStateStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
      }
    });

    final roleTitle = widget.role == 'student'
        ? context.l10n.authStudentLogin
        : context.l10n.authTeacherLogin;

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
                slivers: [
                  _buildSliverAppBar(context, roleTitle),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.space24,
                        AppTheme.space24,
                        AppTheme.space24,
                        MediaQuery.of(context).viewInsets.bottom +
                            AppTheme.space24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppTheme.space24),
                            _buildHeaderIllustration(),
                            const SizedBox(height: AppTheme.space32),
                            Text(
                                  roleTitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              context.l10n.loginSubtitle,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppTheme.textSecondary),
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: AppTheme.space40),
                            _buildTextField(
                                  controller: _phoneController,
                                  label: context.l10n.fieldPhoneNumber,
                                  icon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return context.l10n.validationPhoneRequired;
                                    }
                                    if (!isValidBangladeshiPhone(v)) {
                                      return context.l10n.validationPhoneInvalid;
                                    }
                                    return null;
                                  },
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              context.l10n.hintExamplePhone,
                              style: const TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 12,
                              ),
                            ).animate().fadeIn(delay: 450.ms),
                            const SizedBox(height: AppTheme.space32),
                            _buildTextField(
                                  controller: _passwordController,
                                  label: context.l10n.fieldPassword,
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return context.l10n.validationPasswordRequired;
                                    }
                                    if (v.length < 8) {
                                      return context.l10n.validationPasswordLength8;
                                    }
                                    return null;
                                  },
                                )
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space32),
                            _buildLoginButton(authState),
                            const SizedBox(height: AppTheme.space12),
                            TextButton(
                              onPressed: () =>
                                  context.go('/auth/forgot-password'),
                              child: Text(
                                context.l10n.authForgotPassword,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().fadeIn(delay: 650.ms),
                            const SizedBox(height: AppTheme.space4),
                            TextButton(
                              onPressed: () => context.go(
                                '/auth/email-register?role=${widget.role}',
                              ),
                              child: Text.rich(
                                TextSpan(
                                  text: context.l10n.authNoAccount,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: context.l10n.authRegister,
                                      style: TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 700.ms),
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
        child: Icon(
          widget.role == 'student'
              ? Icons.school_rounded
              : Icons.psychology_rounded,
          size: 56,
          color: AppTheme.primaryBlue,
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLoginButton(AuthState authState) {
    final isLoading = authState.status == AuthStateStatus.loading;

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
        onPressed: isLoading ? null : _login,
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
            : Text(
                context.l10n.authLogin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: widget.role,
          );
    }
  }
}
