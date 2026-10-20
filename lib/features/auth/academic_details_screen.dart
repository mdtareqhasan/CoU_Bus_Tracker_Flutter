import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';
import '../../l10n/l10n.dart';
import 'academic_options_provider.dart';
import 'auth_notification_permission.dart';
import 'auth_provider.dart';
import 'department_options.dart';
import 'session_options.dart';
import '../../shared/models/academic_reference_option.dart';
import '../../shared/widgets/app_bar_language_switcher.dart';

/// Forced profile-completion form.
///
/// Shown to any signed-in student or teacher whose profile is still missing
/// the once-only academic details (Google Sign-In creates the row with all of
/// them NULL). The user cannot enter the app shell until they are saved:
/// [PopScope] blocks the system back gesture, and the backend additionally
/// answers 403 `PROFILE_INCOMPLETE` on every non-`/api/auth/**` request.
///
/// The department/office and session pickers are filled from the public
/// `/api/academic/**` reference endpoints (`academicOptionsProvider`) rather
/// than from a list compiled into the app, and what gets submitted is the
/// option's row id (`departmentId` / `sessionId`). The server sends both
/// language forms of every name; this screen renders whichever matches the
/// current locale.
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

  final _formKey = GlobalKey<FormState>();
  final _rollNumberController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();

  // Canonical stored values from the profile (write-once): the labels on the
  // locked fields, and the fallback for recovering an option id a profile
  // response did not carry.
  String? _departmentText;
  String? _sessionText;

  // The option row ids the pickers submit as `departmentId` / `sessionId`.
  int? _selectedDepartmentId;
  int? _selectedSessionId;

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
  /// backend field name (`departmentId` / `rollNumber` / `sessionId` /
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
      _departmentText = department;
      _selectedDepartmentId = profile.departmentId;
      _departmentLocked = true;
    }

    final rollNumber = _textOrNull(profile.rollNumber);
    if (rollNumber != null) {
      _rollNumberController.text = rollNumber;
      _rollNumberLocked = true;
    }

    final session = _textOrNull(profile.session);
    if (session != null) {
      // The canonical stored value stays in [_sessionText]; the dropdown and
      // locked field render it in the app's language.
      _sessionText = session;
      _selectedSessionId = profile.sessionId;
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
    _rollNumberController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation — mirrors the backend bean validation so mistakes are caught
  // before the request goes out.
  // ---------------------------------------------------------------------------

  String? _validateDepartment(String? _) {
    // Both spellings are accepted: the current backend keys this error on the
    // `departmentId` property, older ones on `department`.
    final server = _fieldErrors['departmentId'] ?? _fieldErrors['department'];
    if (server != null) return server;
    if (_selectedDepartmentId != null) return null;
    return context.l10n.validationDepartmentRequired;
  }

  /// Same rule as [_validateDepartment] in the signature the id-valued
  /// `DropdownButtonFormField<int>` needs; neither reads the argument, the
  /// state fields are the source of truth.
  String? _validateDepartmentId(int? _) => _validateDepartment(null);

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
    final server = _fieldErrors['sessionId'] ?? _fieldErrors['session'];
    if (server != null) return server;
    if (_selectedSessionId != null) return null;
    return context.l10n.validationSessionRequired;
  }

  /// [String?] twin of [_validateSession] for `DropdownButtonFormField<int>`.
  String? _validateSessionId(int? _) => _validateSession(null);

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
  // Academic options — the pickers are filled from /api/academic/**, so every
  // lookup here works against the fetched rows rather than a bundled list.
  // ---------------------------------------------------------------------------

  /// Recovers an option id for a value the profile stored as text only.
  ///
  /// The current backend always returns `departmentId`/`sessionId` next to the
  /// names, so this normally changes nothing; it keeps an older or partial
  /// profile payload submitting a real foreign key instead of failing
  /// validation on a field the user cannot edit.
  void _resolveMissingIds() {
    final options = ref.read(academicOptionsProvider).valueOrNull;
    if (options == null) return;

    if (_selectedDepartmentId == null) {
      final match = _findUnit(options, null, _departmentText);
      if (match != null) _selectedDepartmentId = match.id;
    }
    if (_selectedSessionId == null) {
      final match = _findSession(options, null, _sessionText);
      if (match != null) _selectedSessionId = match.id;
    }
  }

  /// The option with [id], else the one whose canonical value or either label
  /// equals [text]. Returns null when the list is not loaded or the row is no
  /// longer offered (retired rows are not published on the public endpoints).
  static AcademicReferenceOption? _findUnit(
    AcademicOptions? options,
    int? id,
    String? text,
  ) => _find(options?.units, id, text);

  static AcademicReferenceOption? _findSession(
    AcademicOptions? options,
    int? id,
    String? text,
  ) => _find(options?.sessions, id, text);

  static AcademicReferenceOption? _find(
    List<AcademicReferenceOption>? options,
    int? id,
    String? text,
  ) {
    if (options == null) return null;
    if (id != null) {
      for (final option in options) {
        if (option.id == id) return option;
      }
    }
    if (text == null || text.isEmpty) return null;
    for (final option in options) {
      if (option.value == text ||
          option.labelBn == text ||
          option.labelEn == text) {
        return option;
      }
    }
    return null;
  }

  /// A stored department/office rendered in the app's language: the fetched
  /// option wins (it follows an admin rename), then the bundled label list
  /// covers the frames before the options arrive, then the raw value.
  String _unitLabel(String text, AcademicOptions? options) {
    final match = _findUnit(options, _selectedDepartmentId, text);
    if (match != null) return match.labelFor(context.l10n.localeName);
    return departmentLabelFor(text, context.l10n);
  }

  /// Same, for the stored session value (either language form — the profile
  /// sends the Bengali digits, older payloads the ASCII range).
  String _sessionLabel(String text, AcademicOptions? options) {
    final match = _findSession(options, _selectedSessionId, text);
    if (match != null) return match.labelFor(context.l10n.localeName);
    return sessionLabelFor(text, context.l10n);
  }

  /// The already-localized failure message of [academicOptionsProvider].
  static String _optionsErrorMessage(Object error) =>
      error is AcademicOptionsException
      ? error.message
      : ErrorHandler.defaultError;

  /// The failure [academicOptionsProvider] carries, if its list failed to
  /// load (null while it is loading or once it succeeded).
  static Object? _optionsError(AsyncValue<AcademicOptions> options) {
    if (options case AsyncError(:final error)) return error;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // A locked value whose option id the profile did not carry (an older or
    // partial payload) is resolved back to an id from the fetched list before
    // validation runs — the field itself cannot be edited by the user.
    _resolveMissingIds();

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
          departmentId: _selectedDepartmentId!,
          rollNumber: isStudent ? _rollNumberController.text.trim() : null,
          sessionId: isStudent ? _selectedSessionId : null,
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
        _serverError = fieldErrors.isNotEmpty
            ? null
            : _extractServerMessage(error, message);
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          // BN/EN switcher, deliberately kept out of the app
                          // bar: it sits with the content, top-right.
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AppBarLanguageSwitcher(),
                          ),
                          const SizedBox(height: AppTheme.space24),
                          _buildHeaderIllustration(),
                          const SizedBox(height: AppTheme.space24),
                          Text(
                                roleTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            context.l10n.academicSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
    // Watched during build so the pickers rebuild as the option lists arrive
    // (and again after a retry invalidates the provider).
    final options = ref.watch(academicOptionsProvider);

    if (isStudent) {
      return [
        _buildDepartmentField(
          options,
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
        const SizedBox(height: AppTheme.space12),
        _buildRollNumberField()
            .animate()
            .fadeIn(delay: 500.ms)
            .slideX(begin: 0.1, end: 0),
        const SizedBox(height: AppTheme.space12),
        _buildSessionField(
          options,
        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
      ];
    }
    return [
      _buildDepartmentField(
        options,
      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
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

  Widget _buildDepartmentField(AsyncValue<AcademicOptions> options) {
    final label = isStudent
        ? context.l10n.fieldDepartment
        : context.l10n.fieldDepartmentOffice;

    if (_departmentLocked) {
      // A stored value the profile did not carry an id for can only be turned
      // back into one from the fetched list. If that list failed to load, show
      // the retry instead of a filled-in lock that could never be submitted.
      final optionsError = _optionsError(options);
      if (_selectedDepartmentId == null && optionsError != null) {
        return _pickerError(
          labelText: label,
          message: _optionsErrorMessage(optionsError),
        );
      }
      return _buildLockedField(
        label: label,
        icon: Icons.business_outlined,
        validator: _validateDepartment,
        // The stored value is canonical (Bengali); show the localized name.
        displayText: _unitLabel(_departmentText!, options.valueOrNull),
      );
    }

    return options.when<Widget>(
      // The list arrives a moment after the first frame; a refresh (retry)
      // shows the spinner again rather than the stale failure.
      skipLoadingOnRefresh: false,
      loading: () =>
          _pickerLoading(labelText: label, icon: Icons.business_outlined),
      error: (error, _) =>
          _pickerError(labelText: label, message: _optionsErrorMessage(error)),
      data: (loaded) => _unitDropdown(loaded, label: label),
    );
  }

  /// The department (student) / department-or-office (teacher) picker, built
  /// from the fetched rows with the row id as the selectable value.
  Widget _unitDropdown(AcademicOptions loaded, {required String label}) {
    final l10n = context.l10n;
    final hint = isStudent
        ? l10n.selectDepartment
        : l10n.selectDepartmentOffice;

    return DropdownButtonFormField<int>(
      decoration: _inputDecoration(
        context: context,
        labelText: label,
        icon: Icons.business_outlined,
      ),
      hint: Text(hint),
      initialValue: _selectedDepartmentId,
      items: [
        for (final option in loaded.unitsForRole(widget.role))
          DropdownMenuItem<int>(
            value: option.id,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: Text(
                option.labelFor(l10n.localeName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
      validator: _validateDepartmentId,
      onChanged: (value) {
        _clearServerErrors();
        setState(() => _selectedDepartmentId = value);
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
      style: _fieldStyle(context),
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(
        context: context,
        labelText: context.l10n.fieldRollNumber,
        icon: Icons.badge_outlined,
        hintText: context.l10n.hintExampleRoll,
      ),
      validator: _validateRollNumber,
      onChanged: (_) => _clearServerErrors(),
    );
  }

  Widget _buildSessionField(AsyncValue<AcademicOptions> options) {
    if (_sessionLocked) {
      // Same escape hatch as the department field: an id-less stored value
      // needs the fetched list to become submittable again.
      final optionsError = _optionsError(options);
      if (_selectedSessionId == null && optionsError != null) {
        return _pickerError(
          labelText: context.l10n.fieldSession,
          message: _optionsErrorMessage(optionsError),
        );
      }
      return _buildLockedField(
        label: context.l10n.fieldSession,
        icon: Icons.class_outlined,
        validator: _validateSession,
        // The stored value is the English form; show the localized label.
        displayText: _sessionLabel(_sessionText!, options.valueOrNull),
      );
    }

    return options.when<Widget>(
      skipLoadingOnRefresh: false,
      loading: () => _pickerLoading(
        labelText: context.l10n.fieldSession,
        icon: Icons.class_outlined,
      ),
      error: (error, _) => _pickerError(
        labelText: context.l10n.fieldSession,
        message: _optionsErrorMessage(error),
      ),
      data: (loaded) => _sessionDropdown(loaded),
    );
  }

  /// The session picker: the fetched rows with the row id as the selectable
  /// value, each label rendered in the app's language.
  Widget _sessionDropdown(AcademicOptions loaded) {
    final l10n = context.l10n;

    return DropdownButtonFormField<int>(
      decoration: _inputDecoration(
        context: context,
        labelText: l10n.fieldSession,
        icon: Icons.class_outlined,
      ),
      hint: Text(l10n.selectSession),
      initialValue: _selectedSessionId,
      items: [
        for (final option in loaded.sessions)
          DropdownMenuItem<int>(
            value: option.id,
            child: Text(
              option.labelFor(l10n.localeName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      validator: _validateSessionId,
      onChanged: (value) {
        _clearServerErrors();
        setState(() => _selectedSessionId = value);
      },
    );
  }

  /// Placeholder while the option list is being fetched: a disabled-looking
  /// field with a spinner instead of a dropdown that would flash empty.
  Widget _pickerLoading({required String labelText, required IconData icon}) {
    return InputDecorator(
      decoration: _inputDecoration(
        context: context,
        labelText: labelText,
        icon: icon,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Text(
            context.l10n.academicOptionsLoading,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Shown in place of a picker whose list could not be fetched. The button
  /// re-fetches rather than leaving the screen to fail silently — without the
  /// option ids there is nothing to submit.
  Widget _pickerError({required String labelText, required String message}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space12,
        AppTheme.space8,
        AppTheme.space4,
        AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  '$labelText — $message',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => ref.invalidate(academicOptionsProvider),
              child: Text(
                context.l10n.commonRetry,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
      style: _fieldStyle(context),
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      decoration: _inputDecoration(
        context: context,
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
      style: _fieldStyle(context),
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(
        context: context,
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
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextEditingController? controller,
    String? displayText,
  }) {
    // [displayText] overrides what is shown while [controller] keeps the
    // canonical value for validation/submission (e.g. the stored session
    // shown as its localized label). The department/session fields pass
    // only [displayText] — their canonical value lives in state now, not in a
    // controller.
    return TextFormField(
      // `initialValue` only seeds a field's state once, so a key is what makes
      // a changed label rebuild it: the fetched option arriving after the
      // first frame, a locale switch, or an admin renaming the row. Without
      // it the field would keep the first (possibly fallback) text forever.
      key: displayText != null ? ValueKey('locked-$label-$displayText') : null,
      controller: displayText == null ? controller : null,
      initialValue: displayText,
      enabled: false,
      style: _fieldStyle(context),
      decoration: _inputDecoration(
        context: context,
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
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
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
        gradient: AppTheme.primaryGradientFor(context),
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
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradientFor(context),
        ),
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

  TextStyle _fieldStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w500,
  );

  InputDecoration _inputDecoration({
    required BuildContext context,
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
      fillColor: Theme.of(context).colorScheme.surface,
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
        borderSide: BorderSide(color: AppTheme.textHint.withValues(alpha: 0.3)),
      ),
    );
  }
}
