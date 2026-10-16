// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please log in again.';

  @override
  String get errorBadRequest => 'Invalid information. Please try again.';

  @override
  String get errorSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errorForbidden => 'Permission denied.';

  @override
  String get errorNotFound => 'The requested information was not found.';

  @override
  String get errorEmailTaken => 'This email is already in use.';

  @override
  String get errorServerIssue =>
      'A server error occurred. Please try again in a few moments.';

  @override
  String get errorNetwork => 'Check your internet connection.';

  @override
  String get errorServerBusy =>
      'The server is starting up or temporarily busy. Please try again in 1–2 minutes.';

  @override
  String get errorDefault => 'Something went wrong. Please try again.';

  @override
  String get errorColdStart => 'The server is starting up, please wait...';

  @override
  String get errorInvalidLogin => 'Email or password is incorrect.';

  @override
  String get errorInvalidOtp => 'Wrong OTP. Please try again.';

  @override
  String get errorOtpExpired =>
      'The OTP has expired. Please request a new code.';

  @override
  String get errorOtpExceeded =>
      'Too many wrong attempts. The OTP was cancelled. Please request a new code.';

  @override
  String get errorResendCooldown =>
      'Please wait a moment before requesting another code.';

  @override
  String get errorVerifyPhoneFirst =>
      'Please verify your phone number before logging in.';

  @override
  String get errorVerifyEmailFirst =>
      'Please verify your email before logging in.';

  @override
  String get errorPhoneNotFound =>
      'No account exists for this phone number. Please register first.';

  @override
  String get errorAccountDeactivated =>
      'Your account is inactive. Please contact an administrator.';

  @override
  String get errorPhoneAlreadyUsed => 'This phone number is already in use.';

  @override
  String get errorAccountNotFound =>
      'Your account could not be found. Please register first.';

  @override
  String get homeStatActiveBuses => 'Active buses';

  @override
  String get homeStatTodayTrips => 'Today\'s trips';

  @override
  String get homeStatLiveTracking => 'Live tracking';

  @override
  String get homeStatUrgentNotice => 'Urgent notices';

  @override
  String get profileLanguage => 'Language';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get languageEnglish => 'English';
}
