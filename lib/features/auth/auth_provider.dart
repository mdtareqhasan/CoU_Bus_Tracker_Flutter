import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../core/error_handler.dart';
import '../../core/services/google_signin_service.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/models/auth_response.dart';
import '../notifications/fcm_token_service.dart';
import 'auth_repository.dart';
import '../providers.dart';

enum AuthStateStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  needsRegistration,
  needsVerification,
  /// Signed in, but the write-once academic details required by product
  /// policy are still missing. The user must be sent to
  /// `/auth/academic-details` and may not enter the app shell.
  needsProfileDetails,
}

/// Product gate shared by the login, session-restore and save-success paths.
///
/// A student may not use the app unless `department` + `rollNumber` +
/// `session` are set; a teacher needs `department` + `employeeId` +
/// `designation`. Blank/null counts as missing. [role] is case-insensitive
/// and anything that is not `teacher` is treated as a student.
bool isAcademicProfileComplete({
  required String? role,
  String? department,
  String? rollNumber,
  String? session,
  String? employeeId,
  String? designation,
}) {
  bool has(String? value) => value != null && value.trim().isNotEmpty;

  if (role != null && role.trim().toLowerCase() == 'teacher') {
    return has(department) && has(employeeId) && has(designation);
  }
  return has(department) && has(rollNumber) && has(session);
}

/// Reads a text field from a backend response body, treating blank as null.
String? _profileText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Uppercase role (STUDENT / TEACHER) pending OTP verification.
class AuthState {
  final AuthStateStatus status;
  final String? role;
  final String? displayName;
  final String? email;
  final String? phone;
  final int? userId;
  final bool isVerified;
  final bool isEduMail;
  final String? error;
  final String? pendingRole;
  final String? idCardImageUrl;

  // Write-once academic details from the last fetched/saved profile. They are
  // what the completion screen prefills (read-only) and what the gate checks.
  final String? department;
  final String? rollNumber;
  final String? session;
  final String? employeeId;
  final String? designation;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.role,
    this.displayName,
    this.email,
    this.phone,
    this.userId,
    this.isVerified = false,
    this.isEduMail = false,
    this.error,
    this.pendingRole,
    this.idCardImageUrl,
    this.department,
    this.rollNumber,
    this.session,
    this.employeeId,
    this.designation,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? role,
    String? displayName,
    String? email,
    String? phone,
    int? userId,
    bool? isVerified,
    bool? isEduMail,
    String? error,
    String? pendingRole,
    String? idCardImageUrl,
    String? department,
    String? rollNumber,
    String? session,
    String? employeeId,
    String? designation,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      isVerified: isVerified ?? this.isVerified,
      isEduMail: isEduMail ?? this.isEduMail,
      error: error,
      pendingRole: pendingRole ?? this.pendingRole,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      session: session ?? this.session,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
    );
  }

  bool get isLoggedIn =>
      status == AuthStateStatus.authenticated && displayName != null;

  /// `true` when every academic detail product policy requires is populated.
  /// Only meaningful once a profile has actually been fetched or saved.
  bool get isProfileComplete => isAcademicProfileComplete(
        role: role,
        department: department,
        rollNumber: rollNumber,
        session: session,
        employeeId: employeeId,
        designation: designation,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final StorageService _storage;
  final FcmTokenService _fcmTokenService;

  AuthNotifier(this._authRepo, this._storage, this._fcmTokenService)
      : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      // No token yet: restore a pending OTP verification session if present.
      final pendingPhone = await _storage.getPendingPhone();
      final pendingEmail = await _storage.getPendingEmail();
      if (pendingPhone != null) {
        final pendingRole = await _storage.getPendingRole();
        state = state.copyWith(
          status: AuthStateStatus.needsVerification,
          phone: pendingPhone,
          role: pendingRole,
          pendingRole: pendingRole?.toUpperCase(),
        );
      } else if (pendingEmail != null) {
        final pendingRole = await _storage.getPendingRole();
        state = state.copyWith(
          status: AuthStateStatus.needsVerification,
          email: pendingEmail,
          role: pendingRole,
          pendingRole: pendingRole?.toUpperCase(),
        );
      } else {
        state = state.copyWith(status: AuthStateStatus.unauthenticated);
      }
      return;
    }

    // A token exists locally. Validate it against the backend before
    // trusting it. If the user was deleted/rejected in the admin panel,
    // the profile endpoint returns 401/403 and we clear everything.
    final role = _storage.getRole() ?? 'student';
    final result = await _authRepo.validateToken(role);

    if (result case Failure(
      :final statusCode,
      :final message,
      :final error,
    )) {
      // PROFILE_INCOMPLETE is NOT a dead session — the user is still signed
      // in and only needs the completion form. `/me` is exempt server-side
      // so this should never fire, but never wipe the session over it.
      final isProfileIncomplete =
          statusCode == 403 && _isProfileIncompleteBody(error);
      final isAuthError =
          !isProfileIncomplete &&
          (statusCode == 401 ||
              statusCode == 403 ||
              message.toLowerCase().contains('সেশন শেষ'));

      if (isAuthError) {
        // Token invalid / user deleted → full cleanup.
        await _storage.clearSession();
        await _storage.clearAllCache();
        state = const AuthState(status: AuthStateStatus.unauthenticated);
        return;
      }
      // Network / server error → keep authenticated with cached data.
    }

    // Token accepted (or backend unreachable) → restore the session. Fetch
    // the profile for idCardImageUrl plus the once-only academic details the
    // product gate checks.
    String? idCardImageUrl;
    String? department;
    String? rollNumber;
    String? session;
    String? employeeId;
    String? designation;
    var profileLoaded = false;
    try {
      final profileResult = await _authRepo.getProfile(role);
      if (profileResult case Success(data: final profile)) {
        profileLoaded = true;
        idCardImageUrl = _profileText(profile['idCardImageUrl']);
        department = _profileText(profile['department']);
        rollNumber = _profileText(profile['rollNumber']);
        session = _profileText(profile['session']);
        employeeId =
            _profileText(profile['teacherId']) ??
            _profileText(profile['employeeId']);
        designation = _profileText(profile['designation']);
      }
    } catch (_) {
      // Ignore profile fetch errors
    }

    // Fail open when the profile could not be read: we must not push a
    // *complete* profile through the form. An incomplete one is still caught
    // by the backend's 403 → AuthInterceptor.onProfileIncomplete.
    final profileComplete =
        !profileLoaded ||
        isAcademicProfileComplete(
          role: role,
          department: department,
          rollNumber: rollNumber,
          session: session,
          employeeId: employeeId,
          designation: designation,
        );

    state = state.copyWith(
      status: profileComplete
          ? AuthStateStatus.authenticated
          : AuthStateStatus.needsProfileDetails,
      role: _storage.getRole(),
      displayName: _storage.getDisplayName(),
      email: _storage.getUserEmail(),
      phone: _storage.getUserPhone(),
      userId: _storage.getUserId(),
      isVerified: _storage.isVerified(),
      isEduMail: _storage.isEduMail(),
      idCardImageUrl: idCardImageUrl,
      department: department,
      rollNumber: rollNumber,
      session: session,
      employeeId: employeeId,
      designation: designation,
    );
  }

  /// Phone + password login. No OTP is involved.
  /// If the account exists but its phone is not verified yet, the state is
  /// set to `needsVerification` so the UI can route the user to the OTP step.
  Future<void> login({
    required String phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final normalized = normalizeBangladeshiPhone(phone);
      final result = _toUpperRole(role) == 'TEACHER'
          ? await _authRepo.teacherLoginPhone(
              phone: normalized,
              password: password,
            )
          : await _authRepo.studentLoginPhone(
              phone: normalized,
              password: password,
            );

      switch (result) {
        case Success(:final data):
          await _handleAuthSuccess(data, _toLowerRole(role));
        case Failure(:final message):
          if (_isVerifyPhoneMessage(message)) {
            await _storage.setPendingVerification(
              normalized,
              _toUpperRole(role),
            );
            state = state.copyWith(
              status: AuthStateStatus.needsVerification,
              phone: normalized,
              role: _toLowerRole(role),
              pendingRole: _toUpperRole(role),
              error: ErrorHandler.verifyPhoneFirst,
            );
          } else {
            state = state.copyWith(
              status: AuthStateStatus.error,
              error: message,
            );
          }
        default:
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: 'Unknown response',
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Email + password login. No OTP is involved. If the account exists but
  /// its email is not verified yet, the state is set to `needsVerification`.
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.emailLogin(
        role: _toEmailRole(role),
        email: email,
        password: password,
      );

      switch (result) {
        case Success(:final data):
          await _handleAuthSuccess(data, role.toLowerCase());
        case Failure(:final message):
          if (_isVerifyPhoneMessage(message)) {
            await _storage.setPendingVerificationEmail(
              email,
              _toEmailRole(role),
            );
            state = state.copyWith(
              status: AuthStateStatus.needsVerification,
              email: email,
              role: role.toLowerCase(),
              pendingRole: _toEmailRole(role),
              error: ErrorHandler.verifyEmailFirst,
            );
          } else {
            state = state.copyWith(
              status: AuthStateStatus.error,
              error: message,
            );
          }
        default:
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: 'Unknown response',
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Google Sign-In. The Google ID token from the client is verified by the
  /// backend, which returns a JWT for the matching account.
  Future<void> loginWithGoogle({
    required String idToken,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.googleLogin(idToken: idToken, role: role);

      switch (result) {
        case Success(:final data):
          await _handleAuthSuccess(data, role.toLowerCase());
        case Failure(:final message):
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: message,
          );
        default:
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: 'Unknown response',
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Verifies the six-digit OTP sent during registration. Returns the JWT on
  /// success, which logs the user in.
  Future<void> verifyOtp({
    required String phone,
    required String role,
    required String otp,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final normalized = normalizeBangladeshiPhone(phone);
      final result = await _authRepo.verifyPhoneOtp(
        phone: normalized,
        role: role,
        otp: otp,
      );

      switch (result) {
        case Success(:final data):
          if (data.accessToken == null || data.accessToken!.isEmpty) {
            state = state.copyWith(
              status: AuthStateStatus.error,
              error:
                  'ভেরিফিকেশন সফল হলেও টোকেন পাওয়া যায়নি। আবার চেষ্টা করুন।',
            );
            return;
          }
          await _handleAuthSuccess(data, _toLowerRole(role));
        case Failure(:final message):
          state = state.copyWith(status: AuthStateStatus.error, error: message);
        default:
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: 'Unknown response',
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      // Always leave the loading state, including on timeout/connection errors,
      // so the user can retry. The pending OTP session is NOT deleted here.
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Resends the OTP. Returns a Result so the screen can manage its own countdown.
  Future<Result<String>> resendOtp({
    required String phone,
    required String role,
  }) async {
    return _authRepo.resendPhoneOtp(
      phone: normalizeBangladeshiPhone(phone),
      role: role,
    );
  }

  /// Email OTP-first registration: submits the form to /auth/email-verification/init.
  /// The backend sends the email OTP. After this returns, we put the user in
  /// `needsVerification` until they verify the email OTP.
  Future<void> initEmailRegistration({
    required String role,
    required String name,
    required String email,
    required String password,
    required String department,
    String? rollNumber,
    String? session,
    String? employeeId,
    String? designation,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.initEmailRegistration(
        role: _toEmailRole(role),
        name: name,
        email: email,
        password: password,
        department: department,
        rollNumber: rollNumber,
        session: session,
        employeeId: employeeId,
        designation: designation,
      );

      switch (result) {
        case Success():
          await _storage.setPendingVerificationEmail(
            email,
            _toEmailRole(role),
          );
          state = state.copyWith(
            status: AuthStateStatus.needsVerification,
            role: role.toLowerCase(),
            email: email,
            displayName: name,
            pendingRole: _toEmailRole(role),
            error: null,
          );
        case Failure(:final message):
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: message,
          );
        case Loading():
          break;
        case Empty():
          break;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Verifies the six-digit email OTP. On success, logs the user in.
  Future<void> verifyEmailOtp({
    required String email,
    required String role,
    required String otp,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.verifyEmailOtp(
        email: email,
        role: _toEmailRole(role),
        otp: otp,
      );

      switch (result) {
        case Success(:final data):
          if (data.accessToken == null || data.accessToken!.isEmpty) {
            state = state.copyWith(
              status: AuthStateStatus.error,
              error:
                  'ভেরিফিকেশন সফল হলেও টোকেন পাওয়া যায়নি। আবার চেষ্টা করুন।',
            );
            return;
          }
          await _handleAuthSuccess(data, role.toLowerCase());
        case Failure(:final message):
          state = state.copyWith(status: AuthStateStatus.error, error: message);
        default:
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: 'Unknown response',
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  /// Resends the email OTP. Returns a Result so the screen can manage its own countdown.
  Future<Result<String>> resendEmailOtp({
    required String email,
    required String role,
  }) async {
    return _authRepo.resendEmailOtp(
      email: email,
      role: _toEmailRole(role),
    );
  }

  String _toEmailRole(String role) {
    final upper = role.trim().toUpperCase();
    return upper == 'TEACHER' ? 'EMPLOYEE' : upper;
  }

  /// Email password reset: sends OTP through /auth/forgot-password-email/init.
  Future<Result<String>> forgotPasswordEmailInit({
    required String email,
    required String role,
  }) async {
    return _authRepo.forgotPasswordEmailInit(
      email: email,
      role: _toEmailRole(role),
    );
  }

  /// Email password reset: verifies OTP and sets new password.
  Future<Result<String>> forgotPasswordEmailVerify({
    required String email,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    return _authRepo.forgotPasswordEmailVerify(
      email: email,
      role: _toEmailRole(role),
      otp: otp,
      newPassword: newPassword,
    );
  }

  /// Sends OTP for password reset.
  Future<Result<String>> forgotPasswordInit({
    required String phone,
    required String role,
  }) async {
    return _authRepo.forgotPasswordInit(
      phone: normalizeBangladeshiPhone(phone),
      role: role,
    );
  }

  /// Verifies OTP and resets password.
  Future<Result<String>> forgotPasswordVerify({
    required String phone,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    return _authRepo.forgotPasswordVerify(
      phone: normalizeBangladeshiPhone(phone),
      role: role,
      otp: otp,
      newPassword: newPassword,
    );
  }

  /// OTP-first registration: submits the full form to /auth/phone-verification/init.
  /// The backend uploads the ID card and SMS-sends the OTP. After this returns,
  /// we move the user into the `needsVerification` state holding the phone and role.
  Future<void> initPhoneRegistration({
    required String role,
    required String name,
    required String phone,
    required String password,
    required String department,
    required File idCard,
    String? rollNumber,
    String? session,
    String? teacherId,
    String? designation,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final normalized = normalizeBangladeshiPhone(phone);
      final result = await _authRepo.initPhoneRegistration(
        role: role.toLowerCase(),
        name: name,
        phone: normalized,
        password: password,
        department: department,
        idCard: idCard,
        rollNumber: rollNumber,
        session: session,
        teacherId: teacherId,
        designation: designation,
      );

      switch (result) {
        case Success():
          // Backend has both uploaded the ID card AND sent the OTP. We don't
          // get a token yet — that arrives only on OTP verification — so put
          // the user in the `needsVerification` state.
          await _storage.setPendingVerification(normalized, _toUpperRole(role));
          state = state.copyWith(
            status: AuthStateStatus.needsVerification,
            role: role.toLowerCase(),
            phone: normalized,
            displayName: name,
            pendingRole: _toUpperRole(role),
            error: null,
          );
        case Failure(:final message):
          state = state.copyWith(
            status: AuthStateStatus.error,
            error: message,
          );
        case Loading():
          // No-op; shouldn't reach here in practice but keeps the switch exhaustive.
          break;
        case Empty():
          // Result hasn't materialized yet; ignore.
          break;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        error: e.toString(),
      );
    } finally {
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }
  Future<void> _handleAuthSuccess(AuthResponse data, String role) async {
    // Clear pending verification as we are now logged in
    await _storage.setPendingVerification(null, null);
    await _storage.setPendingVerificationEmail(null, null);

    final phone = data.phone != null && data.phone!.isNotEmpty
        ? normalizeBangladeshiPhone(data.phone!)
        : state.phone;

    await _storage.saveSession(
      token: data.accessToken!,
      tokenType: data.tokenType,
      role: data.role?.toLowerCase() ?? role,
      name: data.name ?? 'User',
      email: data.email ?? '',
      phone: phone,
      userId: data.id,
      isVerified: data.isVerified ?? false,
      isEduMail: data.isEduMail ?? false,
    );

    // Fetch the profile: idCardImageUrl plus the once-only academic details
    // product policy requires before the app may be used.
    final profileRole = data.role?.toLowerCase() ?? role;
    String? idCardImageUrl;
    String? department;
    String? rollNumber;
    String? session;
    String? employeeId;
    String? designation;
    var profileLoaded = false;
    try {
      final profileResult = await _authRepo.getProfile(profileRole);
      if (profileResult case Success(data: final profile)) {
        profileLoaded = true;
        idCardImageUrl = _profileText(profile['idCardImageUrl']);
        department = _profileText(profile['department']);
        rollNumber = _profileText(profile['rollNumber']);
        session = _profileText(profile['session']);
        employeeId =
            _profileText(profile['teacherId']) ??
            _profileText(profile['employeeId']);
        designation = _profileText(profile['designation']);
      }
    } catch (_) {
      // Ignore profile fetch errors — idCardImageUrl / academic details stay
      // null and the gate below simply does not apply.
    }

    // Data-driven gate (Google *and* email/phone logins alike): an
    // incomplete profile must go to /auth/academic-details, never /home.
    // Fail open when the profile could not be read — the backend's 403 +
    // AuthInterceptor.onProfileIncomplete catch that case a moment later.
    final profileComplete =
        !profileLoaded ||
        isAcademicProfileComplete(
          role: profileRole,
          department: department,
          rollNumber: rollNumber,
          session: session,
          employeeId: employeeId,
          designation: designation,
        );

    state = state.copyWith(
      status: profileComplete
          ? AuthStateStatus.authenticated
          : AuthStateStatus.needsProfileDetails,
      role: profileRole,
      displayName: data.name ?? 'User',
      email: data.email ?? '',
      phone: phone,
      userId: data.id,
      isVerified: data.isVerified ?? false,
      isEduMail: data.isEduMail ?? false,
      pendingRole: null,
      idCardImageUrl: idCardImageUrl,
      department: department,
      rollNumber: rollNumber,
      session: session,
      employeeId: employeeId,
      designation: designation,
    );

    debugPrint(
      '[AUTH][PROFILE] role=$profileRole loaded=$profileLoaded '
      'complete=$profileComplete → ${state.status.name}',
    );

    // Now that a JWT is stored, register this device's FCM token so the user
    // can receive push notifications. Best-effort and non-blocking — a failure
    // here must never affect the login flow. While the profile is incomplete
    // the backend answers 403 PROFILE_INCOMPLETE, which the interceptor turns
    // into a navigation to the completion screen instead of a logout.
    unawaited(_fcmTokenService.registerIfAuthenticated());
  }

  /// Saves the write-once academic details. On success the refreshed profile
  /// is stored on the state and the status moves to `authenticated`, so the
  /// completion screen can go straight to `/home`.
  Future<Result<Map<String, dynamic>>> updateAcademicDetails({
    required String department,
    String? rollNumber,
    String? session,
    String? employeeId,
    String? designation,
  }) async {
    final role = (state.role ?? 'student').trim().toLowerCase();
    debugPrint('[AUTH][ACADEMIC] saving role=$role');

    final result = await _authRepo.updateAcademicDetails(
      role: role,
      department: department,
      rollNumber: rollNumber,
      session: session,
      employeeId: employeeId,
      designation: designation,
    );

    if (result case Success(data: final profile)) {
      state = state.copyWith(
        status: AuthStateStatus.authenticated,
        department: _profileText(profile['department']) ?? department,
        rollNumber: _profileText(profile['rollNumber']) ?? rollNumber,
        session: _profileText(profile['session']) ?? session,
        employeeId:
            _profileText(profile['teacherId']) ??
            _profileText(profile['employeeId']) ??
            employeeId,
        designation: _profileText(profile['designation']) ?? designation,
        idCardImageUrl:
            _profileText(profile['idCardImageUrl']) ?? state.idCardImageUrl,
        error: null,
      );
      debugPrint('[AUTH][ACADEMIC] saved → authenticated');

      // The 403 that blocked push registration at login is lifted now.
      unawaited(_fcmTokenService.registerIfAuthenticated());
    } else if (result case Failure(:final message)) {
      debugPrint('[AUTH][ACADEMIC] save failed: $message');
      // Stay in `needsProfileDetails`; the screen renders the message inline.
      state = state.copyWith(error: message);
    }

    return result;
  }

  /// Detects the backend's `PROFILE_INCOMPLETE` marker in a 403 body.
  static bool _isProfileIncompleteBody(Object? body) =>
      body is Map && body['code'] == 'PROFILE_INCOMPLETE';

  String _toUpperRole(String role) => role.trim().toUpperCase();
  String _toLowerRole(String role) => role.trim().toLowerCase();

  bool _isVerifyPhoneMessage(String message) {
    // Matched text is locale-dependent (built by ErrorHandler.friendly), so
    // compare through the any-locale helpers, not with `==`.
    final m = message.toLowerCase();
    return m.contains('verify your phone') ||
        m.contains('phone is not verified') ||
        m.contains('phone number not verified') ||
        m.contains('not verified') ||
        ErrorHandler.isVerifyEmailFirst(message) ||
        ErrorHandler.isVerifyPhoneFirst(message) ||
        m.contains('ফোন যাচাই') ||
        m.contains('ইমেইল যাচাই');
  }

  Future<void> logout() async {
    // Best-effort: remove this device's FCM token server-side so the next user
    // who logs in on this device doesn't inherit stale push targets. Runs
    // before clearing the session so the JWT is still attached to the request.
    unawaited(_fcmTokenService.unregisterCurrentToken());

    // Drop the cached Google account so the next sign-in shows the account
    // picker instead of silently reusing the previous Google user.
    await GoogleSignInService.instance.signOut();

    await _storage.clearSession();
    state = const AuthState(status: AuthStateStatus.unauthenticated);
  }

  /// Called when the backend returns 401/403 on an authenticated request
  /// (e.g. the user was deleted/rejected in the admin panel). The Dio
  /// interceptor has already wiped all secure storage and caches, so here we
  /// only reset the in-memory state so the whole UI reflects the logout.
  void forceLogout() {
    state = const AuthState(status: AuthStateStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    storage,
    ref.watch(fcmTokenServiceProvider),
  );
});
