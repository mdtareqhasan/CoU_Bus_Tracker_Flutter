import '../l10n/l10n.dart';

/// Maps backend failures and HTTP codes to user-friendly localized messages.
///
/// This class runs without a `BuildContext` (repositories, providers), so it
/// reads the active locale through `L10n.current` instead of `context.l10n`.
/// See `docs/localization.md`.
///
/// The getters below are also used as identity tokens in flow checks (OTP
/// expiry, "verify phone/email first"). Because their text changes with the
/// language, those checks must go through [isOtpExpired] /
/// [isVerifyPhoneFirst] / [isVerifyEmailFirst], which compare against *every*
/// supported locale — never `==` or `contains` on the message directly.
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

  /// True when [message] is the "OTP expired" error in **any** supported
  /// language. Safe after a mid-flight language switch, since the message was
  /// built in whatever locale was active at the time.
  static bool isOtpExpired(String message) =>
      _matchesAnyLocale(message, (l10n) => l10n.errorOtpExpired);

  /// See [isOtpExpired].
  static bool isVerifyPhoneFirst(String message) =>
      _matchesAnyLocale(message, (l10n) => l10n.errorVerifyPhoneFirst);

  /// See [isOtpExpired].
  static bool isVerifyEmailFirst(String message) =>
      _matchesAnyLocale(message, (l10n) => l10n.errorVerifyEmailFirst);

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
