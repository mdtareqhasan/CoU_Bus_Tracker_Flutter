// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get sessionExpiredMessage =>
      'আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার লগইন করুন।';

  @override
  String get errorBadRequest => 'তথ্য সঠিক নয়। আবার চেষ্টা করুন।';

  @override
  String get errorSessionExpired => 'সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';

  @override
  String get errorForbidden => 'অনুমতি নেই।';

  @override
  String get errorNotFound => 'তথ্যটি পাওয়া যায়নি।';

  @override
  String get errorEmailTaken => 'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।';

  @override
  String get errorServerIssue =>
      'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';

  @override
  String get errorNetwork => 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';

  @override
  String get errorServerBusy =>
      'সার্ভার চালু হচ্ছে বা সাময়িকভাবে ব্যস্ত। ১–২ মিনিট পরে আবার চেষ্টা করুন।';

  @override
  String get errorDefault => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorColdStart =>
      'সার্ভার চালু হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...';

  @override
  String get errorInvalidLogin => 'ইমেইল অথবা পাসওয়ার্ড সঠিক নয়।';

  @override
  String get errorInvalidOtp => 'ভুল ওটিপি। আবার চেষ্টা করুন।';

  @override
  String get errorOtpExpired => 'ওটিপির মেয়াদ শেষ হয়ে গেছে। আবার কোড পাঠান।';

  @override
  String get errorOtpExceeded =>
      'অনেকবার ভুল চেষ্টা। ওটিপি বাতিল হয়েছে। আবার কোড পাঠান।';

  @override
  String get errorResendCooldown => 'আবার কোড পাঠাতে একটু অপেক্ষা করুন।';

  @override
  String get errorVerifyPhoneFirst =>
      'অনুগ্রহ করে লগইন করার আগে আপনার ফোন নম্বর যাচাই করুন।';

  @override
  String get errorVerifyEmailFirst =>
      'অনুগ্রহ করে লগইন করার আগে আপনার ইমেইল যাচাই করুন।';

  @override
  String get errorPhoneNotFound =>
      'এই ফোন নম্বরে কোনো ব্যবহারকারী নেই। প্রথমে নিবন্ধন করুন।';

  @override
  String get errorAccountDeactivated =>
      'আপনার অ্যাকাউন্ট নিষ্ক্রিয়। অ্যাডমিনের সাথে যোগাযোগ করুন।';

  @override
  String get errorPhoneAlreadyUsed => 'এই ফোন নম্বর ইতিমধ্যে ব্যবহৃত হয়েছে।';

  @override
  String get errorAccountNotFound =>
      'আপনার অ্যাকাউন্ট পাওয়া যায়নি। আগে নিবন্ধন করুন।';

  @override
  String get homeStatActiveBuses => 'সক্রিয় বাস';

  @override
  String get homeStatTodayTrips => 'আজকের ট্রিপ';

  @override
  String get homeStatLiveTracking => 'লাইভ ট্র্যাকিং';

  @override
  String get homeStatUrgentNotice => 'জরুরি নোটিশ';

  @override
  String get profileLanguage => 'ভাষা';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get languageEnglish => 'English';
}
