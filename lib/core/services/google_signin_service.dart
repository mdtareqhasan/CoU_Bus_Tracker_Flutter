import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';

/// Thin wrapper around the `google_sign_in` plugin (v7 API).
///
/// Responsibilities:
///  * call `GoogleSignIn.instance.initialize` exactly once, and
///  * run the interactive sign-in flow and return the OAuth **ID token** that
///    the backend verifies.
///
/// The ID token is never logged.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    // initialize() must be called exactly once; cache the future so concurrent
    // callers share the same initialization.
    return _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: kGoogleServerClientId,
    );
  }

  /// Runs the interactive Google sign-in flow.
  ///
  /// Returns the ID token on success, or `null` when the user dismissed the
  /// account picker. Throws [GoogleSignInException] for any other failure.
  Future<String?> signIn() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Google did not return an ID token.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      if (kDebugMode) {
        debugPrint(
          '[GOOGLE][SIGNIN] code=${e.code} description=${e.description}',
        );
      }
      rethrow;
    }
  }

  /// Clears the cached Google session so the next sign-in shows the picker.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort; ignore errors during sign-out.
    }
  }
}
