import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStateStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStateStatus.needsRegistration) {
        context.go('/auth/register?role=${widget.role}');
      } else if (next.status == AuthStateStatus.needsVerification) {
        context.pushReplacement(
          '/auth/otp?email=${next.email ?? _emailController.text.trim()}&role=${widget.role.toUpperCase()}',
        );
      } else if (next.status == AuthStateStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
      }
    });

    final roleTitle = widget.role == 'student'
        ? 'শিক্ষার্থী লগইন'
        : 'শিক্ষক লগইন';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/auth/role');
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Container(
            height: double.infinity,
            width: double.infinity,
            color: AppTheme.backgroundLight,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, roleTitle),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
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
                            'আপনার অ্যাকাউন্টে লগইন করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: AppTheme.space40),
                          _buildTextField(
                                controller: _emailController,
                                label: 'ইমেইল',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'ইমেইল দিন';
                                  if (!v.contains('@')) return 'সঠিক ইমেইল দিন';
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space16),
                          _buildTextField(
                                controller: _passwordController,
                                label: 'পাসওয়ার্ড',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textHint,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'পাসওয়ার্ড দিন';
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space32),
                          _buildLoginButton(authState),
                          const SizedBox(height: AppTheme.space16),
                          TextButton(
                            onPressed: () => context.go(
                              '/auth/register?role=${widget.role}',
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: 'অ্যাকাউন্ট নেই? ',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'নিবন্ধন করুন',
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
        color: AppTheme.primaryBlue.withOpacity(0.1),
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
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
          borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.1)),
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
            color: AppTheme.primaryBlue.withOpacity(0.3),
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
            : const Text(
                'লগইন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: widget.role,
          );
    }
  }
}
