import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/result.dart';
import 'auth_provider.dart';

class EmailOtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String role;

  const EmailOtpVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  ConsumerState<EmailOtpVerificationScreen> createState() =>
      _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState
    extends ConsumerState<EmailOtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldown = 60;

  final List<TextEditingController> _boxes = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _countdownTimer;
  int _countdown = 0;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _boxes) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = _resendCooldown);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp => _boxes.map((c) => c.text).join();

  bool get _isComplete => _enteredOtp.length == _otpLength;

  void _handleDigitChanged(int index, String value) {
    // If multiple digits arrived (e.g. pasted), distribute across boxes.
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) {
      _onPaste(digits);
      return;
    }

    // Keep only digits, single char per box.
    _boxes[index].text = digits.isNotEmpty ? digits[digits.length - 1] : '';
    _boxes[index].selection =
        TextSelection.collapsed(offset: _boxes[index].text.length);

    setState(() => _error = null);

    if (digits.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when the last box is filled.
    if (_isComplete && _boxes[_otpLength - 1].text.isNotEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _onPaste(String fullText) async {
    final digits = fullText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    for (var i = 0; i < _otpLength; i++) {
      _boxes[i].text = i < digits.length ? digits[i] : '';
    }
    setState(() => _error = null);

    final target = digits.length >= _otpLength ? _otpLength - 1 : digits.length;
    _focusNodes[target].requestFocus();
  }

  Future<void> _verify() async {
    if (!_isComplete) {
      setState(() => _error = '৬ সংখ্যার কোডটি সম্পূর্ণ লিখুন।');
      return;
    }
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyOtp(
            email: widget.email,
            role: widget.role,
            otp: _enteredOtp,
          );

      if (!mounted) return;
      final state = ref.read(authProvider);
      if (state.status == AuthStateStatus.authenticated) {
        _clearOtp();
        // Replace the whole auth stack so back navigation cannot return to
        // registration/login or the OTP page after a successful verify.
        context.go('/home');
      } else {
        setState(() {
          _isVerifying = false;
          _error = state.error ?? 'ভেরিফিকেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = 'ভেরিফিকেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _error = null;
    });

    Result<String> result;
    try {
      result = await ref
          .read(authProvider.notifier)
          .resendOtp(email: widget.email, role: widget.role);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _error = 'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।';
      });
      return;
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data),
            backgroundColor: AppTheme.success,
          ),
        );
      case Failure(:final message):
        setState(() => _error = message);
      default:
        setState(() => _error = 'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।');
    }
  }

  void _clearOtp() {
    for (final c in _boxes) {
      c.clear();
    }
    for (final f in _focusNodes) {
      f.unfocus();
    }
  }

  void _goBackToRegistration() {
    _clearOtp();
    context.go('/auth/register?role=${widget.role.toLowerCase()}');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStateStatus.loading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackToRegistration();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          resizeToAvoidBottomInset: false,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space24,
                    AppTheme.space24,
                    AppTheme.space24,
                    MediaQuery.of(context).viewInsets.bottom + AppTheme.space48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.space12),
                      _buildHeaderIllustration(),
                      const SizedBox(height: AppTheme.space32),
                      Text(
                        'ইমেইল যাচাইকরণ',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'আমরা আপনার ইমেইলে ৬ সংখ্যার একটি verification code পাঠিয়েছি।',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, height: 1.5),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: AppTheme.space40),
                      _buildOtpBoxes(),
                      const SizedBox(height: AppTheme.space24),
                      if (_error != null) _buildErrorBanner(),
                      const SizedBox(height: AppTheme.space16),
                      _buildVerifyButton(isLoading),
                      const SizedBox(height: AppTheme.space24),
                      _buildResendSection(),
                      const SizedBox(height: AppTheme.space24),
                      _buildChangeEmailButton(),
                      const SizedBox(height: AppTheme.space48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: _goBackToRegistration,
      ),
      title: const Text('ইমেইল যাচাইকরণ',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
    );
  }

  Widget _buildHeaderIllustration() {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.mark_email_read_rounded,
            color: Colors.white, size: 38),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 48,
          height: 60,
          child: TextField(
            controller: _boxes[index],
            focusNode: _focusNodes[index],
            onChanged: (value) => _handleDigitChanged(index, value),
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: AppTheme.primaryBlue.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                  color: AppTheme.error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return Container(
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
        onPressed: (_isVerifying || isLoading) ? null : _verify,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        ),
        child: (_isVerifying || isLoading)
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('যাচাই করুন',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildResendSection() {
    final canResend = _countdown == 0 && !_isResending;

    return Column(
      children: [
        Text(
          'কোডটি পাননি?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.space8),
        if (_countdown > 0)
          Text(
            'আবার পাঠাতে $_countdown সেকেন্ড অপেক্ষা করুন',
            style: TextStyle(
              color: AppTheme.textHint,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          TextButton(
            onPressed: canResend ? _resend : null,
            child: _isResending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    'আবার কোড পাঠান',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildChangeEmailButton() {
    return TextButton.icon(
      onPressed: _goBackToRegistration,
      icon: const Icon(Icons.edit_outlined,
          size: 18, color: AppTheme.textSecondary),
      label: const Text(
        'ইমেইল পরিবর্তন / নিবন্ধনে ফিরে যান',
        style: TextStyle(
            color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
