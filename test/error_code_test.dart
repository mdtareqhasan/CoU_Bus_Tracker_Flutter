import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cou_bus_tracker/core/error_handler.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// Every constant in the backend's `ErrorCode.java`.
///
/// The backend is single-language: it answers in English and attaches one of
/// these stable codes. This list is the wire contract — when a code is added
/// there, the "every backend code is localized" test below fails until the
/// app maps it, which is exactly the drift we want to catch.
const List<String> backendErrorCodes = [
  // Generic / transport
  'VALIDATION_FAILED',
  'BAD_REQUEST',
  'UNAUTHORIZED',
  'FORBIDDEN',
  'NOT_FOUND',
  'INTERNAL_ERROR',
  'RESOURCE_NOT_FOUND',
  // Field presence / format
  'ROLE_REQUIRED',
  'NAME_REQUIRED',
  'EMAIL_REQUIRED',
  'PASSWORD_REQUIRED',
  'PHONE_REQUIRED',
  'OTP_REQUIRED',
  'NEW_PASSWORD_REQUIRED',
  'DEPARTMENT_REQUIRED',
  'ROLL_NUMBER_REQUIRED',
  'SESSION_REQUIRED',
  'EMPLOYEE_ID_REQUIRED',
  'DESIGNATION_REQUIRED',
  'TEACHER_ID_REQUIRED',
  'EMAIL_INVALID',
  'PHONE_INVALID',
  'OTP_INVALID_LENGTH',
  'PASSWORD_TOO_SHORT',
  'EMAIL_DOMAIN_NOT_ALLOWED',
  'INVALID_ROLE',
  // Write-once academic fields
  'DEPARTMENT_IMMUTABLE',
  'ROLL_NUMBER_IMMUTABLE',
  'SESSION_IMMUTABLE',
  'EMPLOYEE_ID_IMMUTABLE',
  'DESIGNATION_IMMUTABLE',
  // Uniqueness conflicts
  'PHONE_ALREADY_USED',
  'ROLL_ALREADY_REGISTERED',
  'TEACHER_ID_ALREADY_REGISTERED',
  'EMAIL_ALREADY_EXISTS',
  'STUDENT_EMAIL_EXISTS',
  'EMPLOYEE_EMAIL_EXISTS',
  // Account lookup / state
  'STUDENT_NOT_FOUND',
  'TEACHER_NOT_FOUND',
  'NO_STUDENT_WITH_PHONE',
  'NO_TEACHER_WITH_PHONE',
  'NO_STUDENT_WITH_EMAIL',
  'NO_TEACHER_WITH_EMAIL',
  'ACCOUNT_DEACTIVATED',
  'INVALID_CREDENTIALS',
  'CANNOT_DELETE_SELF',
  // OTP lifecycle
  'OTP_NOT_FOUND',
  'OTP_EXPIRED',
  'OTP_TOO_MANY_ATTEMPTS',
  'OTP_INVALID',
  'OTP_RESEND_COOLDOWN',
  // Registration flow
  'REGISTRATION_NOT_FOUND',
  'PENDING_REGISTRATION_NOT_FOUND',
  // Google Sign-In
  'GOOGLE_TOKEN_VERIFICATION_FAILED',
  'GOOGLE_TOKEN_INVALID',
  'GOOGLE_EMAIL_NOT_ALLOWED',
  'FACULTY_EMAIL_REQUIRED',
  'EMAIL_REGISTERED_AS_TEACHER',
  'EMAIL_REGISTERED_AS_STUDENT',
  // Profile completion
  'PROFILE_INCOMPLETE',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandler.fromCode', () {
    test('every backend code is localized in bn and en', () {
      for (final locale in AppLocalizations.supportedLocales) {
        // fromCode reads L10n.current, so activate each locale in turn.
        L10n.activate(locale);

        final resolved = <String, String>{};
        for (final code in backendErrorCodes) {
          final message = ErrorHandler.fromCode(code);
          expect(
            message,
            isNotNull,
            reason: 'backend code "$code" has no localized message in $locale',
          );
          expect(
            message!.trim(),
            isNotEmpty,
            reason: 'backend code "$code" resolved to empty text in $locale',
          );
          resolved[code] = message;
        }
        // Codes deliberately share copy (every `*_REQUIRED` → errorValidation),
        // so this is not a 1:1 check — it just catches the degenerate case
        // where a refactor collapses everything onto one string.
        expect(
          resolved.values.toSet().length,
          greaterThanOrEqualTo(30),
          reason:
              'codes collapsed onto too few messages in $locale — '
              'distinct failures should read distinctly',
        );
      }
    });

    test('bn copy is actually translated, not the English string reused', () {
      final bn = lookupAppLocalizations(const Locale('bn'));
      final en = lookupAppLocalizations(const Locale('en'));
      final same = <String>[];
      for (final code in backendErrorCodes) {
        L10n.activate(const Locale('bn'));
        final bnText = ErrorHandler.fromCode(code);
        L10n.activate(const Locale('en'));
        final enText = ErrorHandler.fromCode(code);
        if (bnText == enText) same.add(code);
      }
      expect(
        same,
        isEmpty,
        reason:
            'these codes show identical text in both locales: $same '
            '(bn=${bn.errorValidation}, en=${en.errorValidation})',
      );
    });

    test('is case- and whitespace-insensitive, and null-safe', () {
      L10n.activate(const Locale('en'));
      final expected = ErrorHandler.fromCode('OTP_EXPIRED');
      expect(ErrorHandler.fromCode('  otp_expired '), expected);
      expect(ErrorHandler.fromCode(null), isNull);
    });

    test('an unknown code returns null so callers can fall back', () {
      expect(ErrorHandler.fromCode('SOME_FUTURE_CODE'), isNull);
      expect(ErrorHandler.fromCode(''), isNull);
    });
  });

  group('ErrorHandler.resolve', () {
    tearDown(() => L10n.activate(const Locale('en')));

    test('prefers the code over the English message', () {
      L10n.activate(const Locale('en'));
      final resolved = ErrorHandler.resolve(
        code: 'OTP_EXPIRED',
        message: 'The OTP has expired. Please request a new one',
        statusCode: 400,
      );
      expect(
        resolved,
        lookupAppLocalizations(const Locale('en')).errorOtpExpired,
      );
    });

    test('falls back to the English message when the code is unknown', () {
      L10n.activate(const Locale('en'));
      expect(
        ErrorHandler.resolve(
          code: 'SOME_FUTURE_CODE',
          message: 'weird backend text',
          statusCode: 400,
        ),
        'weird backend text',
      );
    });

    test('falls back to the HTTP status when there is no body at all', () {
      L10n.activate(const Locale('en'));
      expect(
        ErrorHandler.resolve(statusCode: 503),
        ErrorHandler.serverBusyMessage,
      );
      expect(ErrorHandler.resolve(), ErrorHandler.networkMessage);
    });
  });

  group('ErrorHandler.field', () {
    tearDown(() => L10n.activate(const Locale('bn')));

    test('localizes known Bean-Validation copy in both locales', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        L10n.activate(locale);

        expect(
          ErrorHandler.field('Name is required'),
          l10n.validationNameRequired,
        );
        expect(
          ErrorHandler.field('Enter a valid email address'),
          l10n.validationEmailInvalid,
        );
        expect(
          ErrorHandler.field('Password must be 6 to 128 characters'),
          l10n.validationPasswordLength6,
        );
        expect(
          ErrorHandler.field('Roll number is required'),
          l10n.validationRollRequired,
        );
      }
    });

    test('passes unrecognized copy through instead of hiding it', () {
      L10n.activate(const Locale('en'));
      expect(ErrorHandler.field('Something brand new'), 'Something brand new');
    });
  });

  group('ErrorHandler.isCodeIn', () {
    test('matches the OTP-lifecycle codes', () {
      expect(
        ErrorHandler.isCodeIn('OTP_EXPIRED', ErrorHandler.otpExpiredCodes),
        isTrue,
      );
      expect(
        ErrorHandler.isCodeIn('OTP_NOT_FOUND', ErrorHandler.otpExpiredCodes),
        isTrue,
      );
      expect(
        ErrorHandler.isCodeIn('otp_expired', ErrorHandler.otpExpiredCodes),
        isTrue,
        reason: 'must be case-insensitive',
      );
      expect(
        ErrorHandler.isCodeIn(
          'INVALID_CREDENTIALS',
          ErrorHandler.otpExpiredCodes,
        ),
        isFalse,
      );
      expect(
        ErrorHandler.isCodeIn(null, ErrorHandler.otpExpiredCodes),
        isFalse,
      );
      expect(ErrorHandler.isCodeIn('', ErrorHandler.otpExpiredCodes), isFalse);
    });

    test('session / verify-first code sets are disjoint and non-empty', () {
      expect(ErrorHandler.sessionExpiredCodes, isNotEmpty);
      expect(ErrorHandler.verifyEmailFirstCodes, isNotEmpty);
      expect(ErrorHandler.verifyPhoneFirstCodes, isNotEmpty);
      final overlap = ErrorHandler.verifyEmailFirstCodes.intersection(
        ErrorHandler.verifyPhoneFirstCodes,
      );
      expect(overlap, isEmpty);
    });
  });

  group('isOtpExpired / isSessionExpired against raw backend English', () {
    tearDown(() => L10n.activate(const Locale('bn')));

    test('recognize the backend English wording, not just our own copy', () {
      L10n.activate(const Locale('en'));
      // These are the exact strings ErrorCode.java ships; the flow checks must
      // fire on them without depending on the app's own phrasing.
      expect(
        ErrorHandler.isOtpExpired(
          'The OTP has expired. Please request a new one',
        ),
        isTrue,
      );
      expect(ErrorHandler.isSessionExpired('Unauthorized'), isTrue);

      // Negative cases stay negative.
      expect(ErrorHandler.isOtpExpired('Wrong OTP. Please try again'), isFalse);
      expect(ErrorHandler.isSessionExpired('Permission denied'), isFalse);
    });
  });

  group('success codes', () {
    tearDown(() => L10n.activate(const Locale('bn')));

    test('map to localized copy and tolerate unknown markers', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        L10n.activate(locale);
        expect(ErrorHandler.successFromCode('OTP_SENT'), l10n.otpSent);
        expect(ErrorHandler.successFromCode('OTP_RESENT'), l10n.otpSent);
        expect(
          ErrorHandler.successFromCode('PASSWORD_RESET_SUCCESS'),
          l10n.successPasswordReset,
        );
        expect(ErrorHandler.successFromCode('SOMETHING_ELSE'), isNull);
        expect(ErrorHandler.successFromCode(null), isNull);
      }
    });
  });
}
