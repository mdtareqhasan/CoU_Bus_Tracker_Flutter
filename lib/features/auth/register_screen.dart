import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../app/theme.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const int _maxUploadBytes = 300 * 1024; // 300 KB target
  static const Set<String> _allowedImageMimes = {
    'image/jpeg',
    'image/png',
  };

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _batchController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _idCardImage;
  final ImagePicker _picker = ImagePicker();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _teacherIdController.dispose();
    _departmentController.dispose();
    _batchController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (image == null) return;

    final file = File(image.path);
    final mime = lookupMimeType(file.path);

    if (mime == null || !_allowedImageMimes.contains(mime)) {
      _showError('শুধুমাত্র JPG, JPEG বা PNG ছবি নির্বাচন করুন।');
      return;
    }

    final originalSize = await file.length();
    debugPrint('Picked image size: $originalSize');

    final compressed = await _compressImage(file);
    if (!mounted) return;
    setState(() {
      _idCardImage = compressed;
    });
  }

  Future<File> _compressImage(File original) async {
    final originalSize = await original.length();
    if (originalSize <= _maxUploadBytes) return original;

    final isPng = lookupMimeType(original.path) == 'image/png';
    final dir = original.parent.path;
    final ext = isPng ? 'png' : 'jpg';

    var minWidth = 1400;
    var minHeight = 1400;
    var quality = 80;

    for (var attempt = 0; attempt < 10; attempt++) {
      final target = '$dir/idcard_compressed_$attempt.$ext';
      final bytes = await FlutterImageCompress.compressWithFile(
        original.path,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: isPng ? CompressFormat.png : CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );
      if (bytes == null) break;

      final compressed = File(target);
      await compressed.writeAsBytes(bytes, flush: true);
      final size = await compressed.length();
      debugPrint('Compress attempt $attempt ($ext, ${minWidth}x$minHeight, '
          'q$quality): $size');

      if (size <= _maxUploadBytes) return compressed;

      if (isPng) {
        // PNG is lossless; only the dimensions shrink the size.
        minWidth = (minWidth * 0.7).round();
        minHeight = (minHeight * 0.7).round();
      } else {
        quality = (quality * 0.75).round();
        minWidth = (minWidth * 0.85).round();
        minHeight = (minHeight * 0.85).round();
      }
    }

    // Fall back to the smallest attempt if still oversized, otherwise original.
    final fallback = File('$dir/idcard_compressed_9.$ext');
    if (await fallback.exists()) return fallback;
    return original;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStateStatus.authenticated) {
        context.go('/home');
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

    final roleTitle =
        widget.role == 'student' ? 'শিক্ষার্থী নিবন্ধন' : 'শিক্ষক নিবন্ধন';

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
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, roleTitle),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
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
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          const Text(
                            'আপনার পরিচয় নিশ্চিত করতে আইডি কার্ড আপলোড করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: AppTheme.space32),
                          _buildIdCardPicker(),
                          const SizedBox(height: AppTheme.space32),
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
                            label: 'ইমেইল',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'ইমেইল দিন';
                              if (!v.contains('@')) return 'সঠিক ইমেইল দিন';
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 8),
                          _buildEduMailInfo(),
                          const SizedBox(height: 12),
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
                                  color: AppTheme.textHint),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'পাসওয়ার্ড দিন';
                              if (v.length < 8) return 'কমপক্ষে ৮ অক্ষর দিন';
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideX(begin: 0.1, end: 0),
                          if (widget.role == 'student') ...[
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _studentIdController,
                              label: 'শিক্ষার্থী আইডি',
                              icon: Icons.badge_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'আইডি দিন' : null,
                            )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _departmentController,
                              label: 'বিভাগ',
                              icon: Icons.business_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'বিভাগ দিন' : null,
                            )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _batchController,
                              label: 'ব্যাচ',
                              icon: Icons.class_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'ব্যাচ দিন' : null,
                            )
                                .animate()
                                .fadeIn(delay: 800.ms)
                                .slideX(begin: 0.1, end: 0),
                          ],
                          if (widget.role == 'teacher') ...[
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _teacherIdController,
                              label: 'শিক্ষক আইডি',
                              icon: Icons.badge_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'আইডি দিন' : null,
                            )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _departmentController,
                              label: 'বিভাগ',
                              icon: Icons.business_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'বিভাগ দিন' : null,
                            )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _designationController,
                              label: 'পদবী',
                              icon: Icons.work_outline_rounded,
                            )
                                .animate()
                                .fadeIn(delay: 800.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'ফোন নাম্বার',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'ফোন নাম্বার দিন';
                                final cleaned =
                                    v.replaceAll(RegExp(r'[\s\-]'), '');
                                if (!RegExp(r'^01[3-9]\d{8}$')
                                    .hasMatch(cleaned))
                                  return 'সঠিক ১১ ডিজিটের বাংলাদেশি নাম্বার দিন';
                                return null;
                              },
                            )
                                .animate()
                                .fadeIn(delay: 900.ms)
                                .slideX(begin: 0.1, end: 0),
                          ],
                          const SizedBox(height: AppTheme.space32),
                          _buildRegisterButton(authState),
                          const SizedBox(height: AppTheme.space16),
                          TextButton(
                            onPressed: () =>
                                context.go('/auth/login?role=${widget.role}'),
                            child: Text.rich(
                              TextSpan(
                                text: 'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'লগইন করুন',
                                    style: TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 1100.ms),
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

  Widget _buildEduMailInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'এডু ইমেইল ব্যবহার করুন',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'বিশ্ববিদ্যালয়ের ইমেইল (edu mail) থাকলে সেটি ব্যবহার করুন। না থাকলে ব্যক্তিগত ইমেইলও ব্যবহার করতে পারবেন।',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildIdCardPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('বিশ্ববিদ্যালয় আইডি কার্ডের ছবি (MANDATORY)',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: _idCardImage == null
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.successGreen,
                width: 2,
                style: _idCardImage == null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: _idCardImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge - 2),
                        child: Image.file(_idCardImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      )
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 48,
                          color: AppTheme.primaryBlue.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('আইডি কার্ডের ছবি সিলেক্ট করুন',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      if (_idCardImage == null)
                        const Text(
                            '(JPG/PNG — আপলোডের আগে ৩০০ KB-এ অটো কমপ্রেস হবে)',
                            style: TextStyle(
                                color: AppTheme.textHint, fontSize: 11)),
                      if (_idCardImage != null)
                        FutureBuilder<int>(
                          future: _idCardImage!.length(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final kb = snapshot.data! / 1024;
                              final mb = snapshot.data! / (1024 * 1024);
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  mb >= 1
                                      ? 'ছবির সাইজ: ${mb.toStringAsFixed(2)} MB'
                                      : 'ছবির সাইজ: ${kb.toStringAsFixed(0)} KB',
                                  style: const TextStyle(
                                      color: AppTheme.successGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => context.go('/auth/role'),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
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
          widget.role == 'student'
              ? Icons.school_rounded
              : Icons.psychology_rounded,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
          color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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

  Widget _buildRegisterButton(AuthState authState) {
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
        onPressed: isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('নিবন্ধন করুন',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _register() {
    if (_idCardImage == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('আইডি কার্ড প্রয়োজন'),
          content: const Text(
              'নিবন্ধন সম্পন্ন করতে আপনার বিশ্ববিদ্যালয় আইডি কার্ডের ছবি আপলোড করা বাধ্যতামূলক।'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ঠিক আছে')),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (widget.role == 'student') {
        ref.read(authProvider.notifier).studentRegister(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              studentId: _studentIdController.text.trim(),
              department: _departmentController.text.trim(),
              varsityBatch: _batchController.text.trim(),
              idCard: _idCardImage!,
            );
      } else {
        ref.read(authProvider.notifier).teacherRegister(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              teacherId: _teacherIdController.text.trim(),
              department: _departmentController.text.trim(),
              designation: _designationController.text.trim(),
              phone: _phoneController.text.trim(),
              idCard: _idCardImage!,
            );
      }
    }
  }
}
