import '../l10n/l10n.dart';

/// Maps backend failures and HTTP codes to user-friendly localized messages.
///
/// This class runs without a `BuildContext` (repositories, providers), so it
/// reads the active locale through `L10n.current` instead of `context.l10n`.
/// See `docs/localization.md`.
///
/// The getters below are also used as identity tokens in flow checks (OTP
/// expiry, "verify phone/email first", dead session). Because their text
/// changes with the language, those checks must go through [isOtpExpired] /
/// [isVerifyPhoneFirst] / [isVerifyEmailFirst] / [isSessionExpired], which
/// compare against *every* supported locale — never `==` or `contains` on
/// the message directly.
class ErrorHandler {
  static String getMessage(int? statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return L10n.current.errorBadRequest;
      case 401:
        return sessionExpired;
      case 403:
        return L10n.current.errorForbidden;
      case 404:
        return L10n.current.errorNotFound;
      case 409:
        return L10n.current.errorEmailTaken;
      case 502:
      case 503:
      case 504:
        return serverBusyMessage;
      case 500:
        return L10n.current.errorServerIssue;
      default:
        if (statusCode != null && statusCode >= 500) {
          return L10n.current.errorServerIssue;
        }
        return L10n.current.errorNetwork;
    }
  }

  static String get serverBusyMessage => L10n.current.errorServerBusy;
  static String get timeoutMessage => serverBusyMessage;
  static String get networkMessage => L10n.current.errorNetwork;
  static String get sessionExpired => L10n.current.errorSessionExpired;
  static String get defaultError => L10n.current.errorDefault;
  static String get coldStartMessage => L10n.current.errorColdStart;

  static String get invalidLogin => L10n.current.errorInvalidLogin;
  static String get invalidOtp => L10n.current.errorInvalidOtp;
  static String get otpExpired => L10n.current.errorOtpExpired;
  static String get otpExceeded => L10n.current.errorOtpExceeded;
  static String get resendCooldown => L10n.current.errorResendCooldown;
  static String get verifyPhoneFirst => L10n.current.errorVerifyPhoneFirst;
  static String get verifyEmailFirst => L10n.current.errorVerifyEmailFirst;
  static String get phoneNotFound => L10n.current.errorPhoneNotFound;
  static String get accountDeactivated =>
      L10n.current.errorAccountDeactivated;
  static String get phoneAlreadyUsed => L10n.current.errorPhoneAlreadyUsed;
  static String get accountNotFound => L10n.current.errorAccountNotFound;

  // ── Machine-readable error codes ────────────────────────────────────────
  //
  // The backend is single-language: it always answers in English and attaches
  // a stable `code` (see `ErrorCode.java`) to every error body. The app owns
  // the display language, so [fromCode] is the preferred resolution path —
  // it keys off the invariant code instead of brittle English wording.
  //
  // Resolution order for a response body is:
  //   1. localized message for `code`            → [fromCode]
  //   2. localized message for the raw English   → [friendly]
  //   3. HTTP-status fallback                    → [getMessage]

  /// Localizes the backend's machine-readable [code].
  ///
  /// Returns `null` when the code is unknown (a newer backend, or a code we
  /// deliberately don't surface), so callers can fall back to the English
  /// `message` via [resolve] / [friendly].
  static String? fromCode(String? code) {
    if (code == null) return null;
    final l10n = L10n.current;
    switch (code.trim().toUpperCase()) {
      // ---- Generic / transport ------------------------------------------
      case 'VALIDATION_FAILED':
      case 'BAD_REQUEST':
      case 'ROLE_REQUIRED':
      case 'INVALID_ROLE':
      case 'NAME_REQUIRED':
      case 'EMAIL_REQUIRED':
      case 'PASSWORD_REQUIRED':
      case 'PHONE_REQUIRED':
      case 'OTP_REQUIRED':
      case 'NEW_PASSWORD_REQUIRED':
      case 'DEPARTMENT_REQUIRED':
      case 'ROLL_NUMBER_REQUIRED':
      case 'SESSION_REQUIRED':
      case 'EMPLOYEE_ID_REQUIRED':
      case 'DESIGNATION_REQUIRED':
      case 'TEACHER_ID_REQUIRED':
        return l10n.errorValidation;
      case 'EMAIL_INVALID':
        return l10n.errorInvalidEmail;
      case 'PHONE_INVALID':
        return l10n.errorInvalidPhone;
      case 'OTP_INVALID_LENGTH':
        return l10n.errorOtpLength;
      case 'PASSWORD_TOO_SHORT':
        return l10n.errorPasswordLength;
      case 'EMAIL_DOMAIN_NOT_ALLOWED':
      case 'GOOGLE_EMAIL_NOT_ALLOWED':
        return l10n.errorEmailDomainNotAllowed;
      case 'UNAUTHORIZED':
        return l10n.errorUnauthorized;
      case 'FORBIDDEN':
        return l10n.errorForbidden;
      case 'NOT_FOUND':
      case 'RESOURCE_NOT_FOUND':
        return l10n.errorNotFound;
      case 'INTERNAL_ERROR':
        return l10n.errorServerIssue;

      // ---- Write-once academic fields -----------------------------------
      case 'DEPARTMENT_IMMUTABLE':
        return l10n.errorDepartmentImmutable;
      case 'ROLL_NUMBER_IMMUTABLE':
        return l10n.errorRollImmutable;
      case 'SESSION_IMMUTABLE':
        return l10n.errorSessionImmutable;
      case 'EMPLOYEE_ID_IMMUTABLE':
        return l10n.errorEmployeeIdImmutable;
      case 'DESIGNATION_IMMUTABLE':
        return l10n.errorDesignationImmutable;

      // ---- Uniqueness conflicts -----------------------------------------
      case 'PHONE_ALREADY_USED':
        return phoneAlreadyUsed;
      case 'ROLL_ALREADY_REGISTERED':
        return l10n.errorRollAlreadyRegistered;
      case 'TEACHER_ID_ALREADY_REGISTERED':
        return l10n.errorTeacherIdAlreadyRegistered;
      case 'EMAIL_ALREADY_EXISTS':
      case 'STUDENT_EMAIL_EXISTS':
      case 'EMPLOYEE_EMAIL_EXISTS':
        return l10n.errorEmailTaken;

      // ---- Account lookup / state ---------------------------------------
      case 'STUDENT_NOT_FOUND':
      case 'TEACHER_NOT_FOUND':
        return l10n.errorUserNotFound;
      case 'NO_STUDENT_WITH_PHONE':
      case 'NO_TEACHER_WITH_PHONE':
        return phoneNotFound;
      case 'NO_STUDENT_WITH_EMAIL':
      case 'NO_TEACHER_WITH_EMAIL':
        return accountNotFound;
      case 'ACCOUNT_DEACTIVATED':
        return accountDeactivated;
      case 'INVALID_CREDENTIALS':
        return invalidLogin;
      case 'CANNOT_DELETE_SELF':
        return l10n.errorCannotDeleteSelf;

      // ---- OTP lifecycle -------------------------------------------------
      case 'OTP_NOT_FOUND':
        return l10n.errorOtpNotFound;
      case 'OTP_EXPIRED':
        return otpExpired;
      case 'OTP_TOO_MANY_ATTEMPTS':
        return otpExceeded;
      case 'OTP_INVALID':
        return invalidOtp;
      case 'OTP_RESEND_COOLDOWN':
        return resendCooldown;

      // ---- Registration flow --------------------------------------------
      case 'REGISTRATION_NOT_FOUND':
        return l10n.errorRegistrationNotFound;
      case 'PENDING_REGISTRATION_NOT_FOUND':
        return l10n.errorPendingRegistrationNotFound;

      // ---- Google Sign-In -----------------------------------------------
      case 'GOOGLE_TOKEN_VERIFICATION_FAILED':
        return l10n.errorGoogleSignInFailed;
      case 'GOOGLE_TOKEN_INVALID':
        return l10n.errorGoogleTokenInvalid;
      case 'FACULTY_EMAIL_REQUIRED':
        return l10n.errorFacultyEmailRequired;
      case 'EMAIL_REGISTERED_AS_TEACHER':
        return l10n.errorEmailRegisteredAsTeacher;
      case 'EMAIL_REGISTERED_AS_STUDENT':
        return l10n.errorEmailRegisteredAsStudent;

      // ---- Profile completion -------------------------------------------
      case 'PROFILE_INCOMPLETE':
        return l10n.errorProfileIncomplete;
    }
    return null;
  }

  /// Full resolution pipeline for an error response body.
  ///
  /// [code] is the machine-readable `code` field (may be absent on older
  /// responses), [message] the backend's English text, [statusCode] the HTTP
  /// status used as the last-resort mapping.
  static String resolve({
    String? code,
    String? message,
    int? statusCode,
  }) {
    final byCode = fromCode(code);
    if (byCode != null) return byCode;
    if (message != null && message.trim().isNotEmpty) {
      return friendly(message);
    }
    return getMessage(statusCode, null);
  }

  /// Reads `code` / `message` out of a decoded error body (a JSON object)
  /// so callers don't have to re-implement the defensive map checks.
  static String resolveBody(Object? body, {int? statusCode}) {
    if (body is! Map) return getMessage(statusCode, null);
    final code = body['code'];
    final message = body['message'];
    return resolve(
      code: code is String ? code : null,
      message: message is String ? message : null,
      statusCode: statusCode,
    );
  }

  /// Localizes a **success** body's marker (the `code` field on
  /// `MessageResponse`, e.g. `OTP_SENT` / `PASSWORD_RESET_SUCCESS`).
  ///
  /// Returns `null` for unknown markers so callers keep the raw English text.
  static String? successFromCode(String? code) {
    if (code == null) return null;
    final l10n = L10n.current;
    switch (code.trim().toUpperCase()) {
      case 'OTP_SENT':
      case 'OTP_RESENT':
        return l10n.otpSent;
      case 'PASSWORD_RESET_SUCCESS':
        return l10n.successPasswordReset;
    }
    return null;
  }

  /// Localizes a Bean-Validation message that arrived in English.
  ///
  /// Field-level `errors` in a 400 body have no `code`, only the English text
  /// Spring produced from the DTO annotations. The set of possible strings is
  /// fixed (they live in the DTOs), so an exact-match table is reliable; any
  /// string we don't know about is returned untouched rather than hidden.
  static String field(String english) {
    final l10n = L10n.current;
    switch (english.trim()) {
      // ---- Generic -------------------------------------------------------
      case 'Select a role':
      case 'Role is required':
        return l10n.errorRoleRequired;
      case 'Name is required':
      case 'Full name is required':
        return l10n.validationNameRequired;
      case 'Name must be 2 to 100 characters':
      case 'Name must be at most 100 characters':
      case 'Name must be 100 characters or fewer':
        return l10n.validationNameLength;
      case 'Email is required':
        return l10n.validationEmailRequired;
      case 'Enter a valid email address':
      case 'Invalid email format':
        return l10n.validationEmailInvalid;
      case 'Password is required':
        return l10n.validationPasswordRequired;
      case 'Password must be at least 8 characters':
        return l10n.validationPasswordLength8;
      case 'Password must be 6 to 100 characters':
      case 'Password must be 6 to 128 characters':
      case 'Password must be at least 6 characters':
        return l10n.validationPasswordLength6;
      case 'Phone number is required':
        return l10n.validationPhoneRequired;
      case 'Enter a valid phone number':
        return l10n.validationPhoneInvalid;
      case 'OTP is required':
        return l10n.errorValidation;
      case 'OTP must be 6 digits':
        return l10n.errorOtpLength;
      case 'A new password is required':
        return l10n.validationPasswordRequired;

      // ---- Academic details ---------------------------------------------
      case 'Department is required':
      case 'Department/category is required':
        return l10n.validationDepartmentRequired;
      case 'Department must be 2 to 100 characters':
        return l10n.validationDepartmentLength;
      case 'Session is required':
        return l10n.validationSessionRequired;
      case 'Enter a valid session (e.g. 16, 2020, 2021-22, or 2020-2024)':
      case 'Enter a valid batch (e.g. 16, 2020, or 2020-2024)':
        return l10n.validationSessionFormat;
      case 'Roll number is required':
        return l10n.validationRollRequired;
      case 'Roll number must be 2-50 characters':
        return l10n.validationRollLength;
      case 'Employee ID is required':
        return l10n.validationEmployeeIdRequired;
      case 'Employee ID must be 2-50 characters':
        return l10n.validationEmployeeIdLength;
      case 'Designation is required':
        return l10n.validationDesignationRequired;
      case 'Designation must be at most 100 characters':
        return l10n.validationDesignationLength;
      case 'Teacher ID is required':
      case 'Student ID is required':
      case 'ID is required':
        return l10n.validationIdRequired;
      case 'Teacher ID must be 2-50 characters':
      case 'Student ID must be 2-50 characters':
        return l10n.validationEmployeeIdLength;
    }
    return english;
  }

  /// Localizes every value in a Spring `{"field": ["msg", ...]}` errors map.
  static Map<String, String> localizeFieldErrors(Map<dynamic, dynamic> errors) {
    final localized = <String, String>{};
    errors.forEach((key, value) {
      if (key is! String) return;
      if (value is List && value.isNotEmpty) {
        localized[key] = field(value.first.toString());
      } else if (value != null) {
        localized[key] = field(value.toString());
      }
    });
    return localized;
  }

  /// Backend codes that mean "your session is over" / "OTP is dead". Matched
  /// directly off the response `code`, so flow checks don't depend on the
  /// localized wording of the message at all.
  static const Set<String> sessionExpiredCodes = {'UNAUTHORIZED'};
  static const Set<String> otpExpiredCodes = {
    'OTP_EXPIRED',
    'OTP_NOT_FOUND',
    'OTP_TOO_MANY_ATTEMPTS',
  };
  static const Set<String> verifyEmailFirstCodes = {
    'NO_STUDENT_WITH_EMAIL',
    'NO_TEACHER_WITH_EMAIL',
  };
  static const Set<String> verifyPhoneFirstCodes = {
    'NO_STUDENT_WITH_PHONE',
    'NO_TEACHER_WITH_PHONE',
  };

  static bool isCodeIn(String? code, Set<String> codes) =>
      code != null && codes.contains(code.trim().toUpperCase());

  /// True when [message] is the "OTP expired" error in **any** supported
  /// language, or the backend's raw English wording. Safe after a mid-flight
  /// language switch, since the message was built in whatever locale was
  /// active at the time.
  ///
  /// Prefer matching on the response `code` via [isCodeIn] +
  /// [otpExpiredCodes] when the code is still in hand — it cannot drift with
  /// wording changes.
  static bool isOtpExpired(String message) {
    if (_matchesAnyLocale(message, (l10n) => l10n.errorOtpExpired)) {
      return true;
    }
    final m = message.toLowerCase();
    return m.contains('otp has expired') ||
        m.contains('otp expired') ||
        m.contains('otp is expired') ||
        m.contains('code has expired') ||
        // Legacy Bengali wording from older backend builds.
        m.contains('মেয়াদোত্তীর্ণ') ||
        m.contains('মেয়াদ শেষ');
  }

  /// See [isOtpExpired].
  static bool isVerifyPhoneFirst(String message) =>
      _matchesAnyLocale(message, (l10n) => l10n.errorVerifyPhoneFirst);

  /// See [isOtpExpired].
  static bool isVerifyEmailFirst(String message) =>
      _matchesAnyLocale(message, (l10n) => l10n.errorVerifyEmailFirst);

  /// True when [message] means "your session is over" in **any** supported
  /// language, including the backend's raw English wording. Complements the
  /// `==`-style [isOtpExpired] family with substring checks, because raw
  /// backend text varies in phrasing.
  static bool isSessionExpired(String message) {
    if (_matchesAnyLocale(message, (l10n) => l10n.errorSessionExpired) ||
        _matchesAnyLocale(message, (l10n) => l10n.sessionExpiredMessage)) {
      return true;
    }
    final m = message.toLowerCase();
    return m.contains('session expired') ||
        m.contains('session has expired') ||
        m.contains('session is expired') ||
        m.contains('unauthorized') ||
        // Legacy Bengali wording from older backend builds.
        m.contains('সেশন শেষ');
  }

  static bool _matchesAnyLocale(
    String message,
    String Function(AppLocalizations) localized,
  ) {
    final target = message.trim().toLowerCase();
    return AppLocalizations.supportedLocales.any(
      (locale) =>
          localized(lookupAppLocalizations(locale)).toLowerCase() == target,
    );
  }

  /// Converts backend English messages into friendly localized equivalents.
  /// Falls back to the raw message when no mapping exists.
  static String friendly(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid otp') ||
        m.contains('invalid verification code') ||
        m.contains('incorrect otp') ||
        m.contains('wrong otp')) {
      return invalidOtp;
    }
    if (m.contains('expired') || m.contains('has expired')) {
      return otpExpired;
    }
    if (m.contains('too many') || m.contains('attempts')) {
      return otpExceeded;
    }
    if (m.contains('resend') && m.contains('wait')) {
      return resendCooldown;
    }
    if (m.contains('verify your email') ||
        m.contains('email is not verified') ||
        m.contains('please verify')) {
      return verifyEmailFirst;
    }
    if (m.contains('verify your phone') ||
        m.contains('phone is not verified') ||
        m.contains('phone number not verified')) {
      return verifyPhoneFirst;
    }
    if (m.contains('not found with this email') || m.contains('email not found') || m.contains('user not found')) {
      return invalidLogin;
    }
    if (m.contains('not found with this phone') ||
        m.contains('no user found') ||
        m.contains('does not exist')) {
      return phoneNotFound;
    }
    if (m.contains('deactivated') || m.contains('account is inactive')) {
      return accountDeactivated;
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return phoneAlreadyUsed;
    }
    if (m.contains('invalid credentials') ||
        m.contains('wrong password') ||
        m.contains('invalid email or password')) {
      return invalidLogin;
    }
    if (m.contains('register first') || m.contains('not registered')) {
      return accountNotFound;
    }
    return message;
  }
}
