import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import 'auth_provider.dart';
import 'department_options.dart';
import 'session_options.dart';

class EmailRegistrationScreen extends ConsumerStatefulWidget {
  final String role;
  const EmailRegistrationScreen({super.key, required this.role});

  @override
  ConsumerState<EmailRegistrationScreen> createState() =>
      _EmailRegistrationScreenState();
}

class _EmailRegistrationScreenState
    extends ConsumerState<EmailRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _sessionController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSession;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get isStudent => widget.role == 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _rollNumberController.dispose();
    _sessionController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .initEmailRegistration(
          role: widget.role,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          department: _departmentController.text.trim(),
          rollNumber: isStudent ? _rollNumberController.text.trim() : null,
          session: isStudent
              ? sessionValueByLabel[_sessionController.text.trim()] ??
                    _sessionController.text.trim()
              : null,
          employeeId: isStudent ? null : _employeeIdController.text.trim(),
          designation: isStudent ? null : _designationController.text.trim(),
        );

    if (!mounted) return;
    final state = ref.read(authProvider);
    setState(() => _isLoading = false);

    if (state.status == AuthStateStatus.needsVerification) {
      context.go(
        '/auth/email-otp?email=${Uri.encodeComponent(_emailController.text.trim())}&role=${widget.role}',
      );
      return;
    }

    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = isStudent
        ? 'শিক্ষার্থী নিবন্ধন'
        : 'শিক্ষক ও কর্মকর্তাবৃন্দ নিবন্ধন';

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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, roleTitle),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.space24,
                      AppTheme.space24,
                      AppTheme.space24,
                      MediaQuery.of(context).viewInsets.bottom +
                          AppTheme.space48,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.space12),
                          _buildHeaderIllustration(),
                          const SizedBox(height: AppTheme.space24),
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
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            isStudent
                                ? 'আপনার এডুমেইলের মাধ্যমে OTP নিবন্ধন করুন'
                                : 'আপনার প্রতিষ্ঠানিক ইমেইলের মাধ্যমে OTP নিবন্ধন করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: AppTheme.space24),
                          _buildTextField(
                                controller: _nameController,
                                label: 'পুরো নাম',
                                icon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'নাম দিন' : null,
                              )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space12),
                          _buildTextField(
                                controller: _emailController,
                                label: isStudent
                                    ? 'এডুমেইল'
                                    : 'প্রতিষ্ঠানিক ইমেইল',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'ইমেইল দিন';
                                  return RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      ).hasMatch(v)
                                      ? null
                                      : 'সঠিক ইমেইল দিন';
                                },
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            isStudent
                                ? 'যদি আপনার এডুমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন'
                                : 'যদি আপনার প্রতিষ্ঠানিক ইমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ).animate().fadeIn(delay: 450.ms),
                          const SizedBox(height: AppTheme.space12),
                          DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: (widget.role == 'student')
                                      ? 'বিভাগ'
                                      : 'বিভাগ/অফিস',
                                  prefixIcon: Icon(
                                    Icons.business_outlined,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                hint: Text(
                                  (widget.role == 'student')
                                      ? 'বিভাগ নির্বাচন করুন'
                                      : 'বিভাগ/অফিস নির্বাচন করুন',
                                ),
                                value: _selectedDepartment,
                                items:
                                    (isStudent
                                            ? departmentOptions
                                            : teacherDepartmentOptions)
                                        .map(
                                          (department) =>
                                              DropdownMenuItem<String>(
                                                value: department,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width -
                                                        100,
                                                  ),
                                                  child: Text(
                                                    department,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                    _departmentController.text = value ?? '';
                                  });
                                },
                                validator: (v) =>
                                    v == null ? 'বিভাগ দিন' : null,
                              )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space12),
                          if (isStudent) ...[
                            _buildTextField(
                                  controller: _rollNumberController,
                                  label: 'রোল নম্বর',
                                  icon: Icons.badge_outlined,
                                  hint: 'যেমন: 12208055',
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'রোল নম্বর দিন'
                                      : null,
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'সেশন',
                                    prefixIcon: Icon(
                                      Icons.class_outlined,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  hint: const Text('সেশন নির্বাচন করুন'),
                                  value: _selectedSession,
                                  items: sessionOptions
                                      .map(
                                        (session) => DropdownMenuItem<String>(
                                          value: session,
                                          child: Text(session),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSession = value;
                                      _sessionController.text = value ?? '';
                                    });
                                  },
                                  validator: (v) =>
                                      v == null ? 'সেশন দিন' : null,
                                )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.1, end: 0),
                          ] else ...[
                            _buildTextField(
                                  controller: _employeeIdController,
                                  label: 'আইডি',
                                  icon: Icons.badge_outlined,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'আইডি দিন'
                                      : null,
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                                  controller: _designationController,
                                  label: 'পদবী',
                                  icon: Icons.work_outline_rounded,
                                )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.1, end: 0),
                          ],
                          const SizedBox(height: AppTheme.space32),
                          _buildTextField(
                                controller: _passwordController,
                                label: 'পাসওয়ার্ড',
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
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'পাসওয়ার্ড দিন';
                                  if (v.length < 8)
                                    return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 800.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space12),
                          _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'পাসওয়ার্ড আবার দিন',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'পাসওয়ার্ড আবার দিন';
                                  if (v != _passwordController.text)
                                    return 'পাসওয়ার্ড মিলছে না';
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 900.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space32),
                          _buildRegisterButton(),
                          const SizedBox(height: AppTheme.space16),
                          TextButton(
                            onPressed: () =>
                                context.go('/auth/email-login?role=${widget.role}'),
                            child: Text.rich(
                              TextSpan(
                                text: 'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'লগইন করুন',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                          const SizedBox(height: AppTheme.space48),
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isStudent ? Icons.school_rounded : Icons.psychology_rounded,
          size: 44,
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
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
      ),
      validator: validator,
    );
  }

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'নিবন্ধন করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
