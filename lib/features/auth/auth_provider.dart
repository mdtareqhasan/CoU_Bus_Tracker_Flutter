import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../shared/models/auth_response.dart';
import '../../shared/models/login_request.dart';
import 'auth_repository.dart';
import '../providers.dart';

enum AuthStateStatus { initial, loading, authenticated, unauthenticated, error, needsRegistration }

class AuthState {
  final AuthStateStatus status;
  final String? role;
  final String? displayName;
  final String? email;
  final int? userId;
  final bool isVerified;
  final bool isEduMail;
  final String? error;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.role,
    this.displayName,
    this.email,
    this.userId,
    this.isVerified = false,
    this.isEduMail = false,
    this.error,
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
    );
  }

  bool get isLoggedIn =>
      status == AuthStateStatus.authenticated && displayName != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final StorageService _storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '111634412431-th7l3d7cqtmrpqhrn16hvs55j2f6f9qa.apps.googleusercontent.com',
  );

  AuthNotifier(this._authRepo, this._storage) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasToken = await _storage.hasToken();
    if (hasToken) {
      state = state.copyWith(
        status: AuthStateStatus.authenticated,
        role: _storage.getRole(),
        displayName: _storage.getDisplayName(),
        email: _storage.getUserEmail(),
        userId: _storage.getUserId(),
        isVerified: _storage.isVerified(),
        isEduMail: _storage.isEduMail(),
      );
    } else {
      state = state.copyWith(status: AuthStateStatus.unauthenticated);
    }
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
        state = state.copyWith(status: AuthStateStatus.error, error: 'Google ID Token not found');
        return;
      }

      final result = await _authRepo.googleLogin(idToken, role);

      switch (result) {
        case Success(:final data):
          await _handleAuthSuccess(data, role.toLowerCase());
        case Failure(:final message):
          if (message.contains('register first')) {
            state = state.copyWith(
              status: AuthStateStatus.needsRegistration,
              email: account.email,
              displayName: account.displayName,
              error: message,
            );
          } else {
            state = state.copyWith(status: AuthStateStatus.error, error: message);
          }
        default:
          state = state.copyWith(status: AuthStateStatus.error, error: 'Unknown response');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStateStatus.error, error: e.toString());
    }
  }

  Future<void> login({required String email, required String password, required String role}) async {
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
        state = state.copyWith(status: AuthStateStatus.error, error: message);
      default:
        state = state.copyWith(status: AuthStateStatus.error, error: 'Unknown response');
    }
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
        await _handleAuthSuccess(data, 'student');
      case Failure(:final message):
        state = state.copyWith(status: AuthStateStatus.error, error: message);
      default:
        state = state.copyWith(status: AuthStateStatus.error, error: 'Unknown response');
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
        await _handleAuthSuccess(data, 'teacher');
      case Failure(:final message):
        state = state.copyWith(status: AuthStateStatus.error, error: message);
      default:
        state = state.copyWith(status: AuthStateStatus.error, error: 'Unknown response');
    }
  }

  Future<void> _handleAuthSuccess(AuthResponse data, String role) async {
    await _storage.saveSession(
      token: data.accessToken!,
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

  Future<void> logout() async {
    await _storage.clearSession();
    await _googleSignIn.signOut();
    state = const AuthState(status: AuthStateStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(ref.watch(authRepositoryProvider), storage);
});
