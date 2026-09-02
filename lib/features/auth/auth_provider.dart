import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../core/error_handler.dart';
import '../../shared/models/auth_response.dart';
import '../../shared/models/login_request.dart';
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
}

class AuthState {
  final AuthStateStatus status;
  final String? role;
  final String? displayName;
  final String? email;
  final int? userId;
  final bool isVerified;
  final bool isEduMail;
  final String? error;

  /// Uppercase role (STUDENT / TEACHER) pending OTP verification.
  final String? pendingRole;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.role,
    this.displayName,
    this.email,
    this.userId,
    this.isVerified = false,
    this.isEduMail = false,
    this.error,
    this.pendingRole,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? role,
    String? displayName,
    String? email,
    int? userId,
    bool? isVerified,
    bool? isEduMail,
    String? error,
    String? pendingRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      isVerified: isVerified ?? this.isVerified,
      isEduMail: isEduMail ?? this.isEduMail,
      error: error,
      pendingRole: pendingRole ?? this.pendingRole,
    );
  }

  bool get isLoggedIn =>
      status == AuthStateStatus.authenticated && displayName != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final StorageService _storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '111634412431-th7l3d7cqtmrpqhrn16hvs55j2f6f9qa.apps.googleusercontent.com',
  );

  AuthNotifier(this._authRepo, this._storage) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      // No token yet: restore a pending OTP verification session if present.
      final pendingEmail = await _storage.getPendingEmail();
      if (pendingEmail != null) {
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

    if (result case Failure(:final statusCode)) {
      final isAuthError =
          statusCode == 401 ||
          statusCode == 403 ||
          (result as Failure).message.toLowerCase().contains('সেশন শেষ');

      if (isAuthError) {
        // Token invalid / user deleted → full cleanup.
        await _storage.clearSession();
        await _storage.clearAllCache();
        state = const AuthState(status: AuthStateStatus.unauthenticated);
        return;
      }
      // Network / server error → keep authenticated with cached data.
    }

    // Token accepted (or backend unreachable) → mark authenticated.
    state = state.copyWith(
      status: AuthStateStatus.authenticated,
      role: _storage.getRole(),
      displayName: _storage.getDisplayName(),
      email: _storage.getUserEmail(),
      userId: _storage.getUserId(),
      isVerified: _storage.isVerified(),
      isEduMail: _storage.isEduMail(),
    );
  }

  Future<void> googleLogin(String role) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(status: AuthStateStatus.unauthenticated);
        return;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: 'Google ID Token not found',
        );
        return;
      }

      final result = await _authRepo.googleLogin(idToken, role);

      switch (result) {
        case Success(:final data):
          await _handleAuthSuccess(data, role.toLowerCase());
        case Failure(:final message):
          if (_isRegisterFirstMessage(message)) {
            state = state.copyWith(
              status: AuthStateStatus.needsRegistration,
              email: account.email,
              displayName: account.displayName,
              error: message,
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
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    final req = LoginRequest(email: email, password: password);
    final Result<AuthResponse> result;

    if (role.toLowerCase() == 'student') {
      result = await _authRepo.studentLogin(req);
    } else if (role.toLowerCase() == 'teacher') {
      result = await _authRepo.teacherLogin(req);
    } else {
      result = await _authRepo.adminLogin(req);
    }

    switch (result) {
      case Success(:final data):
        await _handleAuthSuccess(data, role.toLowerCase());
      case Failure(:final message):
        if (_isVerifyEmailMessage(message)) {
          state = state.copyWith(
            status: AuthStateStatus.needsVerification,
            email: email,
            pendingRole: _toUpperRole(role),
            error: ErrorHandler.verifyEmailFirst,
          );
        } else {
          state = state.copyWith(status: AuthStateStatus.error, error: message);
        }
      default:
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: 'Unknown response',
        );
    }
  }

  /// Verifies the six-digit OTP and, on success, saves the session.
  Future<void> verifyOtp({
    required String email,
    required String role,
    required String otp,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.verifyEmailOtp(
        email: email,
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
    required String email,
    required String role,
  }) async {
    return _authRepo.resendEmailOtp(email: email, role: role);
  }

  Future<void> studentRegister({
    required String name,
    required String email,
    String? password,
    String? googleIdToken,
    required String studentId,
    required String department,
    required String varsityBatch,
    required File idCard,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.studentRegister(
        name: name,
        email: email,
        password: password,
        googleIdToken: googleIdToken,
        studentId: studentId,
        department: department,
        varsityBatch: varsityBatch,
        idCard: idCard,
      );

      switch (result) {
        case Success(:final data):
          await _handleRegisterSuccess(
            data,
            'student',
            fallbackEmail: email.trim(),
          );
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
      // Always leave the loading state on success, DioException, timeout,
      // validation error, or any unexpected exception.
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  Future<void> teacherRegister({
    required String name,
    required String email,
    String? password,
    String? googleIdToken,
    required String teacherId,
    required String department,
    String? designation,
    String? phone,
    required File idCard,
  }) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    try {
      final result = await _authRepo.teacherRegister(
        name: name,
        email: email,
        password: password,
        googleIdToken: googleIdToken,
        teacherId: teacherId,
        department: department,
        designation: designation,
        phone: phone,
        idCard: idCard,
      );

      switch (result) {
        case Success(:final data):
          await _handleRegisterSuccess(
            data,
            'teacher',
            fallbackEmail: email.trim(),
          );
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
      // Always leave the loading state on success, DioException, timeout,
      // validation error, or any unexpected exception.
      if (state.status == AuthStateStatus.loading) {
        state = state.copyWith(status: AuthStateStatus.error);
      }
    }
  }

  Future<void> _handleAuthSuccess(AuthResponse data, String role) async {
    // Clear pending verification as we are now logged in
    await _storage.setPendingVerification(null, null);

    await _storage.saveSession(
      token: data.accessToken!,
      tokenType: data.tokenType,
      role: data.role?.toLowerCase() ?? role,
      name: data.name ?? 'User',
      email: data.email ?? '',
      userId: data.id,
      isVerified: data.isVerified ?? false,
      isEduMail: data.isEduMail ?? false,
    );
    state = state.copyWith(
      status: AuthStateStatus.authenticated,
      role: data.role?.toLowerCase() ?? role,
      displayName: data.name ?? 'User',
      email: data.email ?? '',
      userId: data.id,
      isVerified: data.isVerified ?? false,
      isEduMail: data.isEduMail ?? false,
    );
  }

  /// Registration returns no token until the email OTP is verified.
  /// If the response has no access token, we save a pending OTP session and
  /// hold the user at the OTP screen. We never log the user in here.
  Future<void> _handleRegisterSuccess(
    AuthResponse data,
    String role, {
    String? fallbackEmail,
  }) async {
    final hasToken = data.accessToken != null && data.accessToken!.isNotEmpty;
    final verified = data.isVerified ?? false;

    if (!hasToken || !verified) {
      final email = data.email?.trim().isNotEmpty == true
          ? data.email
          : fallbackEmail;

      // Persist a pending OTP session (email + role) in secure storage so it
      // survives app restart. The OTP itself is never stored.
      if (email != null && email.isNotEmpty) {
        await _storage.setPendingVerification(email, _toUpperRole(role));
      }

      state = state.copyWith(
        status: AuthStateStatus.needsVerification,
        role: role,
        email: email,
        displayName: data.name,
        userId: data.id,
        pendingRole: _toUpperRole(role),
        error: null,
      );
      return;
    }

    await _handleAuthSuccess(data, role);
  }

  String _toUpperRole(String role) => role.trim().toUpperCase();
  String _toLowerRole(String role) => role.trim().toLowerCase();

  bool _isVerifyEmailMessage(String message) {
    final m = message.toLowerCase();
    return m.contains('verify your email') ||
        m.contains('verify email') ||
        m.contains('email is not verified') ||
        m.contains('please verify') ||
        m.contains('not verified') ||
        // Matches the friendly Bengali translation from ErrorHandler.friendly
        m == ErrorHandler.verifyEmailFirst.toLowerCase() ||
        m.contains('ইমেইল যাচাই');
  }

  bool _isRegisterFirstMessage(String message) {
    final m = message.toLowerCase();
    return m.contains('register first') ||
        m.contains('not registered') ||
        // Matches the friendly Bengali translation from ErrorHandler.friendly
        m == ErrorHandler.friendly('register first').toLowerCase() ||
        m.contains('নিবন্ধন');
  }

  Future<void> logout() async {
    await _storage.clearSession();
    await _googleSignIn.signOut();
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
  return AuthNotifier(ref.watch(authRepositoryProvider), storage);
});
