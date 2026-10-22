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

  /// যাচাই ব্যর্থ হয়েছে
  ///
  /// In bn, this message translates to:
  /// **'আপনার তথ্য যাচাই করে আবার চেষ্টা করুন।'**
  String get errorValidation;

  /// Backend code EMAIL_INVALID — malformed email address.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল ঠিকানা লিখুন।'**
  String get errorInvalidEmail;

  /// Backend code PHONE_INVALID — malformed phone number.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ফোন নম্বর লিখুন।'**
  String get errorInvalidPhone;

  /// Backend code OTP_INVALID_LENGTH.
  ///
  /// In bn, this message translates to:
  /// **'ওটিপি ৬ সংখ্যার হতে হবে।'**
  String get errorOtpLength;

  /// Backend code PASSWORD_TOO_SHORT.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।'**
  String get errorPasswordLength;

  /// Backend code ROLE_REQUIRED / INVALID_ROLE.
  ///
  /// In bn, this message translates to:
  /// **'অনুগ্রহ করে আপনার ভূমিকা নির্বাচন করুন।'**
  String get errorRoleRequired;

  /// Backend code UNAUTHORIZED.
  ///
  /// In bn, this message translates to:
  /// **'এই কাজটি করার অনুমতি আপনার নেই।'**
  String get errorUnauthorized;

  /// Backend code STUDENT_NOT_FOUND / TEACHER_NOT_FOUND.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট পাওয়া যায়নি।'**
  String get errorUserNotFound;

  /// Backend code ROLL_ALREADY_REGISTERED.
  ///
  /// In bn, this message translates to:
  /// **'এই রোল নম্বর ইতিমধ্যে নিবন্ধিত।'**
  String get errorRollAlreadyRegistered;

  /// Backend code TEACHER_ID_ALREADY_REGISTERED.
  ///
  /// In bn, this message translates to:
  /// **'এই শিক্ষক আইডি ইতিমধ্যে নিবন্ধিত।'**
  String get errorTeacherIdAlreadyRegistered;

  /// Backend code DEPARTMENT_IMMUTABLE.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।'**
  String get errorDepartmentImmutable;

  /// Backend code ROLL_NUMBER_IMMUTABLE.
  ///
  /// In bn, this message translates to:
  /// **'রোল নম্বর একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।'**
  String get errorRollImmutable;

  /// Backend code SESSION_IMMUTABLE.
  ///
  /// In bn, this message translates to:
  /// **'সেশন একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।'**
  String get errorSessionImmutable;

  /// Backend code EMPLOYEE_ID_IMMUTABLE.
  ///
  /// In bn, this message translates to:
  /// **'কর্মী আইডি একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।'**
  String get errorEmployeeIdImmutable;

  /// Backend code DESIGNATION_IMMUTABLE.
  ///
  /// In bn, this message translates to:
  /// **'পদবি একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।'**
  String get errorDesignationImmutable;

  /// Backend code EMAIL_DOMAIN_NOT_ALLOWED / GOOGLE_EMAIL_NOT_ALLOWED.
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র কুমিল্লা বিশ্ববিদ্যালয়ের অফিসিয়াল ইমেইল গ্রহণযোগ্য।'**
  String get errorEmailDomainNotAllowed;

  /// Backend code GOOGLE_TOKEN_VERIFICATION_FAILED.
  ///
  /// In bn, this message translates to:
  /// **'গুগল সাইন ইন যাচাই করা যায়নি। আবার চেষ্টা করুন।'**
  String get errorGoogleSignInFailed;

  /// Backend code GOOGLE_TOKEN_INVALID.
  ///
  /// In bn, this message translates to:
  /// **'গুগল সাইন ইন টোকেন অবৈধ অথবা ইমেইল যাচাই করা হয়নি।'**
  String get errorGoogleTokenInvalid;

  /// Backend code FACULTY_EMAIL_REQUIRED — teacher sign-in used a student email.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক হিসেবে সাইন ইন করতে স্টাফ ইমেইল (name@cou.ac.bd) ব্যবহার করুন।'**
  String get errorFacultyEmailRequired;

  /// Backend code EMAIL_REGISTERED_AS_TEACHER — the email already belongs to a teacher account, so student sign-in is refused.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইলটি ইতিমধ্যে শিক্ষক হিসেবে নিবন্ধিত। শিক্ষক হিসেবে সাইন ইন করুন।'**
  String get errorEmailRegisteredAsTeacher;

  /// Backend code EMAIL_REGISTERED_AS_STUDENT — the email already belongs to a student account, so teacher sign-in is refused.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইলটি ইতিমধ্যে শিক্ষ্যার্থী হিসেবে নিবন্ধিত। শিক্ষ্যার্থী হিসেবে সাইন ইন করুন।'**
  String get errorEmailRegisteredAsStudent;

  /// Backend code CANNOT_DELETE_SELF.
  ///
  /// In bn, this message translates to:
  /// **'আপনি নিজের অ্যাকাউন্ট মুছতে পারবেন না।'**
  String get errorCannotDeleteSelf;

  /// Backend code OTP_NOT_FOUND.
  ///
  /// In bn, this message translates to:
  /// **'কোনো ওটিপি পাওয়া যায়নি। নতুন কোড অনুরোধ করুন।'**
  String get errorOtpNotFound;

  /// Backend code REGISTRATION_NOT_FOUND.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন পাওয়া যায়নি। প্রথমে নিবন্ধন ফর্ম জমা দিন।'**
  String get errorRegistrationNotFound;

  /// Backend code PENDING_REGISTRATION_NOT_FOUND.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোন নম্বরে কোনো অপেক্ষমাণ নিবন্ধন নেই। প্রথমে নিবন্ধন ফর্ম জমা দিন।'**
  String get errorPendingRegistrationNotFound;

  /// Backend code PROFILE_INCOMPLETE.
  ///
  /// In bn, this message translates to:
  /// **'চালিয়ে যেতে অনুগ্রহ করে আপনার প্রোফাইল সম্পূর্ণ করুন।'**
  String get errorProfileIncomplete;

  /// Success code PASSWORD_RESET_SUCCESS on a 200 body.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। নতুন পাসওয়ার্ড দিয়ে লগইন করুন।'**
  String get successPasswordReset;

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

  /// Bottom navigation — home tab.
  ///
  /// In bn, this message translates to:
  /// **'হোম'**
  String get navHome;

  /// Bottom navigation — route tab.
  ///
  /// In bn, this message translates to:
  /// **'রুট'**
  String get navRoute;

  /// Bottom navigation — bus list tab.
  ///
  /// In bn, this message translates to:
  /// **'বাস'**
  String get navBuses;

  /// Bottom navigation — schedules tab.
  ///
  /// In bn, this message translates to:
  /// **'সময়সূচি'**
  String get navSchedules;

  /// Bottom navigation — notices tab.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get navNotices;

  /// Bottom navigation — profile tab.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল'**
  String get navProfile;

  /// Confirmation dialog — affirmative.
  ///
  /// In bn, this message translates to:
  /// **'হ্যাঁ'**
  String get commonYes;

  /// Confirmation dialog — negative.
  ///
  /// In bn, this message translates to:
  /// **'না'**
  String get commonNo;

  /// Fallback display name when a user has none.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী'**
  String get commonUserName;

  /// Title of the leave-the-app confirmation.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ থেকে বের হতে চান?'**
  String get exitAppTitle;

  /// Body of the leave-the-app confirmation.
  ///
  /// In bn, this message translates to:
  /// **'আপনি কি নিশ্চিতভাবে অ্যাপ বন্ধ করতে চান?'**
  String get exitAppMessage;

  /// Shown where a time is missing.
  ///
  /// In bn, this message translates to:
  /// **'নির্ধারিত নয়'**
  String get timeNotScheduled;

  /// Schedule time period, 05:00–11:59.
  ///
  /// In bn, this message translates to:
  /// **'সকাল'**
  String get timeMorning;

  /// Schedule time period, 12:00–14:59.
  ///
  /// In bn, this message translates to:
  /// **'দুপুর'**
  String get timeAfternoon;

  /// Schedule time period, 15:00–17:59.
  ///
  /// In bn, this message translates to:
  /// **'বিকাল'**
  String get timeEvening;

  /// Schedule time period, 18:00–04:59.
  ///
  /// In bn, this message translates to:
  /// **'রাত'**
  String get timeNight;

  /// Bus category badge.
  ///
  /// In bn, this message translates to:
  /// **'নীল'**
  String get busCategoryBlue;

  /// Bus category badge.
  ///
  /// In bn, this message translates to:
  /// **'লাল'**
  String get busCategoryRed;

  /// Bus category badge.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক'**
  String get busCategoryTeacher;

  /// Bus category badge.
  ///
  /// In bn, this message translates to:
  /// **'অফিসার'**
  String get busCategoryOfficer;

  /// Bus category badge.
  ///
  /// In bn, this message translates to:
  /// **'স্টাফ'**
  String get busCategoryStaff;

  /// Schedule direction UP — heading to the campus.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাম্পাস অভিমুখে'**
  String get scheduleDirectionToCampus;

  /// Schedule direction DOWN — leaving the campus.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাম্পাস থেকে'**
  String get scheduleDirectionFromCampus;

  /// Student account status.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইকৃত'**
  String get statusVerified;

  /// Student account status.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয়'**
  String get statusInactive;

  /// Student account status — awaiting verification.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get statusPending;

  /// ID card OCR found no readable text.
  ///
  /// In bn, this message translates to:
  /// **'ছবি থেকে কোনো তথ্য পড়া যায়নি। আইডি কার্ডের ছবি দিন।'**
  String get idCardNoText;

  /// ID card does not look like a Comilla University card.
  ///
  /// In bn, this message translates to:
  /// **'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড মনে হচ্ছে না।'**
  String get idCardNotCoU;

  /// A teacher uploaded a student ID card.
  ///
  /// In bn, this message translates to:
  /// **'এটি শিক্ষার্থীর আইডি কার্ড। শিক্ষক আইডি কার্ড দিন।'**
  String get idCardIsStudent;

  /// Teacher role, but no teacher ID detected.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক আইডি কার্ড সনাক্ত হয়নি। শিক্ষক পরিচয়পত্রের ছবি দিন।'**
  String get idCardTeacherNotFound;

  /// Non-ID image uploaded (form, photo, etc.).
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র আইডি কার্ড গ্রহণযোগ্য। ভর্তির ফর্ম বা অন্যান্য ছবি দেওয়া যাবে না।'**
  String get idCardOnlyAccepted;

  /// Image processing threw.
  ///
  /// In bn, this message translates to:
  /// **'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে।'**
  String get idCardProcessingFailed;

  /// Notification permission rationale — dialog title.
  ///
  /// In bn, this message translates to:
  /// **'বাস আপডেট পেতে নোটিফিকেশন চালু করুন'**
  String get notifPermissionTitle;

  /// Notification permission rationale — dialog body.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বাসের সময়সূচি, রুট বা জরুরি কোনো পরিবর্তন হলে আমরা নোটিফিকেশনের মাধ্যমে আপনাকে জানাতে চাই। এতে গুরুত্বপূর্ণ আপডেট মিস হওয়ার সম্ভাবনা কমবে।'**
  String get notifPermissionBody;

  /// Notification permission rationale — dismiss.
  ///
  /// In bn, this message translates to:
  /// **'পরে করব'**
  String get notifLater;

  /// Notification permission rationale — grant.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি দিন'**
  String get notifAllow;

  /// Live tracking screen title when no bus name was passed.
  ///
  /// In bn, this message translates to:
  /// **'বাস ট্র্যাকিং'**
  String get busTrackingTitle;

  /// Offline state heading, shown wherever connectivity is required.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ নেই'**
  String get noInternetTitle;

  /// Home offline body — mentions cached data is kept.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ চালু করে রিলোড করুন।\n\nআপনার আগের ডেটা ক্যাশে সংরক্ষিত আছে।'**
  String get noInternetBody;

  /// Home offline — reload button.
  ///
  /// In bn, this message translates to:
  /// **'রিলোড করুন'**
  String get homeReload;

  /// Home exit dialog — close button.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ বন্ধ করুন'**
  String get homeCloseApp;

  /// Home exit dialog body (home uses its own wording here).
  ///
  /// In bn, this message translates to:
  /// **'আপনি কি নিশ্চিত যে অ্যাপ থেকে বের হতে চান?'**
  String get homeExitMessage;

  /// Home — today's schedule section heading.
  ///
  /// In bn, this message translates to:
  /// **'আজকের সময়সূচি'**
  String get todayScheduleTitle;

  /// Home header greeting shown above the brand name.
  ///
  /// In bn, this message translates to:
  /// **'আসসালামু আলাইকুম,'**
  String get homeGreeting;

  /// The app's Bengali product name.
  ///
  /// In bn, this message translates to:
  /// **'কুবি যাত্রা'**
  String get appName;

  /// Home header fallback text when no data has loaded.
  ///
  /// In bn, this message translates to:
  /// **'CoU যাত্রী'**
  String get homeBrandTagline;

  /// Accessibility tooltip on the home menu button.
  ///
  /// In bn, this message translates to:
  /// **'মেনু'**
  String get menuTooltip;

  /// Home header — buses currently active.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি বাস সক্রিয় আছে'**
  String homeActiveBusCount(num count);

  /// Generic 'N buses' count label.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি বাস'**
  String countBuses(num count);

  /// Section header link to the full list.
  ///
  /// In bn, this message translates to:
  /// **'সব দেখুন'**
  String get seeAll;

  /// Home — today's schedule list is exhausted.
  ///
  /// In bn, this message translates to:
  /// **'আজকে আর কোনো শিডিউল নেই'**
  String get noScheduleToday;

  /// Banner shown when displaying cached data without a connection.
  ///
  /// In bn, this message translates to:
  /// **'অফলাইন • সংরক্ষিত তথ্য দেখানো হচ্ছে'**
  String get offlineBanner;

  /// Profile screen app bar title.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল'**
  String get profileTitle;

  /// Logged-out profile heading.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রোফাইল'**
  String get profileYourProfile;

  /// Logged-out profile explanation.
  ///
  /// In bn, this message translates to:
  /// **'বাসের তথ্য ও সঠিক শিডিউল ট্র্যাক করতে আপনার অ্যাকাউন্টে লগইন করুন'**
  String get profileLoginPrompt;

  /// Logged-out profile — login/register button.
  ///
  /// In bn, this message translates to:
  /// **'লগইন / নিবন্ধন করুন'**
  String get profileLoginRegister;

  /// Student role label, shown to both roles.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থী'**
  String get roleStudent;

  /// Teacher role label, shown to both roles.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক'**
  String get roleTeacher;

  /// Profile — ID card section heading.
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড'**
  String get profileIdCard;

  /// Profile — hint under the ID card image.
  ///
  /// In bn, this message translates to:
  /// **'ছবি দেখতে ট্যাপ করুন'**
  String get profileTapToViewPhoto;

  /// Profile info row — name.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get profileName;

  /// Profile info row — email.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get profileEmail;

  /// Profile info row — role.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get profileRole;

  /// Profile — logout button.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট'**
  String get profileLogout;

  /// Schedules screen — title for the teacher-bus variant.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক বাস'**
  String get scheduleTeacherBus;

  /// Schedules screen — title for the student-bus variant.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থী বাস'**
  String get scheduleStudentBus;

  /// Schedules screen app bar title.
  ///
  /// In bn, this message translates to:
  /// **'সময়সূচি'**
  String get scheduleTitle;

  /// Schedules — search field hint.
  ///
  /// In bn, this message translates to:
  /// **'শিডিউল খুঁজুন (সময় বা রুট)...'**
  String get scheduleSearchHint;

  /// Schedules — day-type filter chip (default).
  ///
  /// In bn, this message translates to:
  /// **'আজকের তালিকা'**
  String get scheduleFilterToday;

  /// Schedules — day-type filter chip, working days.
  ///
  /// In bn, this message translates to:
  /// **'কর্মদিবস'**
  String get scheduleFilterWorking;

  /// Schedules — day-type filter chip, weekend.
  ///
  /// In bn, this message translates to:
  /// **'শুক্র ও শনিবার'**
  String get scheduleFilterWeekend;

  /// Filter chip that clears the filter.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get filterAll;

  /// Schedules — nothing matches for today.
  ///
  /// In bn, this message translates to:
  /// **'আজকে কোনো শিডিউল নেই'**
  String get scheduleEmpty;

  /// Bus list — search field hint.
  ///
  /// In bn, this message translates to:
  /// **'বাস খুঁজুন...'**
  String get busSearchHint;

  /// Bus list — a bus has no route data.
  ///
  /// In bn, this message translates to:
  /// **'রুট তথ্য নেই'**
  String get busRouteMissing;

  /// Bus list — no buses match the filter/search.
  ///
  /// In bn, this message translates to:
  /// **'কোনো বাস পাওয়া যায়নি'**
  String get busListEmpty;

  /// Live tracking — initial status while the web view loads.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্ত হচ্ছে...'**
  String get trackingConnecting;

  /// Live tracking — device GPS is disabled.
  ///
  /// In bn, this message translates to:
  /// **'GPS বন্ধ'**
  String get trackingGpsOff;

  /// Live tracking — location permission denied.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি নেই'**
  String get trackingPermissionDenied;

  /// Live tracking — location permission permanently blocked.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি ব্লক'**
  String get trackingPermissionBlocked;

  /// Live tracking — hint to lower the update interval.
  ///
  /// In bn, this message translates to:
  /// **'দ্রুত আপডেট পেতে নিচের বাম পাশের ড্রপডাউন থেকে ৫ সেঃ সিলেক্ট করুন'**
  String get trackingFastUpdateHint;

  /// Live tracking — offline body.
  ///
  /// In bn, this message translates to:
  /// **'বাসের লোকেশন দেখতে ইন্টারনেট সংযোগ চালু করে\nআবার চেষ্টা করুন।'**
  String get trackingNoInternetBody;

  /// Role selection screen heading.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ভূমিকা'**
  String get roleSelectTitle;

  /// Role selection — screen title.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ভূমিকা নির্বাচন করুন'**
  String get roleChoosePrompt;

  /// Role selection — subtitle.
  ///
  /// In bn, this message translates to:
  /// **'লগইন বা নিবন্ধনের জন্য ভূমিকা বাছাই করুন'**
  String get roleLoginRegisterHint;

  /// Role selection — student card subtitle.
  ///
  /// In bn, this message translates to:
  /// **'ছাত্র হিসেবে লগইন বা নিবন্ধন করুন'**
  String get roleStudentSubtitle;

  /// Role selection — teacher card subtitle.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক হিসেবে লগইন বা নিবন্ধন করুন'**
  String get roleTeacherSubtitle;

  /// Bus detail — driver information section heading.
  ///
  /// In bn, this message translates to:
  /// **'ড্রাইভার তথ্য'**
  String get driverInfoTitle;

  /// Bus detail — schedule and route section heading.
  ///
  /// In bn, this message translates to:
  /// **'শিডিউল ও রুট'**
  String get scheduleRouteTitle;

  /// Bus detail — badge on a deactivated trip; the trip stays visible, greyed out, so a rider who taps the "service paused" notification sees why it will not run.
  ///
  /// In bn, this message translates to:
  /// **'সাময়িক বন্ধ'**
  String get busSchedulePaused;

  /// Bus detail — link to live tracking.
  ///
  /// In bn, this message translates to:
  /// **'লাইভ লোকেশন দেখুন'**
  String get busSeeLiveLocation;

  /// Bus detail — shown in place of the live-tracking button when the bus has no tracker link yet.
  ///
  /// In bn, this message translates to:
  /// **'এই বাসের জন্য লাইভ ট্র্যাকার লিংক এখনো যুক্ত করা হয়নি'**
  String get busTrackerUnavailable;

  /// Generic error fallback text.
  ///
  /// In bn, this message translates to:
  /// **'ত্রুটি'**
  String get commonError;

  /// Forced update — dialog title.
  ///
  /// In bn, this message translates to:
  /// **'আপডেট প্রয়োজন'**
  String get forceUpdateTitle;

  /// Optional update — dialog title.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ভার্সন পাওয়া গেছে'**
  String get newVersionTitle;

  /// Optional update — dialog body.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপের নতুন ভার্সন পাওয়া গেছে। আপডেট করুন।'**
  String get newVersionBody;

  /// Update dialog — accept button.
  ///
  /// In bn, this message translates to:
  /// **'আপডেট করুন'**
  String get updateNow;

  /// Update dialog — dismiss button.
  ///
  /// In bn, this message translates to:
  /// **'পরে করুন'**
  String get updateLater;

  /// Notices screen app bar title.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get noticeTitle;

  /// Notice badge — past its validity.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদোত্তীর্ণ'**
  String get noticeExpired;

  /// Notice badge — currently valid.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয়'**
  String get noticeActive;

  /// Notices — nothing active.
  ///
  /// In bn, this message translates to:
  /// **'এখন কোনো সক্রিয় নোটিশ নেই'**
  String get noticeEmpty;

  /// Maintenance screen heading.
  ///
  /// In bn, this message translates to:
  /// **'রক্ষণাবেক্ষণ'**
  String get maintenanceTitle;

  /// Maintenance screen body.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপটি রক্ষণাবেক্ষণে আছে। শীঘ্রই ফিরে আসছি।'**
  String get maintenanceBody;

  /// Generic retry button.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get commonRetry;

  /// Dialog acknowledge button.
  ///
  /// In bn, this message translates to:
  /// **'ঠিক আছে'**
  String get commonOk;

  /// Dialog cancel button.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get commonCancel;

  /// No description provided for @fieldFullName.
  ///
  /// In bn, this message translates to:
  /// **'পুরো নাম'**
  String get fieldFullName;

  /// No description provided for @fieldPhoneNumber.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর'**
  String get fieldPhoneNumber;

  /// No description provided for @fieldEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get fieldPassword;

  /// Confirm-password field label; also reused as its validator message.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড আবার দিন'**
  String get fieldPasswordConfirm;

  /// No description provided for @fieldNewPassword.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড'**
  String get fieldNewPassword;

  /// No description provided for @fieldRollNumber.
  ///
  /// In bn, this message translates to:
  /// **'রোল নম্বর'**
  String get fieldRollNumber;

  /// No description provided for @fieldTeacherId.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক আইডি'**
  String get fieldTeacherId;

  /// No description provided for @fieldEmployeeId.
  ///
  /// In bn, this message translates to:
  /// **'কর্মচারী আইডি'**
  String get fieldEmployeeId;

  /// Generic ID field label (teacher/staff registration).
  ///
  /// In bn, this message translates to:
  /// **'আইডি'**
  String get fieldId;

  /// No description provided for @fieldDesignation.
  ///
  /// In bn, this message translates to:
  /// **'পদবী'**
  String get fieldDesignation;

  /// No description provided for @fieldDepartment.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ'**
  String get fieldDepartment;

  /// No description provided for @fieldDepartmentOffice.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ/অফিস'**
  String get fieldDepartmentOffice;

  /// No description provided for @fieldSession.
  ///
  /// In bn, this message translates to:
  /// **'সেশন'**
  String get fieldSession;

  /// No description provided for @validationNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নাম দিন'**
  String get validationNameRequired;

  /// No description provided for @validationNameLength.
  ///
  /// In bn, this message translates to:
  /// **'নাম ২ থেকে ১০০ অক্ষরের হতে হবে'**
  String get validationNameLength;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর দিন'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ফোন নম্বর দিন (01XXXXXXXXX)'**
  String get validationPhoneInvalid;

  /// No description provided for @validationEmailRequired.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল দিন'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল দিন'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড দিন'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordLength8.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে'**
  String get validationPasswordLength8;

  /// No description provided for @validationPasswordLength6.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে'**
  String get validationPasswordLength6;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড মিলছে না'**
  String get validationPasswordMismatch;

  /// No description provided for @validationDepartmentRequired.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ দিন'**
  String get validationDepartmentRequired;

  /// No description provided for @validationDepartmentLength.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ ২ থেকে ১০০ অক্ষরের হতে হবে'**
  String get validationDepartmentLength;

  /// No description provided for @validationSessionRequired.
  ///
  /// In bn, this message translates to:
  /// **'সেশন দিন'**
  String get validationSessionRequired;

  /// Session validator — lists accepted formats.
  ///
  /// In bn, this message translates to:
  /// **'সেশন সঠিকভাবে দিন (যেমন: 16, 2020, 2021-22, অথবা 2020-2024)'**
  String get validationSessionFormat;

  /// No description provided for @validationRollRequired.
  ///
  /// In bn, this message translates to:
  /// **'রোল নম্বর দিন'**
  String get validationRollRequired;

  /// No description provided for @validationRollLength.
  ///
  /// In bn, this message translates to:
  /// **'রোল নম্বর ২-৫০ অক্ষরের হতে হবে'**
  String get validationRollLength;

  /// No description provided for @validationEmployeeIdRequired.
  ///
  /// In bn, this message translates to:
  /// **'কর্মচারী আইডি দিন'**
  String get validationEmployeeIdRequired;

  /// No description provided for @validationEmployeeIdLength.
  ///
  /// In bn, this message translates to:
  /// **'কর্মচারী আইডি ২-৫০ অক্ষরের হতে হবে'**
  String get validationEmployeeIdLength;

  /// No description provided for @validationDesignationRequired.
  ///
  /// In bn, this message translates to:
  /// **'পদবী দিন'**
  String get validationDesignationRequired;

  /// No description provided for @validationDesignationLength.
  ///
  /// In bn, this message translates to:
  /// **'পদবী ১০০ অক্ষরের হতে হবে'**
  String get validationDesignationLength;

  /// Generic ID validator (teacher/staff registration).
  ///
  /// In bn, this message translates to:
  /// **'আইডি দিন'**
  String get validationIdRequired;

  /// No description provided for @selectDepartment.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ নির্বাচন করুন'**
  String get selectDepartment;

  /// No description provided for @selectDepartmentOffice.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ/অফিস নির্বাচন করুন'**
  String get selectDepartmentOffice;

  /// No description provided for @selectSession.
  ///
  /// In bn, this message translates to:
  /// **'সেশন নির্বাচন করুন'**
  String get selectSession;

  /// No description provided for @hintExampleRoll.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: 12208055'**
  String get hintExampleRoll;

  /// No description provided for @hintExampleEmployeeId.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: 1234'**
  String get hintExampleEmployeeId;

  /// No description provided for @hintExampleDesignation.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: সহযোগী অধ্যাপক'**
  String get hintExampleDesignation;

  /// No description provided for @hintExamplePhone.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: 01712345678'**
  String get hintExamplePhone;

  /// No description provided for @authLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইন করুন'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন করুন'**
  String get authRegister;

  /// No description provided for @authLoginBack.
  ///
  /// In bn, this message translates to:
  /// **'লগইনে ফিরে যান'**
  String get authLoginBack;

  /// No description provided for @authForgotPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড ভুলে গেছেন?'**
  String get authForgotPassword;

  /// Preceding the underlined register link — keep the trailing space.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট নেই? '**
  String get authNoAccount;

  /// Preceding the underlined login link — keep the trailing space.
  ///
  /// In bn, this message translates to:
  /// **'ইতিমধ্যে অ্যাকাউন্ট আছে? '**
  String get authHaveAccount;

  /// No description provided for @authStudentLogin.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থী লগইন'**
  String get authStudentLogin;

  /// No description provided for @authTeacherLogin.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক লগইন'**
  String get authTeacherLogin;

  /// No description provided for @authTeacherOfficerLogin.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক ও কর্মকর্তাবৃন্দ লগইন'**
  String get authTeacherOfficerLogin;

  /// No description provided for @authStudentRegister.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থী নিবন্ধন'**
  String get authStudentRegister;

  /// No description provided for @authTeacherRegister.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক নিবন্ধন'**
  String get authTeacherRegister;

  /// No description provided for @authTeacherOfficerRegister.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক ও কর্মকর্তাবৃন্দ নিবন্ধন'**
  String get authTeacherOfficerRegister;

  /// No description provided for @passwordResetTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট'**
  String get passwordResetTitle;

  /// No description provided for @authPhoneVerificationTitle.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর যাচাইকরণ'**
  String get authPhoneVerificationTitle;

  /// No description provided for @authEmailVerificationTitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল যাচাইকরণ'**
  String get authEmailVerificationTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর ও পাসওয়ার্ড দিয়ে লগইন করুন'**
  String get loginSubtitle;

  /// No description provided for @forgotPhoneSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ফোন নম্বর দিন, আমরা OTP পাঠাবো'**
  String get forgotPhoneSubtitle;

  /// No description provided for @forgotEmailSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ইমেইল দিন, আমরা OTP পাঠাবো'**
  String get forgotEmailSubtitle;

  /// Login subtitle when the user picked the Edumail path.
  ///
  /// In bn, this message translates to:
  /// **'এডুমেইল ও পাসওয়ার্ড দিয়ে লগইন করুন'**
  String get emailLoginSubtitleEdu;

  /// Login subtitle when the user picked the institutional-email path.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিষ্ঠানিক ইমেইল ও পাসওয়ার্ড দিয়ে লগইন করুন'**
  String get emailLoginSubtitleInst;

  /// Field label for the @student.cou.ac.bd style address.
  ///
  /// In bn, this message translates to:
  /// **'এডুমেইল'**
  String get emailFieldEdu;

  /// Field label for staff/professional addresses.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিষ্ঠানিক ইমেইল'**
  String get emailFieldInst;

  /// No description provided for @emailRegisterSubtitleEdu.
  ///
  /// In bn, this message translates to:
  /// **'আপনার এডুমেইলের মাধ্যমে OTP নিবন্ধন করুন'**
  String get emailRegisterSubtitleEdu;

  /// No description provided for @emailRegisterSubtitleInst.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রতিষ্ঠানিক ইমেইলের মাধ্যমে OTP নিবন্ধন করুন'**
  String get emailRegisterSubtitleInst;

  /// Keeps the source's original wording.
  ///
  /// In bn, this message translates to:
  /// **'যদি আপনার এডুমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন'**
  String get noEduMailHintEdu;

  /// Keeps the source's original wording.
  ///
  /// In bn, this message translates to:
  /// **'যদি আপনার প্রতিষ্ঠানিক ইমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন'**
  String get noEduMailHintInst;

  /// No description provided for @googleSignInSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্ট দিয়ে প্রবেশ করুন'**
  String get googleSignInSubtitle;

  /// No description provided for @googleInstitutionalPrompt.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বিশ্ববিদ্যালয়ের প্রাতিষ্ঠানিক ইমেইল ব্যবহার করে প্রবেশ করুন।'**
  String get googleInstitutionalPrompt;

  /// No description provided for @googleEmailFormatLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রয়োজনীয় ইমেইল ফরমেট:'**
  String get googleEmailFormatLabel;

  /// No description provided for @googleIctHelp.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বিশ্ববিদ্যালয় ইমেইল না থাকলে অনুগ্রহ করে কুমিল্লা বিশ্ববিদ্যালয়ের আইসিটি সেলের সঙ্গে যোগাযোগ করুন।'**
  String get googleIctHelp;

  /// No description provided for @googleSignInButton.
  ///
  /// In bn, this message translates to:
  /// **'গুগল অ্যাকাউন্ট দিয়ে প্রবেশ করুন'**
  String get googleSignInButton;

  /// User dismissed the Google account picker.
  ///
  /// In bn, this message translates to:
  /// **'প্রবেশ বাতিল করা হয়েছে।'**
  String get googleSignInCancelled;

  /// Google sign-in is misconfigured (SHA-1 / client ID).
  ///
  /// In bn, this message translates to:
  /// **'গুগল সাইন-ইন কনফিগারেশনে সমস্যা হয়েছে। যোগাযোগ করুন।'**
  String get googleSignInConfigError;

  /// No description provided for @googleGmailReminderTitle.
  ///
  /// In bn, this message translates to:
  /// **'এগিয়ে যাওয়ার আগে'**
  String get googleGmailReminderTitle;

  /// No description provided for @googleGmailReminderMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টে প্রবেশাধিকার আছে এবং অ্যাকাউন্টটি Gmail অ্যাপে আগে থেকেই সাইন ইন করা আছে কিনা নিশ্চিত করুন। সাইন ইন করার সময় আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টটি নির্বাচন করুন।'**
  String get googleGmailReminderMessage;

  /// No description provided for @uploadIdTitle.
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড আপলোড'**
  String get uploadIdTitle;

  /// No description provided for @uploadIdSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার বিশ্ববিদ্যালয়ের পরিচয়পত্র আপলোড করুন'**
  String get uploadIdSubtitle;

  /// No description provided for @uploadIdSuccess.
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড সফলভাবে আপলোড হয়েছে'**
  String get uploadIdSuccess;

  /// No description provided for @selectPhoto.
  ///
  /// In bn, this message translates to:
  /// **'ছবি সিলেক্ট করুন'**
  String get selectPhoto;

  /// No description provided for @completeUpload.
  ///
  /// In bn, this message translates to:
  /// **'আপলোড সম্পন্ন করুন'**
  String get completeUpload;

  /// No description provided for @authSendOtp.
  ///
  /// In bn, this message translates to:
  /// **'OTP পাঠান'**
  String get authSendOtp;

  /// No description provided for @authVerifyOtp.
  ///
  /// In bn, this message translates to:
  /// **'OTP যাচাই করুন'**
  String get authVerifyOtp;

  /// No description provided for @authVerify.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই করুন'**
  String get authVerify;

  /// No description provided for @authResendCode.
  ///
  /// In bn, this message translates to:
  /// **'আবার কোড পাঠান'**
  String get authResendCode;

  /// No description provided for @authChangePhoneBack.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর পরিবর্তন / নিবন্ধনে ফিরে যান'**
  String get authChangePhoneBack;

  /// No description provided for @authChangeEmailBack.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল পরিবর্তন / নিবন্ধনে ফিরে যান'**
  String get authChangeEmailBack;

  /// Heading above the resend-code button.
  ///
  /// In bn, this message translates to:
  /// **'কোডটি পাননি?'**
  String get authCodeNotReceived;

  /// Resend cooldown, e.g. '0:45' remaining.
  ///
  /// In bn, this message translates to:
  /// **'নতুন কোড পাঠাতে {remaining} অবশিষ্ট'**
  String authResendCountdown(String remaining);

  /// No description provided for @otpDigitHint.
  ///
  /// In bn, this message translates to:
  /// **'৬ ডিজিট OTP'**
  String get otpDigitHint;

  /// No description provided for @otpDigitRequired.
  ///
  /// In bn, this message translates to:
  /// **'৬ ডিজিট OTP দিন'**
  String get otpDigitRequired;

  /// No description provided for @resetPasswordButton.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করুন'**
  String get resetPasswordButton;

  /// Confirmation after requesting an OTP for a phone number.
  ///
  /// In bn, this message translates to:
  /// **'{phone} নম্বরে OTP পাঠানো হয়েছে'**
  String otpSentToPhone(String phone);

  /// Confirmation after requesting an OTP for an email address.
  ///
  /// In bn, this message translates to:
  /// **'{email} ইমেইলে OTP পাঠানো হয়েছে'**
  String otpSentToEmail(String email);

  /// Validator/inline error for a partially typed OTP.
  ///
  /// In bn, this message translates to:
  /// **'৬ সংখ্যার কোডটি সম্পূর্ণ লিখুন।'**
  String get otpIncomplete;

  /// Generic fallback when no specific verification error exists.
  ///
  /// In bn, this message translates to:
  /// **'ভেরিফিকেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'**
  String get verificationFailedFallback;

  /// Shown after an expired OTP triggers an automatic resend.
  ///
  /// In bn, this message translates to:
  /// **'OTP মেয়াদোত্তীর্ণ হয়েছে। নতুন OTP পাঠানো হয়েছে।'**
  String get otpExpiredResent;

  /// No description provided for @codeSendFailed.
  ///
  /// In bn, this message translates to:
  /// **'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।'**
  String get codeSendFailed;

  /// OTP screen subtitle — mentions a verification code.
  ///
  /// In bn, this message translates to:
  /// **'আমরা আপনার ফোনে ৬ সংখ্যার একটি verification code পাঠিয়েছি।'**
  String get phoneVerifySubtitle;

  /// OTP screen subtitle — mentions a verification code.
  ///
  /// In bn, this message translates to:
  /// **'আমরা আপনার ইমেইলে ৬ সংখ্যার একটি verification code পাঠিয়েছি।'**
  String get emailVerifySubtitle;

  /// Image picker rejected a non JPG/PNG file.
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র JPG, JPEG বা PNG ছবি নির্বাচন করুন।'**
  String get invalidImageType;

  /// OCR recognized a teacher ID card (success toast).
  ///
  /// In bn, this message translates to:
  /// **'✅ শিক্ষক আইডি কার্ড সনাক্ত হয়েছে'**
  String get idCardDetectedTeacher;

  /// OCR recognized a student ID card (success toast).
  ///
  /// In bn, this message translates to:
  /// **'✅ আইডি কার্ড সনাক্ত হয়েছে'**
  String get idCardDetected;

  /// Upload finished (success toast).
  ///
  /// In bn, this message translates to:
  /// **'✅ ছবি আপলোড হয়েছে'**
  String get photoUploaded;

  /// OCR auto-filled the form — asks the user to review it.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য স্বয়ংক্রিয়ভাবে পূরণ হয়েছে। পরীক্ষা করে নিন।'**
  String get autoFilledInfo;

  /// No description provided for @photoValidationFailed.
  ///
  /// In bn, this message translates to:
  /// **'ছবি যাচাইয়ে সমস্যা হয়েছে।'**
  String get photoValidationFailed;

  /// No description provided for @registerSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড অথবা ভর্তির ফর্ম আপলোড করুন'**
  String get registerSubtitle;

  /// No description provided for @otpWillBeSentToPhone.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধনের পর এই নম্বরে OTP পাঠানো হবে'**
  String get otpWillBeSentToPhone;

  /// Registration upload section heading (student).
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড বা ভর্তির ফর্ম — যেকোনো একটি দিন!'**
  String get uploadDocStudent;

  /// Registration upload section heading (teacher).
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক আইডি কার্ড আপলোড করুন'**
  String get uploadDocTeacher;

  /// Bulleted upload guidelines (student) — newlines between bullets.
  ///
  /// In bn, this message translates to:
  /// **'• আইডি কার্ড আছে → আইডি কার্ডের ছবি আপলোড করুন\n• আইডি কার্ড নেই → ভর্তির ফর্ম / ভর্তি ভাউচারের ছবি আপলোড করুন\n• উভয়ই কুমিল্লা বিশ্ববিদ্যালয়ের হতে হবে'**
  String get uploadGuidelinesStudent;

  /// Bulleted upload guidelines (teacher) — newlines between bullets.
  ///
  /// In bn, this message translates to:
  /// **'• শিক্ষক পরিচয়পত্রের ছবি আপলোড করুন\n• কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড হতে হবে\n• ডিপার্টমেন্ট ও পদবি স্বয়ংক্রিয়ভাবে পূরণ হবে'**
  String get uploadGuidelinesTeacher;

  /// File-picker caption (student).
  ///
  /// In bn, this message translates to:
  /// **'পরিচয়পত্র / ভর্তির ফর্মের ছবি (MANDATORY)'**
  String get docPhotoLabelStudent;

  /// File-picker caption (teacher).
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক পরিচয়পত্রের ছবি (MANDATORY)'**
  String get docPhotoLabelTeacher;

  /// No description provided for @photoFormatStudent.
  ///
  /// In bn, this message translates to:
  /// **'(JPG/PNG — আইডি কার্ড অথবা ভর্তির ফর্ম)'**
  String get photoFormatStudent;

  /// No description provided for @photoFormatTeacher.
  ///
  /// In bn, this message translates to:
  /// **'(JPG/PNG — শিক্ষক আইডি কার্ড)'**
  String get photoFormatTeacher;

  /// Photo size hint in megabytes — {size} is already formatted.
  ///
  /// In bn, this message translates to:
  /// **'ছবির সাইজ: {size} MB'**
  String photoSizeMb(String size);

  /// Photo size hint in kilobytes — {size} is already formatted.
  ///
  /// In bn, this message translates to:
  /// **'ছবির সাইজ: {size} KB'**
  String photoSizeKb(String size);

  /// No description provided for @photoValidatingIndicator.
  ///
  /// In bn, this message translates to:
  /// **'ছবি যাচাই করা হচ্ছে...'**
  String get photoValidatingIndicator;

  /// No description provided for @registerDocTitle.
  ///
  /// In bn, this message translates to:
  /// **'নথি প্রয়োজন'**
  String get registerDocTitle;

  /// No description provided for @registerDocRequiredMsg.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন সম্পন্ন করতে আপনার বিশ্ববিদ্যালয় আইডি কার্ড অথবা ভর্তির ফর্মের ছবি আপলোড করা বাধ্যতামূলক।'**
  String get registerDocRequiredMsg;

  /// No description provided for @photoValidatingDialog.
  ///
  /// In bn, this message translates to:
  /// **'ছবি যাচাই হচ্ছে... অপেক্ষা করুন।'**
  String get photoValidatingDialog;

  /// Shown when the uploaded document could not be accepted.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক আইডি কার্ড দিন।'**
  String get validIdCardPrompt;

  /// No description provided for @academicStudentTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থীর তথ্য সম্পূর্ণ করুন'**
  String get academicStudentTitle;

  /// No description provided for @academicStaffTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষক ও কর্মকর্তাদের তথ্য সম্পূর্ণ করুন'**
  String get academicStaffTitle;

  /// No description provided for @academicSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট ব্যবহার করতে নিচের তথ্যগুলো দিন।'**
  String get academicSubtitle;

  /// Academic details are submitted only once.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্য একবার দেওয়ার পর পরিবর্তন করা যাবে না। সঠিকভাবে দিন।'**
  String get academicOnceOnlyNote;

  /// Field helper under locked-after-submit fields.
  ///
  /// In bn, this message translates to:
  /// **'একবার দেওয়ার পর পরিবর্তন করা যাবে না'**
  String get academicHelperOnce;

  /// Placeholder inside a registration picker while its option list is being fetched.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা লোড হচ্ছে…'**
  String get academicOptionsLoading;

  /// No description provided for @academicSave.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ করুন'**
  String get academicSave;

  /// Confirm dialog before logging out from the completion form.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট করবেন?'**
  String get academicLogoutTitle;

  /// Confirm dialog body for skipping the completion form.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য ছাড়া অ্যাকাউন্ট ব্যবহার করা যাবে না। পরে আবার লগইন করে পূরণ করতে পারবেন।'**
  String get academicLogoutBody;

  /// Backend verified the OTP but returned no access token.
  ///
  /// In bn, this message translates to:
  /// **'ভেরিফিকেশন সফল হলেও টোকেন পাওয়া যায়নি। আবার চেষ্টা করুন।'**
  String get errorVerifyOtpNoToken;

  /// Success message returned by the OTP send request.
  ///
  /// In bn, this message translates to:
  /// **'OTP পাঠানো হয়েছে'**
  String get otpSent;

  /// Success message returned by the OTP resend request.
  ///
  /// In bn, this message translates to:
  /// **'OTP পুনরায় পাঠানো হয়েছে'**
  String get otpResent;

  /// Unexpected backend response shape; kept as-is.
  ///
  /// In bn, this message translates to:
  /// **'Unknown response'**
  String get errorUnknownResponse;

  /// No description provided for @deptCse.
  ///
  /// In bn, this message translates to:
  /// **'কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং (CSE)'**
  String get deptCse;

  /// No description provided for @deptMathematics.
  ///
  /// In bn, this message translates to:
  /// **'গণিত'**
  String get deptMathematics;

  /// No description provided for @deptPhysics.
  ///
  /// In bn, this message translates to:
  /// **'পদার্থবিজ্ঞান'**
  String get deptPhysics;

  /// No description provided for @deptStatistics.
  ///
  /// In bn, this message translates to:
  /// **'পরিসংখ্যান'**
  String get deptStatistics;

  /// No description provided for @deptChemistry.
  ///
  /// In bn, this message translates to:
  /// **'রসায়ন'**
  String get deptChemistry;

  /// No description provided for @deptPharmacy.
  ///
  /// In bn, this message translates to:
  /// **'ফার্মেসি'**
  String get deptPharmacy;

  /// No description provided for @deptEnglish.
  ///
  /// In bn, this message translates to:
  /// **'ইংরেজি'**
  String get deptEnglish;

  /// No description provided for @deptBangla.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা'**
  String get deptBangla;

  /// No description provided for @deptEconomics.
  ///
  /// In bn, this message translates to:
  /// **'অর্থনীতি'**
  String get deptEconomics;

  /// No description provided for @deptPublicAdministration.
  ///
  /// In bn, this message translates to:
  /// **'লোক প্রশাসন'**
  String get deptPublicAdministration;

  /// No description provided for @deptAnthropology.
  ///
  /// In bn, this message translates to:
  /// **'নৃবিজ্ঞান'**
  String get deptAnthropology;

  /// No description provided for @deptMassCommunication.
  ///
  /// In bn, this message translates to:
  /// **'গণযোগাযোগ ও সাংবাদিকতা'**
  String get deptMassCommunication;

  /// No description provided for @deptArchaeology.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্নতত্ত্ব'**
  String get deptArchaeology;

  /// No description provided for @deptManagement.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবস্থাপনা শিক্ষা'**
  String get deptManagement;

  /// No description provided for @deptAccounting.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্টিং অ্যান্ড ইনফরমেশন সিস্টেমস'**
  String get deptAccounting;

  /// No description provided for @deptMarketing.
  ///
  /// In bn, this message translates to:
  /// **'মার্কেটিং'**
  String get deptMarketing;

  /// No description provided for @deptFinance.
  ///
  /// In bn, this message translates to:
  /// **'ফাইন্যান্স অ্যান্ড ব্যাংকিং'**
  String get deptFinance;

  /// No description provided for @deptIct.
  ///
  /// In bn, this message translates to:
  /// **'ইনফরমেশন অ্যান্ড কমিউনিকেশন টেকনোলজি (ICT)'**
  String get deptIct;

  /// No description provided for @deptLaw.
  ///
  /// In bn, this message translates to:
  /// **'আইন'**
  String get deptLaw;

  /// No description provided for @officeVc.
  ///
  /// In bn, this message translates to:
  /// **'উপাচার্যের কার্যালয়'**
  String get officeVc;

  /// No description provided for @officeProVc.
  ///
  /// In bn, this message translates to:
  /// **'উপ-উপাচার্যের কার্যালয়'**
  String get officeProVc;

  /// No description provided for @officeTreasurer.
  ///
  /// In bn, this message translates to:
  /// **'কোষাধ্যক্ষের কার্যালয়'**
  String get officeTreasurer;

  /// No description provided for @officeRegistrar.
  ///
  /// In bn, this message translates to:
  /// **'রেজিস্ট্রারের কার্যালয়'**
  String get officeRegistrar;

  /// No description provided for @officeProctor.
  ///
  /// In bn, this message translates to:
  /// **'প্রক্টরের কার্যালয়'**
  String get officeProctor;

  /// No description provided for @officeResearchExtension.
  ///
  /// In bn, this message translates to:
  /// **'গবেষণা ও সম্প্রসারণ পরিচালকের কার্যালয়'**
  String get officeResearchExtension;

  /// No description provided for @officeEstate.
  ///
  /// In bn, this message translates to:
  /// **'এস্টেট শাখা'**
  String get officeEstate;

  /// No description provided for @officeSecurity.
  ///
  /// In bn, this message translates to:
  /// **'নিরাপত্তা শাখা'**
  String get officeSecurity;

  /// No description provided for @officeCentralStore.
  ///
  /// In bn, this message translates to:
  /// **'কেন্দ্রীয় স্টোর'**
  String get officeCentralStore;

  /// No description provided for @officeFinanceAccounts.
  ///
  /// In bn, this message translates to:
  /// **'অর্থ ও হিসাব পরিচালকের কার্যালয়'**
  String get officeFinanceAccounts;

  /// No description provided for @officeExaminations.
  ///
  /// In bn, this message translates to:
  /// **'পরীক্ষা নিয়ন্ত্রকের কার্যালয়'**
  String get officeExaminations;

  /// No description provided for @officePlanningDevelopment.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা ও উন্নয়ন পরিচালকের কার্যালয়'**
  String get officePlanningDevelopment;

  /// No description provided for @officeLibrary.
  ///
  /// In bn, this message translates to:
  /// **'কেন্দ্রীয় গ্রন্থাগার'**
  String get officeLibrary;

  /// No description provided for @officeEngineering.
  ///
  /// In bn, this message translates to:
  /// **'প্রকৌশল কার্যালয়'**
  String get officeEngineering;

  /// No description provided for @officeMedical.
  ///
  /// In bn, this message translates to:
  /// **'মেডিকেল সেন্টার'**
  String get officeMedical;

  /// No description provided for @officeIctCell.
  ///
  /// In bn, this message translates to:
  /// **'আইসিটি সেল'**
  String get officeIctCell;

  /// No description provided for @officePhysicalEducation.
  ///
  /// In bn, this message translates to:
  /// **'শারীরিক শিক্ষা কার্যালয়'**
  String get officePhysicalEducation;

  /// No description provided for @officePublicRelations.
  ///
  /// In bn, this message translates to:
  /// **'জনসংযোগ কার্যালয়'**
  String get officePublicRelations;

  /// No description provided for @officeCentralMosque.
  ///
  /// In bn, this message translates to:
  /// **'কেন্দ্রীয় মসজিদ'**
  String get officeCentralMosque;

  /// No description provided for @officeTransportPool.
  ///
  /// In bn, this message translates to:
  /// **'পরিবহন পুল'**
  String get officeTransportPool;

  /// No description provided for @officeCounseling.
  ///
  /// In bn, this message translates to:
  /// **'শিক্ষার্থী কাউন্সেলিং ও গাইডেন্স'**
  String get officeCounseling;

  /// No description provided for @officeInternationalRelations.
  ///
  /// In bn, this message translates to:
  /// **'আন্তর্জাতিক সম্পর্ক'**
  String get officeInternationalRelations;

  /// No description provided for @officeCareerDevelopment.
  ///
  /// In bn, this message translates to:
  /// **'ক্যারিয়ার ডেভেলপমেন্ট সেন্টার'**
  String get officeCareerDevelopment;

  /// No description provided for @session2016.
  ///
  /// In bn, this message translates to:
  /// **'২০১৬-২০১৭'**
  String get session2016;

  /// No description provided for @session2017.
  ///
  /// In bn, this message translates to:
  /// **'২০১৭-২০১৮'**
  String get session2017;

  /// No description provided for @session2018.
  ///
  /// In bn, this message translates to:
  /// **'২০১৮-২০১৯'**
  String get session2018;

  /// No description provided for @session2019.
  ///
  /// In bn, this message translates to:
  /// **'২০১৯-২০২০'**
  String get session2019;

  /// No description provided for @session2020.
  ///
  /// In bn, this message translates to:
  /// **'২০২০-২০২১'**
  String get session2020;

  /// No description provided for @session2021.
  ///
  /// In bn, this message translates to:
  /// **'২০২১-২০২২'**
  String get session2021;

  /// No description provided for @session2022.
  ///
  /// In bn, this message translates to:
  /// **'২০২২-২০২৩'**
  String get session2022;

  /// No description provided for @session2023.
  ///
  /// In bn, this message translates to:
  /// **'২০২৩-২০২৪'**
  String get session2023;

  /// No description provided for @session2024.
  ///
  /// In bn, this message translates to:
  /// **'২০২৪-২০২৫'**
  String get session2024;

  /// No description provided for @session2025.
  ///
  /// In bn, this message translates to:
  /// **'২০২৫-২০২৬'**
  String get session2025;

  /// About Us screen title — also the entry in the home hamburger menu.
  ///
  /// In bn, this message translates to:
  /// **'আমাদের সম্পর্কে'**
  String get aboutUsTitle;

  /// About Us — accessibility tooltip on the floating scroll-down button.
  ///
  /// In bn, this message translates to:
  /// **'আরও দেখতে নিচে স্ক্রল করুন'**
  String get aboutScrollTooltip;

  /// About Us — one-line app description under the logo.
  ///
  /// In bn, this message translates to:
  /// **'কুমিল্লা বিশ্ববিদ্যালয়ের বাস রিয়েল-টাইমে ট্র্যাক করার অ্যাপ, সাথে বাস সময়সূচি'**
  String get aboutAppDescription;

  /// About Us — heading of the department credit card.
  ///
  /// In bn, this message translates to:
  /// **'কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং'**
  String get aboutDeptName;

  /// About Us — note crediting the CSE department for the initiative.
  ///
  /// In bn, this message translates to:
  /// **'এই অ্যাপটি তৈরির উদ্যোগ নেওয়া হয়েছে সিএসই বিভাগ কর্তৃক।'**
  String get aboutDeptNote;

  /// About Us — role line of the lead developer card.
  ///
  /// In bn, this message translates to:
  /// **'লিড ডেভেলপার'**
  String get aboutRoleLeadDeveloper;

  /// About Us — role line of the current maintainer card.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান রক্ষণাবেক্ষক ও কোর কন্ট্রিবিউটর'**
  String get aboutRoleMaintainer;

  /// About Us — role line of the project consultant card.
  ///
  /// In bn, this message translates to:
  /// **'প্রজেক্ট কনসালট্যান্ট'**
  String get aboutRoleConsultant;

  /// About Us — role line of the advisor card.
  ///
  /// In bn, this message translates to:
  /// **'উপদেষ্টা'**
  String get aboutRoleAdvisor;

  /// About Us — affiliation line of the lead developer card (batch 16).
  ///
  /// In bn, this message translates to:
  /// **'সিএসই বিভাগ, ব্যাচ: ১৬, কুমিল্লা বিশ্ববিদ্যালয়'**
  String get aboutInfoLeadDeveloper;

  /// About Us — affiliation line of the current maintainer card (batch 17).
  ///
  /// In bn, this message translates to:
  /// **'সিএসই বিভাগ, ব্যাচ: ১৭, কুমিল্লা বিশ্ববিদ্যালয়'**
  String get aboutInfoMaintainer;

  /// About Us — two-line affiliation of the project consultant card.
  ///
  /// In bn, this message translates to:
  /// **'মাক্রো প্রো, থাইল্যান্ডে সিনিয়র প্ল্যাটফর্ম ইঞ্জিনিয়ার\nসিএসই ১০ ব্যাচ, কুমিল্লা বিশ্ববিদ্যালয়'**
  String get aboutInfoConsultant;

  /// About Us — affiliation line of the advisor card.
  ///
  /// In bn, this message translates to:
  /// **'কুমিল্লা বিশ্ববিদ্যালয়, সিএসই বিভাগে লেকচারার'**
  String get aboutInfoAdvisor;

  /// Label for the profile dark mode setting.
  ///
  /// In bn, this message translates to:
  /// **'ডার্ক মোড'**
  String get profileDarkMode;

  /// Description for the profile dark mode setting.
  ///
  /// In bn, this message translates to:
  /// **'গাঢ় রঙের থিম ব্যবহার করুন'**
  String get profileDarkModeDescription;

  /// Badge on a route that only runs in one direction. Never applied to a linked pair — a pair is two one-way rows, not 'both ways'.
  ///
  /// In bn, this message translates to:
  /// **'একদিক'**
  String get routeOneWay;

  /// Title of the rider's saved routes: home 'My Routes' section header and the Route tab's pin sheet title.
  ///
  /// In bn, this message translates to:
  /// **'আমার রুট'**
  String get routeMyRoutes;

  /// One line under the sheet title explaining the two independent toggles: pin = shows on Home, bell = schedule-change notifications.
  ///
  /// In bn, this message translates to:
  /// **'পিন করলে হোম স্ক্রিনে দেখাবে, ঘণ্টা চালু করলে সময়সূচি বদলের বার্তা পাবেন'**
  String get routeMyRoutesHint;

  /// Trip count shown under a route name on its card.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি ট্রিপ'**
  String routeTripCount(num count);

  /// Shown when a route has no active trips yet — card sub-line and route detail empty state.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো ট্রিপ নেই'**
  String get routeNoTrips;

  /// Route tab empty state — no routes configured yet.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো রুট যোগ করা হয়নি'**
  String get routeEmpty;

  /// Tooltip/semantics for the pin toggle in the saved-routes sheet.
  ///
  /// In bn, this message translates to:
  /// **'হোম স্ক্রিনে পিন করুন'**
  String get routePinTooltip;

  /// Tooltip/semantics for the schedule-alert bell toggle in the saved-routes sheet.
  ///
  /// In bn, this message translates to:
  /// **'সময়সূচি পরিবর্তনের বার্তা পান'**
  String get routeAlertTooltip;
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
