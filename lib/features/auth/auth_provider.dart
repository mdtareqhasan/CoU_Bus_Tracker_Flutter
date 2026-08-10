import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/storage_service.dart';
import '../../shared/models/student.dart';
import '../../shared/models/login_request.dart';
import '../../shared/models/student_register_request.dart';
import '../../shared/models/teacher_register_request.dart';
import 'auth_repository.dart';
import '../providers.dart';

enum AuthStateStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStateStatus status;
  final String? role;
  final String? displayName;
  final String? email;
  final Student? studentProfile;
  final String? error;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.role,
    this.displayName,
    this.email,
    this.studentProfile,
    this.error,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? role,
    String? displayName,
    String? email,
    Student? studentProfile,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      studentProfile: studentProfile ?? this.studentProfile,
      error: error,
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
    if (hasToken) {
      state = state.copyWith(
        status: AuthStateStatus.authenticated,
        role: _storage.getRole(),
        displayName: _storage.getDisplayName(),
        email: _storage.getUserEmail(),
      );
    } else {
      state = state.copyWith(status: AuthStateStatus.unauthenticated);
    }
  }

  Future<void> studentLogin(String email, String password) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    final result = await _authRepo.studentLogin(LoginRequest(
      email: email,
      password: password,
    ));

    switch (result) {
      case Success(:final data):
        await _storage.saveSession(
          token: data.accessToken!,
          role: 'student',
          name: data.userDisplayName,
          email: email,
        );
        state = state.copyWith(
          status: AuthStateStatus.authenticated,
          role: 'student',
          displayName: data.userDisplayName,
          email: email,
        );
      case Failure(:final message):
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: message,
        );
      default:
        break;
    }
  }

  Future<void> teacherLogin(String email, String password) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    final result = await _authRepo.teacherLogin(LoginRequest(
      email: email,
      password: password,
    ));

    switch (result) {
      case Success(:final data):
        await _storage.saveSession(
          token: data.accessToken!,
          role: 'teacher',
          name: data.userDisplayName,
          email: email,
        );
        state = state.copyWith(
          status: AuthStateStatus.authenticated,
          role: 'teacher',
          displayName: data.userDisplayName,
          email: email,
        );
      case Failure(:final message):
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: message,
        );
      default:
        break;
    }
  }

  Future<void> studentRegister(StudentRegisterRequest request) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    final result = await _authRepo.studentRegister(request);

    switch (result) {
      case Success(:final data):
        await _storage.saveSession(
          token: data.accessToken!,
          role: 'student',
          name: data.userDisplayName,
          email: request.email,
        );
        state = state.copyWith(
          status: AuthStateStatus.authenticated,
          role: 'student',
          displayName: data.userDisplayName,
          email: request.email,
        );
      case Failure(:final message):
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: message,
        );
      default:
        break;
    }
  }

  Future<void> teacherRegister(TeacherRegisterRequest request) async {
    state = state.copyWith(status: AuthStateStatus.loading, error: null);

    final result = await _authRepo.teacherRegister(request);

    switch (result) {
      case Success(:final data):
        await _storage.saveSession(
          token: data.accessToken!,
          role: 'teacher',
          name: data.userDisplayName,
          email: request.email,
        );
        state = state.copyWith(
          status: AuthStateStatus.authenticated,
          role: 'teacher',
          displayName: data.userDisplayName,
          email: request.email,
        );
      case Failure(:final message):
        state = state.copyWith(
          status: AuthStateStatus.error,
          error: message,
        );
      default:
        break;
    }
  }

  Future<void> loadProfile() async {
    if (!await _storage.hasToken()) return;

    final result = await _authRepo.getStudentProfile();
    if (result case Success(:final data)) {
      state = state.copyWith(studentProfile: data);
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState(status: AuthStateStatus.unauthenticated);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    storage,
  );
});
