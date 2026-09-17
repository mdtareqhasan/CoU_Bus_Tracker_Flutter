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
import '../../core/utils/phone_utils.dart';
import '../../core/services/id_card_validation_service.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const int _maxUploadBytes = 300 * 1024; // 300 KB target
  static const Set<String> _allowedImageMimes = {'image/jpeg', 'image/png'};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _sessionController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _idCardImage;
  final ImagePicker _picker = ImagePicker();
  bool _isValidatingIdCard = false;
  String? _idCardValidationMessage;
  bool? _isIdCardValid;
  int _imageKey = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    _teacherIdController.dispose();
    _departmentController.dispose();
    _sessionController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      _isValidatingIdCard = true;
      _idCardValidationMessage = null;
      _isIdCardValid = null;
      _imageKey++; // Force image widget to rebuild
    });

    // Validate with ML Kit for both students and teachers
    await _validateIdCard(compressed);
  }

  Future<void> _validateIdCard(File imageFile) async {
    try {
      final result = await IdCardValidationService.validateIdCard(imageFile, role: widget.role);

      if (!mounted) return;

      String message;
      if (result.documentType == 'teacher_id_card') {
        message = '✅ শিক্ষক আইডি কার্ড সনাক্ত হয়েছে';
      } else if (result.documentType == 'id_card') {
        message = '✅ আইডি কার্ড সনাক্ত হয়েছে';
      } else {
        message = '✅ ছবি আপলোড হয়েছে';
      }

      setState(() {
        _isValidatingIdCard = false;
        _isIdCardValid = result.isValid;
        _idCardValidationMessage = message;
      });

      // Auto-fill fields if valid
      if (result.isValid) {
        if (result.extractedRollNumber != null && _rollNumberController.text.isEmpty) {
          _rollNumberController.text = result.extractedRollNumber!;
        }
        if (result.extractedSession != null && _sessionController.text.isEmpty) {
          _sessionController.text = result.extractedSession!;
        }
        if (result.extractedDepartment != null && _departmentController.text.isEmpty) {
          _departmentController.text = result.extractedDepartment!;
        }
        if (result.extractedDesignation != null && _designationController.text.isEmpty) {
          _designationController.text = result.extractedDesignation!;
        }
        if (result.extractedEmployeeId != null && _teacherIdController.text.isEmpty) {
          _teacherIdController.text = result.extractedEmployeeId!;
        }

        if (result.extractedRollNumber != null ||
            result.extractedSession != null ||
            result.extractedDepartment != null ||
            result.extractedDesignation != null ||
            result.extractedEmployeeId != null) {
          _showSuccess('তথ্য স্বয়ংক্রিয়ভাবে পূরণ হয়েছে। পরীক্ষা করে নিন।');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidatingIdCard = false;
        _isIdCardValid = null;
        _idCardValidationMessage = 'ছবি যাচাইয়ে সমস্যা হয়েছে।';
      });
    }
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
      debugPrint(
        'Compress attempt $attempt ($ext, ${minWidth}x$minHeight, '
        'q$quality): $size',
      );

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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStateStatus.authenticated) {
        context.go('/home');
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
        ? 'শিক্ষার্থী নিবন্ধন'
        : 'শিক্ষক নিবন্ধন';

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
                        MediaQuery.of(context).viewInsets.bottom + AppTheme.space48,
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
                          const Text(
                            'আইডি কার্ড অথবা ভর্তির ফর্ম আপলোড করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: AppTheme.space24),
                          _buildDocumentPicker(),
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
                                controller: _phoneController,
                                label: 'ফোন নম্বর',
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'ফোন নম্বর দিন';
                                  if (!isValidBangladeshiPhone(v))
                                    return 'সঠিক ফোন নম্বর দিন (01XXXXXXXXX)';
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          const Text(
                            'নিবন্ধনের পর এই নম্বরে OTP পাঠানো হবে',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ).animate().fadeIn(delay: 550.ms),
                          if (widget.role == 'student') ...[
                            const SizedBox(height: AppTheme.space12),
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
                            _buildTextField(
                                  controller: _departmentController,
                                  label: 'বিভাগ',
                                  icon: Icons.business_outlined,
                                  hint: 'যেমন: CSE, EEE, BBA',
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'বিভাগ দিন'
                                      : null,
                                )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                                  controller: _sessionController,
                                  label: 'সেশন',
                                  icon: Icons.class_outlined,
                                  hint: 'যেমন: 2021-22',
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'সেশন দিন'
                                      : null,
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
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'আইডি দিন'
                                      : null,
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: AppTheme.space12),
                            _buildTextField(
                                  controller: _departmentController,
                                  label: 'বিভাগ',
                                  icon: Icons.business_outlined,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'বিভাগ দিন'
                                      : null,
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
                                  if (v == null || v.isEmpty) {
                                    return 'পাসওয়ার্ড দিন';
                                  }
                                  if (v.length < 8) {
                                    return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
                                  }
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 900.ms)
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
                                  if (v == null || v.isEmpty) {
                                    return 'পাসওয়ার্ড আবার দিন';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'পাসওয়ার্ড মিলছে না';
                                  }
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 1000.ms)
                              .slideX(begin: 0.1, end: 0),
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

  /// আইডি কার্ড না থাকলে ভর্তির ফর্ম দেওয়ার ব্যাখ্যা।
  Widget _buildDocumentNote() {
    final isStudent = widget.role == 'student';
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
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
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStudent
                      ? 'আইডি কার্ড বা ভর্তির ফর্ম — যেকোনো একটি দিন!'
                      : 'শিক্ষক আইডি কার্ড আপলোড করুন',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isStudent
                      ? '• আইডি কার্ড আছে → আইডি কার্ডের ছবি আপলোড করুন\n'
                          '• আইডি কার্ড নেই → ভর্তির ফর্ম / ভর্তি ভাউচারের ছবি আপলোড করুন\n'
                          '• উভয়ই কুমিল্লা বিশ্ববিদ্যালয়ের হতে হবে'
                      : '• শিক্ষক পরিচয়পত্রের ছবি আপলোড করুন\n'
                          '• কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড হতে হবে\n'
                          '• ডিপার্টমেন্ট ও পদবি স্বয়ংক্রিয়ভাবে পূরণ হবে',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.5,
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

  Widget _buildDocumentPicker() {
    final isStudent = widget.role == 'student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStudent ? 'পরিচয়পত্র / ভর্তির ফর্মের ছবি (MANDATORY)' : 'শিক্ষক পরিচয়পত্রের ছবি (MANDATORY)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
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
              ),
            ),
            child: _idCardImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge - 2,
                        ),
                        child: Image.file(
                          _idCardImage!,
                          key: ValueKey(_imageKey),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
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
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 48,
                        color: AppTheme.primaryBlue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ছবি সিলেক্ট করুন',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (_idCardImage == null)
                        Text(
                          isStudent
                              ? '(JPG/PNG — আইডি কার্ড অথবা ভর্তির ফর্ম)'
                              : '(JPG/PNG — শিক্ষক আইডি কার্ড)',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 11,
                          ),
                        ),
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
                                    fontWeight: FontWeight.bold,
                                  ),
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
        const SizedBox(height: 12),
        _buildDocumentNote(),
        // Validation status indicator
        if (_isValidatingIdCard) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'ছবি যাচাই করা হচ্ছে...',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_idCardValidationMessage != null && !_isValidatingIdCard) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: _isIdCardValid == true
                  ? AppTheme.successGreen.withOpacity(0.06)
                  : AppTheme.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _isIdCardValid == true
                    ? AppTheme.successGreen.withOpacity(0.2)
                    : AppTheme.error.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isIdCardValid == true
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color: _isIdCardValid == true
                      ? AppTheme.successGreen
                      : AppTheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _idCardValidationMessage!,
                    style: TextStyle(
                      color: _isIdCardValid == true
                          ? AppTheme.successGreen
                          : AppTheme.error,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
        hintStyle: const TextStyle(
          color: AppTheme.textHint,
          fontSize: 13,
        ),
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
                'নিবন্ধন করুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _register() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_idCardImage == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('নথি প্রয়োজন'),
          content: const Text(
            'নিবন্ধন সম্পন্ন করতে আপনার বিশ্ববিদ্যালয় আইডি কার্ড অথবা ভর্তির ফর্মের ছবি আপলোড করা বাধ্যতামূলক।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
      return;
    }

    if (_isValidatingIdCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ছবি যাচাই হচ্ছে... অপেক্ষা করুন।'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      return;
    }

    // Block if ML Kit rejected the image
    if (_isIdCardValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_idCardValidationMessage ?? 'সঠিক ছবি দিন।'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final role = widget.role; // 'student' or 'teacher'
      ref.read(authProvider.notifier).initPhoneRegistration(
            role: role,
            name: _nameController.text.trim(),
            phone: phone,
            password: password,
            department: _departmentController.text.trim(),
            idCard: _idCardImage!,
            rollNumber: role == 'student'
                ? _rollNumberController.text.trim()
                : null,
            session: role == 'student'
                ? _sessionController.text.trim()
                : null,
            teacherId: role == 'teacher'
                ? _teacherIdController.text.trim()
                : null,
            designation: role == 'teacher'
                ? _designationController.text.trim()
                : null,
          );
    }
  }
}
