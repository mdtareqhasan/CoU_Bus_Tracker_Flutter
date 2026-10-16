import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// Snackbar shown when the auth session expires (401/403) and the user is sent back to login.
  ///
  /// In bn, this message translates to:
  /// **'আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার লগইন করুন।'**
  String get sessionExpiredMessage;

  /// HTTP 400 — server rejected the submitted data.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য সঠিক নয়। আবার চেষ্টা করুন।'**
  String get errorBadRequest;

  /// HTTP 401 — session is gone, user must sign in again.
  ///
  /// In bn, this message translates to:
  /// **'সেশন শেষ হয়েছে। আবার সাইন ইন করুন।'**
  String get errorSessionExpired;

  /// HTTP 403 — the account is not allowed to do this.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি নেই।'**
  String get errorForbidden;

  /// HTTP 404 — requested record does not exist.
  ///
  /// In bn, this message translates to:
  /// **'তথ্যটি পাওয়া যায়নি।'**
  String get errorNotFound;

  /// HTTP 409 — the email is already registered.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।'**
  String get errorEmailTaken;

  /// HTTP 500 and any other 5xx — generic server fault.
  ///
  /// In bn, this message translates to:
  /// **'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।'**
  String get errorServerIssue;

  /// No status code at all — request never reached the server.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ পরীক্ষা করুন।'**
  String get errorNetwork;

  /// HTTP 502/503/504 and timeouts — server starting or busy; says to retry after 1–2 minutes.
  ///
  /// In bn, this message translates to:
  /// **'সার্ভার চালু হচ্ছে বা সাময়িকভাবে ব্যস্ত। ১–২ মিনিট পরে আবার চেষ্টা করুন।'**
  String get errorServerBusy;

  /// Fallback when nothing else matched.
  ///
  /// In bn, this message translates to:
  /// **'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।'**
  String get errorDefault;

  /// Shown while the backend is waking up on first request.
  ///
  /// In bn, this message translates to:
  /// **'সার্ভার চালু হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...'**
  String get errorColdStart;

  /// Wrong email/password combination.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল অথবা পাসওয়ার্ড সঠিক নয়।'**
  String get errorInvalidLogin;

  /// The entered OTP code does not match.
  ///
  /// In bn, this message translates to:
  /// **'ভুল ওটিপি। আবার চেষ্টা করুন।'**
  String get errorInvalidOtp;

  /// The OTP is too old; a new one was already sent. Triggers the auto-resend in the OTP screens.
  ///
  /// In bn, this message translates to:
  /// **'ওটিপির মেয়াদ শেষ হয়ে গেছে। আবার কোড পাঠান।'**
  String get errorOtpExpired;

  /// Too many wrong OTP attempts; the code is now void.
  ///
  /// In bn, this message translates to:
  /// **'অনেকবার ভুল চেষ্টা। ওটিপি বাতিল হয়েছে। আবার কোড পাঠান।'**
  String get errorOtpExceeded;

  /// Resend was requested too soon; wait for the countdown.
  ///
  /// In bn, this message translates to:
  /// **'আবার কোড পাঠাতে একটু অপেক্ষা করুন।'**
  String get errorResendCooldown;

  /// Login blocked because the phone number has no verified OTP yet.
  ///
  /// In bn, this message translates to:
  /// **'অনুগ্রহ করে লগইন করার আগে আপনার ফোন নম্বর যাচাই করুন।'**
  String get errorVerifyPhoneFirst;

  /// Login blocked because the email address is not verified yet.
  ///
  /// In bn, this message translates to:
  /// **'অনুগ্রহ করে লগইন করার আগে আপনার ইমেইল যাচাই করুন।'**
  String get errorVerifyEmailFirst;

  /// No account exists for that phone number.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোন নম্বরে কোনো ব্যবহারকারী নেই। প্রথমে নিবন্ধন করুন।'**
  String get errorPhoneNotFound;

  /// Account was disabled by an admin.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অ্যাকাউন্ট নিষ্ক্রিয়। অ্যাডমিনের সাথে যোগাযোগ করুন।'**
  String get errorAccountDeactivated;

  /// Registration attempted with a phone number that is taken.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোন নম্বর ইতিমধ্যে ব্যবহৃত হয়েছে।'**
  String get errorPhoneAlreadyUsed;

  /// Login attempted for an account that was never registered.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অ্যাকাউন্ট পাওয়া যায়নি। আগে নিবন্ধন করুন।'**
  String get errorAccountNotFound;

  /// Home stats card — number of buses running right now.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয় বাস'**
  String get homeStatActiveBuses;

  /// Home stats card — trips scheduled for today.
  ///
  /// In bn, this message translates to:
  /// **'আজকের ট্রিপ'**
  String get homeStatTodayTrips;

  /// Home stats card — link to live tracking.
  ///
  /// In bn, this message translates to:
  /// **'লাইভ ট্র্যাকিং'**
  String get homeStatLiveTracking;

  /// Home stats card — number of active urgent notices.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি নোটিশ'**
  String get homeStatUrgentNotice;

  /// Profile — header of the language selection card.
  ///
  /// In bn, this message translates to:
  /// **'ভাষা'**
  String get profileLanguage;

  /// Language option; always written in Bengali script, in every locale.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// Language option; always written in English, in every locale.
  ///
  /// In bn, this message translates to:
  /// **'English'**
  String get languageEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
