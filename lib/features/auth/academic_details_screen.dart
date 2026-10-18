import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';
import '../../l10n/l10n.dart';
import 'auth_notification_permission.dart';
import 'auth_provider.dart';
import 'department_options.dart';
import 'session_options.dart';
import '../../shared/widgets/app_bar_language_switcher.dart';

/// Forced profile-completion form.
///
/// Shown to any signed-in student or teacher whose profile is still missing
/// the once-only academic details (Google Sign-In creates the row with all of
/// them NULL). The user cannot enter the app shell until they are saved:
/// [PopScope] blocks the system back gesture, and the backend additionally
/// answers 403 `PROFILE_INCOMPLETE` on every non-`/api/auth/**` request.
///
/// Values that are already stored are prefilled and read-only — the backend
/// rejects changing them with 400.
class AcademicDetailsScreen extends ConsumerStatefulWidget {
  final String role;
  const AcademicDetailsScreen({super.key, required this.role});

  @override
  ConsumerState<AcademicDetailsScreen> createState() =>
      _AcademicDetailsScreenState();
}

class _AcademicDetailsScreenState extends ConsumerState<AcademicDetailsScreen> {
  static final _idPattern = RegExp(r'^[A-Za-z0-9\-]{2,50}$');
  static final _sessionPattern = RegExp(r'^([0-9]{1,2}|[0-9]{4}(-[0-9]{2,4})?)$');

  final _formKey = GlobalKey<FormState>();
  final _departmentController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _sessionController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedSession;

  // Write-once: a value the backend already stores is locked and read-only.
  bool _departmentLocked = false;
  bool _rollNumberLocked = false;
  bool _sessionLocked = false;
  bool _employeeIdLocked = false;
  bool _designationLocked = false;

  bool _isLoading = false;
  bool _isLoggingOut = false;

  /// Form-level (non field-specific) server message, shown as a banner.
  String? _serverError;

  /// Field-level 400 messages from the backend's `errors` map, keyed by the
  /// backend field name (`department` / `rollNumber` / `session` /
  /// `employeeId` / `designation`).
  Map<String, String> _fieldErrors = const {};

  bool get isStudent => widget.role.trim().toLowerCase() != 'teacher';

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    final profile = ref.read(authProvider);

    final department = _textOrNull(profile.department);
    if (department != null) {
      _selectedDepartment = department;
      _departmentController.text = department;
      _departmentLocked = true;
    }

    final rollNumber = _textOrNull(profile.rollNumber);
    if (rollNumber != null) {
      _rollNumberController.text = rollNumber;
      _rollNumberLocked = true;
    }

    final session = _textOrNull(profile.session);
    if (session != null) {
      // The controller always holds the canonical stored value; the dropdown
      // and locked field render it in the app's language.
      _selectedSession = session;
      _sessionController.text = session;
      _sessionLocked = true;
    }

    final employeeId = _textOrNull(profile.employeeId);
    if (employeeId != null) {
      _employeeIdController.text = employeeId;
      _employeeIdLocked = true;
    }

    final designation = _textOrNull(profile.designation);
    if (designation != null) {
      _designationController.text = designation;
      _designationLocked = true;
    }
  }

  static String? _textOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _rollNumberController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  /// The canonical session value the backend pattern expects. The controller
  /// holds the value directly (the dropdown maps it to a localized label only
  /// for display), so this is a plain read.
  String _sessionValue() => _sessionController.text.trim();

  // ---------------------------------------------------------------------------
  // Validation — mirrors the backend bean validation so mistakes are caught
  // before the request goes out.
  // ---------------------------------------------------------------------------

  String? _validateDepartment(String? _) {
    final server = _fieldErrors['department'];
    if (server != null) return server;
    final value = _departmentController.text.trim();
    if (value.isEmpty) return context.l10n.validationDepartmentRequired;
    if (value.length < 2 || value.length > 100) {
      return context.l10n.validationDepartmentLength;
    }
    return null;
  }

  String? _validateRollNumber(String? _) {
    final server = _fieldErrors['rollNumber'];
    if (server != null) return server;
    final value = _rollNumberController.text.trim();
    if (value.isEmpty) return context.l10n.validationRollRequired;
    if (!_idPattern.hasMatch(value)) {
      return context.l10n.validationRollLength;
    }
    return null;
  }

  String? _validateSession(String? _) {
    final server = _fieldErrors['session'];
    if (server != null) return server;
    final value = _sessionValue();
    if (value.isEmpty) return context.l10n.validationSessionRequired;
    if (!_sessionPattern.hasMatch(value)) {
      return context.l10n.validationSessionFormat;
    }
    return null;
  }

  String? _validateEmployeeId(String? _) {
    final server = _fieldErrors['employeeId'];
    if (server != null) return server;
    final value = _employeeIdController.text.trim();
    if (value.isEmpty) return context.l10n.validationEmployeeIdRequired;
    if (!_idPattern.hasMatch(value)) {
      return context.l10n.validationEmployeeIdLength;
    }
    return null;
  }

  String? _validateDesignation(String? _) {
    final server = _fieldErrors['designation'];
    if (server != null) return server;
    final value = _designationController.text.trim();
    if (value.isEmpty) return context.l10n.validationDesignationRequired;
    if (value.length > 100) return context.l10n.validationDesignationLength;
    return null;
  }

  void _clearServerErrors() {
    if (_fieldErrors.isEmpty && _serverError == null) return;
    setState(() {
      _fieldErrors = const {};
      _serverError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _fieldErrors = const {};
      _serverError = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .updateAcademicDetails(
          department: _departmentController.text.trim(),
          rollNumber: isStudent ? _rollNumberController.text.trim() : null,
          session: isStudent ? _sessionValue() : null,
          employeeId: isStudent ? null : _employeeIdController.text.trim(),
          designation: isStudent ? null : _designationController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result case Success()) {
      // Profile is complete now — straight to the app, no ID-card step.
      requestPostAuthNotificationPermissionAfterNavigation(context);
      context.go('/home');
      return;
    }

    if (result case Failure(:final message, :final error)) {
      final fieldErrors = _extractFieldErrors(error);
      setState(() {
        _fieldErrors = fieldErrors;
        _serverError =
            fieldErrors.isNotEmpty ? null : _extractServerMessage(error, message);
      });
      // Re-run validation so the field-level messages appear in place.
      _formKey.currentState?.validate();
    }
  }

  /// Pulls `{"errors": {"rollNumber": ["msg"]}}` out of a 400 body.
  ///
  /// The backend's Bean-Validation text is English-only, so each value is run
  /// through [ErrorHandler.field] before it is shown inline under a form field.
  static Map<String, String> _extractFieldErrors(Object? body) {
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map) return ErrorHandler.localizeFieldErrors(errors);
    }
    return const {};
  }

  /// The business-rule message when the body has no field errors.
  ///
  /// Prefers the localized text for the backend's machine-readable `code`;
  /// falls back to the raw English `message` (older responses), then [fallback]
  /// — which is already localized by `ErrorHandler`.
  static String _extractServerMessage(Object? body, String fallback) {
    if (body is Map) {
      final code = body['code'];
      if (code is String) {
        final localized = ErrorHandler.fromCode(code);
        if (localized != null) return localized;
      }
      final message = body['message'];
      if (message is String &&
          message.trim().isNotEmpty &&
          message.trim().toLowerCase() != 'validation failed') {
        return message.trim();
      }
    }
    return fallback;
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          context.l10n.academicLogoutTitle,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          context.l10n.academicLogoutBody,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.profileLogout,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    // `logout()` also drops the cached Google account, so the next sign-in
    // shows the account picker instead of silently reusing this one.
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/auth/role');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final roleTitle = isStudent
        ? context.l10n.academicStudentTitle
        : context.l10n.academicStaffTitle;

    return PopScope(
      // The app shell is off-limits until the profile is complete, so the
      // system back gesture must not do anything.
      canPop: false,
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
                            context.l10n.academicSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: AppTheme.space16),
                          _buildWriteOnceNotice().animate().fadeIn(
                            delay: 300.ms,
                          ),
                          const SizedBox(height: AppTheme.space12),
                          ..._buildFields(),
                          if (_serverError != null) ...[
                            const SizedBox(height: AppTheme.space12),
                            _buildServerErrorBanner(),
                          ],
                          const SizedBox(height: AppTheme.space32),
                          _buildSubmitButton(),
                          const SizedBox(height: AppTheme.space16),
                          _buildLogoutButton(),
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

  List<Widget> _buildFields() {
    if (isStudent) {
      return [
        _buildDepartmentField()
            .animate()
            .fadeIn(delay: 400.ms)
            .slideX(begin: 0.1, end: 0),
        const SizedBox(height: AppTheme.space12),
        _buildRollNumberField()
            .animate()
            .fadeIn(delay: 500.ms)
            .slideX(begin: 0.1, end: 0),
        const SizedBox(height: AppTheme.space12),
        _buildSessionField()
            .animate()
            .fadeIn(delay: 600.ms)
            .slideX(begin: 0.1, end: 0),
      ];
    }
    return [
      _buildDepartmentField()
          .animate()
          .fadeIn(delay: 400.ms)
          .slideX(begin: 0.1, end: 0),
      const SizedBox(height: AppTheme.space12),
      _buildEmployeeIdField()
          .animate()
          .fadeIn(delay: 500.ms)
          .slideX(begin: 0.1, end: 0),
      const SizedBox(height: AppTheme.space12),
      _buildDesignationField()
          .animate()
          .fadeIn(delay: 600.ms)
          .slideX(begin: 0.1, end: 0),
    ];
  }

  Widget _buildWriteOnceNotice() {
    return Container(
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
              context.l10n.academicOnceOnlyNote,
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
    );
  }

  Widget _buildDepartmentField() {
    if (_departmentLocked) {
      return _buildLockedField(
        controller: _departmentController,
        label: isStudent
            ? context.l10n.fieldDepartment
            : context.l10n.fieldDepartmentOffice,
        icon: Icons.business_outlined,
        validator: _validateDepartment,
        // The stored value is canonical (Bengali); show the localized name.
        displayText:
            departmentLabelFor(_departmentController.text.trim(), context.l10n),
      );
    }

    // The stored value may not be one of the predefined options (e.g. it was
    // set by an admin) — add it so the dropdown never loses it.
    final options = isStudent ? departmentOptions : teacherDepartmentOptions;
    final items = _selectedDepartment != null &&
            _selectedDepartment!.isNotEmpty &&
            !options.any((option) => option.value == _selectedDepartment)
        ? [
            ...options,
            AcademicOption(_selectedDepartment!, (l10n) => _selectedDepartment!),
          ]
        : options;

    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(
        labelText: isStudent
            ? context.l10n.fieldDepartment
            : context.l10n.fieldDepartmentOffice,
        icon: Icons.business_outlined,
      ),
      hint: Text(
        isStudent
            ? context.l10n.selectDepartment
            : context.l10n.selectDepartmentOffice,
      ),
      initialValue: _selectedDepartment,
      items: items
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 100,
                ),
                child: Text(
                  option.label(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
      validator: _validateDepartment,
      onChanged: (value) {
        _clearServerErrors();
        setState(() {
          _selectedDepartment = value;
          _departmentController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildRollNumberField() {
    if (_rollNumberLocked) {
      return _buildLockedField(
        controller: _rollNumberController,
        label: context.l10n.fieldRollNumber,
        icon: Icons.badge_outlined,
        validator: _validateRollNumber,
      );
    }
    return TextFormField(
      controller: _rollNumberController,
      style: _fieldStyle,
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(
        labelText: context.l10n.fieldRollNumber,
        icon: Icons.badge_outlined,
        hintText: context.l10n.hintExampleRoll,
      ),
      validator: _validateRollNumber,
      onChanged: (_) => _clearServerErrors(),
    );
  }

  Widget _buildSessionField() {
    if (_sessionLocked) {
      return _buildLockedField(
        controller: _sessionController,
        label: context.l10n.fieldSession,
        icon: Icons.class_outlined,
        validator: _validateSession,
        // The stored value is the English form; show the localized label.
        displayText:
            sessionLabelFor(_sessionController.text.trim(), context.l10n),
      );
    }

    // The controller holds the canonical value (`2020-2021`); the dropdown
    // shows the localized label. Keep any stored/unknown value selectable so
    // the dropdown's value always matches what is submitted.
    final items = _selectedSession != null &&
            _selectedSession!.isNotEmpty &&
            !sessionValues.contains(_selectedSession)
        ? [
            ...sessionOptions,
            SessionOption(_selectedSession!, (l10n) => _selectedSession!),
          ]
        : sessionOptions;

    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(
        labelText: context.l10n.fieldSession,
        icon: Icons.class_outlined,
      ),
      hint: Text(context.l10n.selectSession),
      initialValue: _selectedSession,
      items: items
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: Text(
                option.label(context.l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: _validateSession,
      onChanged: (value) {
        _clearServerErrors();
        setState(() {
          _selectedSession = value;
          _sessionController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildEmployeeIdField() {
    if (_employeeIdLocked) {
      return _buildLockedField(
        controller: _employeeIdController,
        label: context.l10n.fieldEmployeeId,
        icon: Icons.badge_outlined,
        validator: _validateEmployeeId,
      );
    }
    return TextFormField(
      controller: _employeeIdController,
      style: _fieldStyle,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      decoration: _inputDecoration(
        labelText: context.l10n.fieldEmployeeId,
        icon: Icons.badge_outlined,
        hintText: context.l10n.hintExampleEmployeeId,
      ),
      validator: _validateEmployeeId,
      onChanged: (_) => _clearServerErrors(),
    );
  }

  Widget _buildDesignationField() {
    if (_designationLocked) {
      return _buildLockedField(
        controller: _designationController,
        label: context.l10n.fieldDesignation,
        icon: Icons.work_outline_rounded,
        validator: _validateDesignation,
      );
    }
    return TextFormField(
      controller: _designationController,
      style: _fieldStyle,
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(
        labelText: context.l10n.fieldDesignation,
        icon: Icons.work_outline_rounded,
        hintText: context.l10n.hintExampleDesignation,
      ),
      validator: _validateDesignation,
      onChanged: (_) => _clearServerErrors(),
    );
  }

  /// A value the backend already stores: shown greyed out and impossible to
  /// edit, with a short hint explaining why.
  Widget _buildLockedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? displayText,
  }) {
    // [displayText] overrides what is shown while [controller] keeps the
    // canonical value for validation/submission (e.g. the session's English
    // value shown as its localized label).
    return TextFormField(
      controller: displayText == null ? controller : null,
      initialValue: displayText,
      enabled: false,
      style: _fieldStyle,
      decoration: _inputDecoration(
        labelText: label,
        icon: icon,
        suffixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: AppTheme.textHint,
        ),
        helperText: context.l10n.academicHelperOnce,
      ),
      validator: validator,
    );
  }

  Widget _buildServerErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppTheme.error,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              _serverError!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSubmitButton() {
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
        onPressed: _isLoading ? null : _submit,
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
            : Text(
                context.l10n.academicSave,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Discreet escape hatch so nobody is trapped behind the gate.
  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _isLoading || _isLoggingOut ? null : _logout,
      child: _isLoggingOut
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: AppTheme.textHint,
                strokeWidth: 2,
              ),
            )
          : Text(
              context.l10n.profileLogout,
              style: const TextStyle(
                color: AppTheme.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: const [AppBarLanguageSwitcher()],
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
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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

  static const _fieldStyle = TextStyle(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
  );

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
      helperStyle: const TextStyle(color: AppTheme.textHint, fontSize: 11),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(
          color: AppTheme.textHint.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
