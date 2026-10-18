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
  String get errorValidation => 'আপনার তথ্য যাচাই করে আবার চেষ্টা করুন।';

  @override
  String get errorInvalidEmail => 'সঠিক ইমেইল ঠিকানা লিখুন।';

  @override
  String get errorInvalidPhone => 'সঠিক ফোন নম্বর লিখুন।';

  @override
  String get errorOtpLength => 'ওটিপি ৬ সংখ্যার হতে হবে।';

  @override
  String get errorPasswordLength => 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';

  @override
  String get errorRoleRequired => 'অনুগ্রহ করে আপনার ভূমিকা নির্বাচন করুন।';

  @override
  String get errorUnauthorized => 'এই কাজটি করার অনুমতি আপনার নেই।';

  @override
  String get errorUserNotFound => 'অ্যাকাউন্ট পাওয়া যায়নি।';

  @override
  String get errorRollAlreadyRegistered => 'এই রোল নম্বর ইতিমধ্যে নিবন্ধিত।';

  @override
  String get errorTeacherIdAlreadyRegistered =>
      'এই শিক্ষক আইডি ইতিমধ্যে নিবন্ধিত।';

  @override
  String get errorDepartmentImmutable =>
      'বিভাগ একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।';

  @override
  String get errorRollImmutable =>
      'রোল নম্বর একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।';

  @override
  String get errorSessionImmutable =>
      'সেশন একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।';

  @override
  String get errorEmployeeIdImmutable =>
      'কর্মী আইডি একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।';

  @override
  String get errorDesignationImmutable =>
      'পদবি একবার সংরক্ষণের পর পরিবর্তন করা যাবে না।';

  @override
  String get errorEmailDomainNotAllowed =>
      'শুধুমাত্র কুমিল্লা বিশ্ববিদ্যালয়ের অফিসিয়াল ইমেইল গ্রহণযোগ্য।';

  @override
  String get errorGoogleSignInFailed =>
      'গুগল সাইন ইন যাচাই করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get errorGoogleTokenInvalid =>
      'গুগল সাইন ইন টোকেন অবৈধ অথবা ইমেইল যাচাই করা হয়নি।';

  @override
  String get errorFacultyEmailRequired =>
      'শিক্ষক হিসেবে সাইন ইন করতে স্টাফ ইমেইল (name@cou.ac.bd) ব্যবহার করুন।';

  @override
  String get errorEmailRegisteredAsTeacher =>
      'এই ইমেইলটি ইতিমধ্যে শিক্ষক হিসেবে নিবন্ধিত। শিক্ষক হিসেবে সাইন ইন করুন।';

  @override
  String get errorEmailRegisteredAsStudent =>
      'এই ইমেইলটি ইতিমধ্যে শিক্ষ্যার্থী হিসেবে নিবন্ধিত। শিক্ষ্যার্থী হিসেবে সাইন ইন করুন।';

  @override
  String get errorCannotDeleteSelf => 'আপনি নিজের অ্যাকাউন্ট মুছতে পারবেন না।';

  @override
  String get errorOtpNotFound =>
      'কোনো ওটিপি পাওয়া যায়নি। নতুন কোড অনুরোধ করুন।';

  @override
  String get errorRegistrationNotFound =>
      'নিবন্ধন পাওয়া যায়নি। প্রথমে নিবন্ধন ফর্ম জমা দিন।';

  @override
  String get errorPendingRegistrationNotFound =>
      'এই ফোন নম্বরে কোনো অপেক্ষমাণ নিবন্ধন নেই। প্রথমে নিবন্ধন ফর্ম জমা দিন।';

  @override
  String get errorProfileIncomplete =>
      'চালিয়ে যেতে অনুগ্রহ করে আপনার প্রোফাইল সম্পূর্ণ করুন।';

  @override
  String get successPasswordReset =>
      'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। নতুন পাসওয়ার্ড দিয়ে লগইন করুন।';

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

  @override
  String get navHome => 'হোম';

  @override
  String get navBuses => 'বাস';

  @override
  String get navSchedules => 'সময়সূচি';

  @override
  String get navNotices => 'নোটিশ';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get commonYes => 'হ্যাঁ';

  @override
  String get commonNo => 'না';

  @override
  String get commonUserName => 'ব্যবহারকারী';

  @override
  String get exitAppTitle => 'অ্যাপ থেকে বের হতে চান?';

  @override
  String get exitAppMessage => 'আপনি কি নিশ্চিতভাবে অ্যাপ বন্ধ করতে চান?';

  @override
  String get timeNotScheduled => 'নির্ধারিত নয়';

  @override
  String get timeMorning => 'সকাল';

  @override
  String get timeAfternoon => 'দুপুর';

  @override
  String get timeEvening => 'বিকাল';

  @override
  String get timeNight => 'রাত';

  @override
  String get busCategoryBlue => 'নীল';

  @override
  String get busCategoryRed => 'লাল';

  @override
  String get busCategoryTeacher => 'শিক্ষক';

  @override
  String get busCategoryOfficer => 'অফিসার';

  @override
  String get busCategoryStaff => 'স্টাফ';

  @override
  String get scheduleDirectionToCampus => 'ক্যাম্পাস অভিমুখে';

  @override
  String get scheduleDirectionFromCampus => 'ক্যাম্পাস থেকে';

  @override
  String get statusVerified => 'যাচাইকৃত';

  @override
  String get statusInactive => 'নিষ্ক্রিয়';

  @override
  String get statusPending => 'অপেক্ষমাণ';

  @override
  String get idCardNoText =>
      'ছবি থেকে কোনো তথ্য পড়া যায়নি। আইডি কার্ডের ছবি দিন।';

  @override
  String get idCardNotCoU =>
      'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড মনে হচ্ছে না।';

  @override
  String get idCardIsStudent =>
      'এটি শিক্ষার্থীর আইডি কার্ড। শিক্ষক আইডি কার্ড দিন।';

  @override
  String get idCardTeacherNotFound =>
      'শিক্ষক আইডি কার্ড সনাক্ত হয়নি। শিক্ষক পরিচয়পত্রের ছবি দিন।';

  @override
  String get idCardOnlyAccepted =>
      'শুধুমাত্র আইডি কার্ড গ্রহণযোগ্য। ভর্তির ফর্ম বা অন্যান্য ছবি দেওয়া যাবে না।';

  @override
  String get idCardProcessingFailed => 'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে।';

  @override
  String get notifPermissionTitle => 'বাস আপডেট পেতে নোটিফিকেশন চালু করুন';

  @override
  String get notifPermissionBody =>
      'আপনার বাসের সময়সূচি, রুট বা জরুরি কোনো পরিবর্তন হলে আমরা নোটিফিকেশনের মাধ্যমে আপনাকে জানাতে চাই। এতে গুরুত্বপূর্ণ আপডেট মিস হওয়ার সম্ভাবনা কমবে।';

  @override
  String get notifLater => 'পরে করব';

  @override
  String get notifAllow => 'অনুমতি দিন';

  @override
  String get busTrackingTitle => 'বাস ট্র্যাকিং';

  @override
  String get noInternetTitle => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get noInternetBody =>
      'ইন্টারনেট সংযোগ চালু করে রিলোড করুন।\n\nআপনার আগের ডেটা ক্যাশে সংরক্ষিত আছে।';

  @override
  String get homeReload => 'রিলোড করুন';

  @override
  String get homeCloseApp => 'অ্যাপ বন্ধ করুন';

  @override
  String get homeExitMessage => 'আপনি কি নিশ্চিত যে অ্যাপ থেকে বের হতে চান?';

  @override
  String get todayScheduleTitle => 'আজকের সময়সূচি';

  @override
  String get homeGreeting => 'আসসালামু আলাইকুম,';

  @override
  String get appName => 'কুবি যাত্রা';

  @override
  String get homeBrandTagline => 'CoU যাত্রী';

  @override
  String get menuTooltip => 'মেনু';

  @override
  String homeActiveBusCount(num count) {
    return '$count টি বাস সক্রিয় আছে';
  }

  @override
  String countBuses(num count) {
    return '$count টি বাস';
  }

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get noScheduleToday => 'আজকে আর কোনো শিডিউল নেই';

  @override
  String get offlineBanner => 'অফলাইন • সংরক্ষিত তথ্য দেখানো হচ্ছে';

  @override
  String get profileTitle => 'প্রোফাইল';

  @override
  String get profileYourProfile => 'আপনার প্রোফাইল';

  @override
  String get profileLoginPrompt =>
      'বাসের তথ্য ও সঠিক শিডিউল ট্র্যাক করতে আপনার অ্যাকাউন্টে লগইন করুন';

  @override
  String get profileLoginRegister => 'লগইন / নিবন্ধন করুন';

  @override
  String get roleStudent => 'শিক্ষার্থী';

  @override
  String get roleTeacher => 'শিক্ষক';

  @override
  String get profileIdCard => 'আইডি কার্ড';

  @override
  String get profileTapToViewPhoto => 'ছবি দেখতে ট্যাপ করুন';

  @override
  String get profileName => 'নাম';

  @override
  String get profileEmail => 'ইমেইল';

  @override
  String get profileRole => 'ভূমিকা';

  @override
  String get profileLogout => 'লগ আউট';

  @override
  String get scheduleTeacherBus => 'শিক্ষক বাস';

  @override
  String get scheduleStudentBus => 'শিক্ষার্থী বাস';

  @override
  String get scheduleTitle => 'সময়সূচি';

  @override
  String get scheduleSearchHint => 'শিডিউল খুঁজুন (সময় বা রুট)...';

  @override
  String get scheduleFilterToday => 'আজকের তালিকা';

  @override
  String get scheduleFilterWorking => 'কর্মদিবস';

  @override
  String get scheduleFilterWeekend => 'শুক্র ও শনিবার';

  @override
  String get filterAll => 'সব';

  @override
  String get scheduleEmpty => 'আজকে কোনো শিডিউল নেই';

  @override
  String get busSearchHint => 'বাস খুঁজুন...';

  @override
  String get busRouteMissing => 'রুট তথ্য নেই';

  @override
  String get busListEmpty => 'কোনো বাস পাওয়া যায়নি';

  @override
  String get trackingConnecting => 'সংযুক্ত হচ্ছে...';

  @override
  String get trackingGpsOff => 'GPS বন্ধ';

  @override
  String get trackingPermissionDenied => 'অনুমতি নেই';

  @override
  String get trackingPermissionBlocked => 'অনুমতি ব্লক';

  @override
  String get trackingFastUpdateHint =>
      'দ্রুত আপডেট পেতে নিচের বাম পাশের ড্রপডাউন থেকে ৫ সেঃ সিলেক্ট করুন';

  @override
  String get trackingNoInternetBody =>
      'বাসের লোকেশন দেখতে ইন্টারনেট সংযোগ চালু করে\nআবার চেষ্টা করুন।';

  @override
  String get roleSelectTitle => 'আপনার ভূমিকা';

  @override
  String get roleChoosePrompt => 'আপনার ভূমিকা নির্বাচন করুন';

  @override
  String get roleLoginRegisterHint =>
      'লগইন বা নিবন্ধনের জন্য ভূমিকা বাছাই করুন';

  @override
  String get roleStudentSubtitle => 'ছাত্র হিসেবে লগইন বা নিবন্ধন করুন';

  @override
  String get roleTeacherSubtitle => 'শিক্ষক হিসেবে লগইন বা নিবন্ধন করুন';

  @override
  String get driverInfoTitle => 'ড্রাইভার তথ্য';

  @override
  String get scheduleRouteTitle => 'শিডিউল ও রুট';

  @override
  String get busSeeLiveLocation => 'লাইভ লোকেশন দেখুন';

  @override
  String get commonError => 'ত্রুটি';

  @override
  String get forceUpdateTitle => 'আপডেট প্রয়োজন';

  @override
  String get newVersionTitle => 'নতুন ভার্সন পাওয়া গেছে';

  @override
  String get newVersionBody => 'অ্যাপের নতুন ভার্সন পাওয়া গেছে। আপডেট করুন।';

  @override
  String get updateNow => 'আপডেট করুন';

  @override
  String get updateLater => 'পরে করুন';

  @override
  String get noticeTitle => 'নোটিশ';

  @override
  String get noticeExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get noticeActive => 'সক্রিয়';

  @override
  String get noticeEmpty => 'এখন কোনো সক্রিয় নোটিশ নেই';

  @override
  String get maintenanceTitle => 'রক্ষণাবেক্ষণ';

  @override
  String get maintenanceBody => 'অ্যাপটি রক্ষণাবেক্ষণে আছে। শীঘ্রই ফিরে আসছি।';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonOk => 'ঠিক আছে';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get fieldFullName => 'পুরো নাম';

  @override
  String get fieldPhoneNumber => 'ফোন নম্বর';

  @override
  String get fieldEmail => 'ইমেইল';

  @override
  String get fieldPassword => 'পাসওয়ার্ড';

  @override
  String get fieldPasswordConfirm => 'পাসওয়ার্ড আবার দিন';

  @override
  String get fieldNewPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get fieldRollNumber => 'রোল নম্বর';

  @override
  String get fieldTeacherId => 'শিক্ষক আইডি';

  @override
  String get fieldEmployeeId => 'কর্মচারী আইডি';

  @override
  String get fieldId => 'আইডি';

  @override
  String get fieldDesignation => 'পদবী';

  @override
  String get fieldDepartment => 'বিভাগ';

  @override
  String get fieldDepartmentOffice => 'বিভাগ/অফিস';

  @override
  String get fieldSession => 'সেশন';

  @override
  String get validationNameRequired => 'নাম দিন';

  @override
  String get validationNameLength => 'নাম ২ থেকে ১০০ অক্ষরের হতে হবে';

  @override
  String get validationPhoneRequired => 'ফোন নম্বর দিন';

  @override
  String get validationPhoneInvalid => 'সঠিক ফোন নম্বর দিন (01XXXXXXXXX)';

  @override
  String get validationEmailRequired => 'ইমেইল দিন';

  @override
  String get validationEmailInvalid => 'সঠিক ইমেইল দিন';

  @override
  String get validationPasswordRequired => 'পাসওয়ার্ড দিন';

  @override
  String get validationPasswordLength8 =>
      'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';

  @override
  String get validationPasswordLength6 =>
      'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';

  @override
  String get validationPasswordMismatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get validationDepartmentRequired => 'বিভাগ দিন';

  @override
  String get validationDepartmentLength => 'বিভাগ ২ থেকে ১০০ অক্ষরের হতে হবে';

  @override
  String get validationSessionRequired => 'সেশন দিন';

  @override
  String get validationSessionFormat =>
      'সেশন সঠিকভাবে দিন (যেমন: 16, 2020, 2021-22, অথবা 2020-2024)';

  @override
  String get validationRollRequired => 'রোল নম্বর দিন';

  @override
  String get validationRollLength => 'রোল নম্বর ২-৫০ অক্ষরের হতে হবে';

  @override
  String get validationEmployeeIdRequired => 'কর্মচারী আইডি দিন';

  @override
  String get validationEmployeeIdLength => 'কর্মচারী আইডি ২-৫০ অক্ষরের হতে হবে';

  @override
  String get validationDesignationRequired => 'পদবী দিন';

  @override
  String get validationDesignationLength => 'পদবী ১০০ অক্ষরের হতে হবে';

  @override
  String get validationIdRequired => 'আইডি দিন';

  @override
  String get selectDepartment => 'বিভাগ নির্বাচন করুন';

  @override
  String get selectDepartmentOffice => 'বিভাগ/অফিস নির্বাচন করুন';

  @override
  String get selectSession => 'সেশন নির্বাচন করুন';

  @override
  String get hintExampleRoll => 'যেমন: 12208055';

  @override
  String get hintExampleEmployeeId => 'যেমন: 1234';

  @override
  String get hintExampleDesignation => 'যেমন: সহযোগী অধ্যাপক';

  @override
  String get hintExamplePhone => 'যেমন: 01712345678';

  @override
  String get authLogin => 'লগইন করুন';

  @override
  String get authRegister => 'নিবন্ধন করুন';

  @override
  String get authLoginBack => 'লগইনে ফিরে যান';

  @override
  String get authForgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get authNoAccount => 'অ্যাকাউন্ট নেই? ';

  @override
  String get authHaveAccount => 'ইতিমধ্যে অ্যাকাউন্ট আছে? ';

  @override
  String get authStudentLogin => 'শিক্ষার্থী লগইন';

  @override
  String get authTeacherLogin => 'শিক্ষক লগইন';

  @override
  String get authTeacherOfficerLogin => 'শিক্ষক ও কর্মকর্তাবৃন্দ লগইন';

  @override
  String get authStudentRegister => 'শিক্ষার্থী নিবন্ধন';

  @override
  String get authTeacherRegister => 'শিক্ষক নিবন্ধন';

  @override
  String get authTeacherOfficerRegister => 'শিক্ষক ও কর্মকর্তাবৃন্দ নিবন্ধন';

  @override
  String get passwordResetTitle => 'পাসওয়ার্ড রিসেট';

  @override
  String get authPhoneVerificationTitle => 'ফোন নম্বর যাচাইকরণ';

  @override
  String get authEmailVerificationTitle => 'ইমেইল যাচাইকরণ';

  @override
  String get loginSubtitle => 'ফোন নম্বর ও পাসওয়ার্ড দিয়ে লগইন করুন';

  @override
  String get forgotPhoneSubtitle => 'আপনার ফোন নম্বর দিন, আমরা OTP পাঠাবো';

  @override
  String get forgotEmailSubtitle => 'আপনার ইমেইল দিন, আমরা OTP পাঠাবো';

  @override
  String get emailLoginSubtitleEdu => 'এডুমেইল ও পাসওয়ার্ড দিয়ে লগইন করুন';

  @override
  String get emailLoginSubtitleInst =>
      'প্রতিষ্ঠানিক ইমেইল ও পাসওয়ার্ড দিয়ে লগইন করুন';

  @override
  String get emailFieldEdu => 'এডুমেইল';

  @override
  String get emailFieldInst => 'প্রতিষ্ঠানিক ইমেইল';

  @override
  String get emailRegisterSubtitleEdu =>
      'আপনার এডুমেইলের মাধ্যমে OTP নিবন্ধন করুন';

  @override
  String get emailRegisterSubtitleInst =>
      'আপনার প্রতিষ্ঠানিক ইমেইলের মাধ্যমে OTP নিবন্ধন করুন';

  @override
  String get noEduMailHintEdu =>
      'যদি আপনার এডুমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন';

  @override
  String get noEduMailHintInst =>
      'যদি আপনার প্রতিষ্ঠানিক ইমেইল না থাকে, তাহলে আইসিটি সেলে যোগাযগ করুন';

  @override
  String get googleSignInSubtitle =>
      'বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্ট দিয়ে প্রবেশ করুন';

  @override
  String get googleInstitutionalPrompt =>
      'আপনার বিশ্ববিদ্যালয়ের প্রাতিষ্ঠানিক ইমেইল ব্যবহার করে প্রবেশ করুন।';

  @override
  String get googleEmailFormatLabel => 'প্রয়োজনীয় ইমেইল ফরমেট:';

  @override
  String get googleIctHelp =>
      'আপনার বিশ্ববিদ্যালয় ইমেইল না থাকলে অনুগ্রহ করে কুমিল্লা বিশ্ববিদ্যালয়ের আইসিটি সেলের সঙ্গে যোগাযোগ করুন।';

  @override
  String get googleSignInButton => 'গুগল অ্যাকাউন্ট দিয়ে প্রবেশ করুন';

  @override
  String get googleSignInCancelled => 'প্রবেশ বাতিল করা হয়েছে।';

  @override
  String get googleSignInConfigError =>
      'গুগল সাইন-ইন কনফিগারেশনে সমস্যা হয়েছে। যোগাযোগ করুন।';

  @override
  String get googleGmailReminderTitle => 'এগিয়ে যাওয়ার আগে';

  @override
  String get googleGmailReminderMessage =>
      'আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টে প্রবেশাধিকার আছে এবং অ্যাকাউন্টটি Gmail অ্যাপে আগে থেকেই সাইন ইন করা আছে কিনা নিশ্চিত করুন। সাইন ইন করার সময় আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টটি নির্বাচন করুন।';

  @override
  String get uploadIdTitle => 'আইডি কার্ড আপলোড';

  @override
  String get uploadIdSubtitle => 'আপনার বিশ্ববিদ্যালয়ের পরিচয়পত্র আপলোড করুন';

  @override
  String get uploadIdSuccess => 'আইডি কার্ড সফলভাবে আপলোড হয়েছে';

  @override
  String get selectPhoto => 'ছবি সিলেক্ট করুন';

  @override
  String get completeUpload => 'আপলোড সম্পন্ন করুন';

  @override
  String get authSendOtp => 'OTP পাঠান';

  @override
  String get authVerifyOtp => 'OTP যাচাই করুন';

  @override
  String get authVerify => 'যাচাই করুন';

  @override
  String get authResendCode => 'আবার কোড পাঠান';

  @override
  String get authChangePhoneBack => 'ফোন নম্বর পরিবর্তন / নিবন্ধনে ফিরে যান';

  @override
  String get authChangeEmailBack => 'ইমেইল পরিবর্তন / নিবন্ধনে ফিরে যান';

  @override
  String get authCodeNotReceived => 'কোডটি পাননি?';

  @override
  String authResendCountdown(String remaining) {
    return 'নতুন কোড পাঠাতে $remaining অবশিষ্ট';
  }

  @override
  String get otpDigitHint => '৬ ডিজিট OTP';

  @override
  String get otpDigitRequired => '৬ ডিজিট OTP দিন';

  @override
  String get resetPasswordButton => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String otpSentToPhone(String phone) {
    return '$phone নম্বরে OTP পাঠানো হয়েছে';
  }

  @override
  String otpSentToEmail(String email) {
    return '$email ইমেইলে OTP পাঠানো হয়েছে';
  }

  @override
  String get otpIncomplete => '৬ সংখ্যার কোডটি সম্পূর্ণ লিখুন।';

  @override
  String get verificationFailedFallback =>
      'ভেরিফিকেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get otpExpiredResent =>
      'OTP মেয়াদোত্তীর্ণ হয়েছে। নতুন OTP পাঠানো হয়েছে।';

  @override
  String get codeSendFailed => 'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।';

  @override
  String get phoneVerifySubtitle =>
      'আমরা আপনার ফোনে ৬ সংখ্যার একটি verification code পাঠিয়েছি।';

  @override
  String get emailVerifySubtitle =>
      'আমরা আপনার ইমেইলে ৬ সংখ্যার একটি verification code পাঠিয়েছি।';

  @override
  String get invalidImageType =>
      'শুধুমাত্র JPG, JPEG বা PNG ছবি নির্বাচন করুন।';

  @override
  String get idCardDetectedTeacher => '✅ শিক্ষক আইডি কার্ড সনাক্ত হয়েছে';

  @override
  String get idCardDetected => '✅ আইডি কার্ড সনাক্ত হয়েছে';

  @override
  String get photoUploaded => '✅ ছবি আপলোড হয়েছে';

  @override
  String get autoFilledInfo =>
      'তথ্য স্বয়ংক্রিয়ভাবে পূরণ হয়েছে। পরীক্ষা করে নিন।';

  @override
  String get photoValidationFailed => 'ছবি যাচাইয়ে সমস্যা হয়েছে।';

  @override
  String get registerSubtitle => 'আইডি কার্ড অথবা ভর্তির ফর্ম আপলোড করুন';

  @override
  String get otpWillBeSentToPhone => 'নিবন্ধনের পর এই নম্বরে OTP পাঠানো হবে';

  @override
  String get uploadDocStudent => 'আইডি কার্ড বা ভর্তির ফর্ম — যেকোনো একটি দিন!';

  @override
  String get uploadDocTeacher => 'শিক্ষক আইডি কার্ড আপলোড করুন';

  @override
  String get uploadGuidelinesStudent =>
      '• আইডি কার্ড আছে → আইডি কার্ডের ছবি আপলোড করুন\n• আইডি কার্ড নেই → ভর্তির ফর্ম / ভর্তি ভাউচারের ছবি আপলোড করুন\n• উভয়ই কুমিল্লা বিশ্ববিদ্যালয়ের হতে হবে';

  @override
  String get uploadGuidelinesTeacher =>
      '• শিক্ষক পরিচয়পত্রের ছবি আপলোড করুন\n• কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড হতে হবে\n• ডিপার্টমেন্ট ও পদবি স্বয়ংক্রিয়ভাবে পূরণ হবে';

  @override
  String get docPhotoLabelStudent =>
      'পরিচয়পত্র / ভর্তির ফর্মের ছবি (MANDATORY)';

  @override
  String get docPhotoLabelTeacher => 'শিক্ষক পরিচয়পত্রের ছবি (MANDATORY)';

  @override
  String get photoFormatStudent => '(JPG/PNG — আইডি কার্ড অথবা ভর্তির ফর্ম)';

  @override
  String get photoFormatTeacher => '(JPG/PNG — শিক্ষক আইডি কার্ড)';

  @override
  String photoSizeMb(String size) {
    return 'ছবির সাইজ: $size MB';
  }

  @override
  String photoSizeKb(String size) {
    return 'ছবির সাইজ: $size KB';
  }

  @override
  String get photoValidatingIndicator => 'ছবি যাচাই করা হচ্ছে...';

  @override
  String get registerDocTitle => 'নথি প্রয়োজন';

  @override
  String get registerDocRequiredMsg =>
      'নিবন্ধন সম্পন্ন করতে আপনার বিশ্ববিদ্যালয় আইডি কার্ড অথবা ভর্তির ফর্মের ছবি আপলোড করা বাধ্যতামূলক।';

  @override
  String get photoValidatingDialog => 'ছবি যাচাই হচ্ছে... অপেক্ষা করুন।';

  @override
  String get validIdCardPrompt => 'সঠিক আইডি কার্ড দিন।';

  @override
  String get academicStudentTitle => 'শিক্ষার্থীর তথ্য সম্পূর্ণ করুন';

  @override
  String get academicStaffTitle => 'শিক্ষক ও কর্মকর্তাদের তথ্য সম্পূর্ণ করুন';

  @override
  String get academicSubtitle => 'অ্যাকাউন্ট ব্যবহার করতে নিচের তথ্যগুলো দিন।';

  @override
  String get academicOnceOnlyNote =>
      'এই তথ্য একবার দেওয়ার পর পরিবর্তন করা যাবে না। সঠিকভাবে দিন।';

  @override
  String get academicHelperOnce => 'একবার দেওয়ার পর পরিবর্তন করা যাবে না';

  @override
  String get academicSave => 'সংরক্ষণ করুন';

  @override
  String get academicLogoutTitle => 'লগ আউট করবেন?';

  @override
  String get academicLogoutBody =>
      'তথ্য ছাড়া অ্যাকাউন্ট ব্যবহার করা যাবে না। পরে আবার লগইন করে পূরণ করতে পারবেন।';

  @override
  String get errorVerifyOtpNoToken =>
      'ভেরিফিকেশন সফল হলেও টোকেন পাওয়া যায়নি। আবার চেষ্টা করুন।';

  @override
  String get otpSent => 'OTP পাঠানো হয়েছে';

  @override
  String get otpResent => 'OTP পুনরায় পাঠানো হয়েছে';

  @override
  String get errorUnknownResponse => 'Unknown response';

  @override
  String get deptCse => 'কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং (CSE)';

  @override
  String get deptMathematics => 'গণিত';

  @override
  String get deptPhysics => 'পদার্থবিজ্ঞান';

  @override
  String get deptStatistics => 'পরিসংখ্যান';

  @override
  String get deptChemistry => 'রসায়ন';

  @override
  String get deptPharmacy => 'ফার্মেসি';

  @override
  String get deptEnglish => 'ইংরেজি';

  @override
  String get deptBangla => 'বাংলা';

  @override
  String get deptEconomics => 'অর্থনীতি';

  @override
  String get deptPublicAdministration => 'লোক প্রশাসন';

  @override
  String get deptAnthropology => 'নৃবিজ্ঞান';

  @override
  String get deptMassCommunication => 'গণযোগাযোগ ও সাংবাদিকতা';

  @override
  String get deptArchaeology => 'প্রত্নতত্ত্ব';

  @override
  String get deptManagement => 'ব্যবস্থাপনা শিক্ষা';

  @override
  String get deptAccounting => 'অ্যাকাউন্টিং অ্যান্ড ইনফরমেশন সিস্টেমস';

  @override
  String get deptMarketing => 'মার্কেটিং';

  @override
  String get deptFinance => 'ফাইন্যান্স অ্যান্ড ব্যাংকিং';

  @override
  String get deptIct => 'ইনফরমেশন অ্যান্ড কমিউনিকেশন টেকনোলজি (ICT)';

  @override
  String get deptLaw => 'আইন';

  @override
  String get officeVc => 'উপাচার্যের কার্যালয়';

  @override
  String get officeProVc => 'উপ-উপাচার্যের কার্যালয়';

  @override
  String get officeTreasurer => 'কোষাধ্যক্ষের কার্যালয়';

  @override
  String get officeRegistrar => 'রেজিস্ট্রারের কার্যালয়';

  @override
  String get officeProctor => 'প্রক্টরের কার্যালয়';

  @override
  String get officeResearchExtension =>
      'গবেষণা ও সম্প্রসারণ পরিচালকের কার্যালয়';

  @override
  String get officeEstate => 'এস্টেট শাখা';

  @override
  String get officeSecurity => 'নিরাপত্তা শাখা';

  @override
  String get officeCentralStore => 'কেন্দ্রীয় স্টোর';

  @override
  String get officeFinanceAccounts => 'অর্থ ও হিসাব পরিচালকের কার্যালয়';

  @override
  String get officeExaminations => 'পরীক্ষা নিয়ন্ত্রকের কার্যালয়';

  @override
  String get officePlanningDevelopment =>
      'পরিকল্পনা ও উন্নয়ন পরিচালকের কার্যালয়';

  @override
  String get officeLibrary => 'কেন্দ্রীয় গ্রন্থাগার';

  @override
  String get officeEngineering => 'প্রকৌশল কার্যালয়';

  @override
  String get officeMedical => 'মেডিকেল সেন্টার';

  @override
  String get officeIctCell => 'আইসিটি সেল';

  @override
  String get officePhysicalEducation => 'শারীরিক শিক্ষা কার্যালয়';

  @override
  String get officePublicRelations => 'জনসংযোগ কার্যালয়';

  @override
  String get officeCentralMosque => 'কেন্দ্রীয় মসজিদ';

  @override
  String get officeTransportPool => 'পরিবহন পুল';

  @override
  String get officeCounseling => 'শিক্ষার্থী কাউন্সেলিং ও গাইডেন্স';

  @override
  String get officeInternationalRelations => 'আন্তর্জাতিক সম্পর্ক';

  @override
  String get officeCareerDevelopment => 'ক্যারিয়ার ডেভেলপমেন্ট সেন্টার';

  @override
  String get session2016 => '২০১৬-২০১৭';

  @override
  String get session2017 => '২০১৭-২০১৮';

  @override
  String get session2018 => '২০১৮-২০১৯';

  @override
  String get session2019 => '২০১৯-২০২০';

  @override
  String get session2020 => '২০২০-২০২১';

  @override
  String get session2021 => '২০২১-২০২২';

  @override
  String get session2022 => '২০২২-২০২৩';

  @override
  String get session2023 => '২০২৩-২০২৪';

  @override
  String get session2024 => '২০২৪-২০২৫';

  @override
  String get session2025 => '২০২৫-২০২৬';
}
