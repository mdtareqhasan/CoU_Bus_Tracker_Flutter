import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../core/error_handler.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/models/auth_response.dart';
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
    );
  }

  bool get isLoggedIn =>
      status == AuthStateStatus.authenticated && displayName != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final StorageService _storage;

  AuthNotifier(this._authRepo, this._storage) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      // No token yet: restore a pending OTP verification session if present.
      final pendingPhone = await _storage.getPendingPhone();
      if (pendingPhone != null) {
        final pendingRole = await _storage.getPendingRole();
        state = state.copyWith(
          status: AuthStateStatus.needsVerification,
          phone: pendingPhone,
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
    // Fetch profile to get idCardImageUrl
    String? idCardImageUrl;
    try {
      final endpoint = role == 'teacher'
          ? '/auth/teacher/me'
          : '/auth/student/me';
      final response = await _authRepo._apiClient.dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data is Map) {
        idCardImageUrl = response.data['idCardImageUrl'] as String?;
      }
    } catch (_) {
      // Ignore profile fetch errors
    }

    state = state.copyWith(
      status: AuthStateStatus.authenticated,
      role: _storage.getRole(),
      displayName: _storage.getDisplayName(),
      email: _storage.getUserEmail(),
      phone: _storage.getUserPhone(),
      userId: _storage.getUserId(),
      isVerified: _storage.isVerified(),
      isEduMail: _storage.isEduMail(),
      idCardImageUrl: idCardImageUrl,
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

    // Fetch profile to get idCardImageUrl
    String? idCardImageUrl;
    try {
      final endpoint = (data.role?.toLowerCase() ?? role) == 'teacher'
          ? '/auth/teacher/me'
          : '/auth/student/me';
      final response = await _authRepo._apiClient.dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data is Map) {
        idCardImageUrl = response.data['idCardImageUrl'] as String?;
      }
    } catch (_) {
      // Ignore profile fetch errors - idCardImageUrl will be null
    }

    state = state.copyWith(
      status: AuthStateStatus.authenticated,
      role: data.role?.toLowerCase() ?? role,
      displayName: data.name ?? 'User',
      email: data.email ?? '',
      phone: phone,
      userId: data.id,
      isVerified: data.isVerified ?? false,
      isEduMail: data.isEduMail ?? false,
      pendingRole: null,
      idCardImageUrl: idCardImageUrl,
    );
  }

  String _toUpperRole(String role) => role.trim().toUpperCase();
  String _toLowerRole(String role) => role.trim().toLowerCase();

  bool _isVerifyPhoneMessage(String message) {
    final m = message.toLowerCase();
    return m.contains('verify your phone') ||
        m.contains('phone is not verified') ||
        m.contains('phone number not verified') ||
        m.contains('not verified') ||
        m == ErrorHandler.verifyEmailFirst.toLowerCase() ||
        m == ErrorHandler.verifyPhoneFirst.toLowerCase() ||
        m.contains('ফোন যাচাই') ||
        m.contains('ইমেইল যাচাই');
  }

  Future<void> logout() async {
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
  return AuthNotifier(ref.watch(authRepositoryProvider), storage);
});
