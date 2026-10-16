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
  String get errorValidation => 'Please check your information and try again.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorInvalidPhone => 'Please enter a valid phone number.';

  @override
  String get errorOtpLength => 'The OTP must be 6 digits.';

  @override
  String get errorPasswordLength => 'Password must be at least 6 characters.';

  @override
  String get errorRoleRequired => 'Please select your role.';

  @override
  String get errorUnauthorized => 'You are not authorized to do this.';

  @override
  String get errorUserNotFound => 'Account not found.';

  @override
  String get errorRollAlreadyRegistered =>
      'This roll number is already registered.';

  @override
  String get errorTeacherIdAlreadyRegistered =>
      'This teacher ID is already registered.';

  @override
  String get errorDepartmentImmutable =>
      'Department cannot be changed once it has been set.';

  @override
  String get errorRollImmutable =>
      'Roll number cannot be changed once it has been set.';

  @override
  String get errorSessionImmutable =>
      'Session cannot be changed once it has been set.';

  @override
  String get errorEmployeeIdImmutable =>
      'Employee ID cannot be changed once it has been set.';

  @override
  String get errorDesignationImmutable =>
      'Designation cannot be changed once it has been set.';

  @override
  String get errorEmailDomainNotAllowed =>
      'Only official Comilla University email addresses are allowed.';

  @override
  String get errorGoogleSignInFailed =>
      'Could not verify the Google sign-in. Please try again.';

  @override
  String get errorGoogleTokenInvalid =>
      'The Google sign-in token is invalid or the email is not verified.';

  @override
  String get errorFacultyEmailRequired =>
      'To sign in as a teacher, use a staff email (name@cou.ac.bd).';

  @override
  String get errorCannotDeleteSelf => 'You cannot delete your own account.';

  @override
  String get errorOtpNotFound => 'No OTP found. Please request a new one.';

  @override
  String get errorRegistrationNotFound =>
      'Registration not found. Please submit the registration form first.';

  @override
  String get errorPendingRegistrationNotFound =>
      'No pending registration found for this phone. Please submit the registration form first.';

  @override
  String get errorProfileIncomplete =>
      'Please complete your profile to continue.';

  @override
  String get successPasswordReset =>
      'Password reset successfully. Log in with your new password.';

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

  @override
  String get navHome => 'Home';

  @override
  String get navBuses => 'Buses';

  @override
  String get navSchedules => 'Schedules';

  @override
  String get navNotices => 'Notices';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonUserName => 'User';

  @override
  String get exitAppTitle => 'Leave the app?';

  @override
  String get exitAppMessage => 'Are you sure you want to close the app?';

  @override
  String get timeNotScheduled => 'Not scheduled';

  @override
  String get timeMorning => 'Morning';

  @override
  String get timeAfternoon => 'Afternoon';

  @override
  String get timeEvening => 'Evening';

  @override
  String get timeNight => 'Night';

  @override
  String get busCategoryBlue => 'Blue';

  @override
  String get busCategoryRed => 'Red';

  @override
  String get busCategoryTeacher => 'Teacher';

  @override
  String get busCategoryOfficer => 'Officer';

  @override
  String get busCategoryStaff => 'Staff';

  @override
  String get scheduleDirectionToCampus => 'To campus';

  @override
  String get scheduleDirectionFromCampus => 'From campus';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusPending => 'Pending';

  @override
  String get idCardNoText =>
      'Nothing could be read from the image. Please provide a photo of the ID card.';

  @override
  String get idCardNotCoU =>
      'This does not look like a Comilla University ID card.';

  @override
  String get idCardIsStudent =>
      'This is a student ID card. Please provide a teacher ID card.';

  @override
  String get idCardTeacherNotFound =>
      'Teacher ID card not detected. Please provide a photo of the teacher ID card.';

  @override
  String get idCardOnlyAccepted =>
      'Only ID cards are accepted. Admission forms or other photos cannot be used.';

  @override
  String get idCardProcessingFailed =>
      'There was a problem processing the image.';

  @override
  String get notifPermissionTitle => 'Enable notifications for bus updates';

  @override
  String get notifPermissionBody =>
      'We would like to notify you about schedule, route, or emergency changes so you don\'t miss important updates.';

  @override
  String get notifLater => 'Later';

  @override
  String get notifAllow => 'Allow';

  @override
  String get busTrackingTitle => 'Bus Tracking';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetBody =>
      'Turn on your internet connection and reload.\n\nYour previous data is saved in the cache.';

  @override
  String get homeReload => 'Reload';

  @override
  String get homeCloseApp => 'Close app';

  @override
  String get homeExitMessage => 'Are you sure you want to leave the app?';

  @override
  String get todayScheduleTitle => 'Today\'s schedule';

  @override
  String get homeGreeting => 'Assalamu Alaikum,';

  @override
  String get appName => 'Kubi Jatra';

  @override
  String get homeBrandTagline => 'CoU Passenger';

  @override
  String get menuTooltip => 'Menu';

  @override
  String homeActiveBusCount(num count) {
    return '$count buses are active';
  }

  @override
  String countBuses(num count) {
    return '$count buses';
  }

  @override
  String get seeAll => 'See all';

  @override
  String get noScheduleToday => 'No more schedules for today';

  @override
  String get offlineBanner => 'Offline • Showing saved data';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileYourProfile => 'Your profile';

  @override
  String get profileLoginPrompt =>
      'Log in to your account to track bus information and accurate schedules';

  @override
  String get profileLoginRegister => 'Log in / Register';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get profileIdCard => 'ID card';

  @override
  String get profileTapToViewPhoto => 'Tap to view the photo';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileRole => 'Role';

  @override
  String get profileLogout => 'Log out';

  @override
  String get scheduleTeacherBus => 'Teacher bus';

  @override
  String get scheduleStudentBus => 'Student bus';

  @override
  String get scheduleTitle => 'Schedules';

  @override
  String get scheduleSearchHint => 'Search schedules (time or route)...';

  @override
  String get scheduleFilterToday => 'Today\'s list';

  @override
  String get scheduleFilterWorking => 'Working days';

  @override
  String get scheduleFilterWeekend => 'Friday & Saturday';

  @override
  String get filterAll => 'All';

  @override
  String get scheduleEmpty => 'No schedules today';

  @override
  String get busSearchHint => 'Search buses...';

  @override
  String get busRouteMissing => 'No route information';

  @override
  String get busListEmpty => 'No buses found';

  @override
  String get trackingConnecting => 'Connecting...';

  @override
  String get trackingGpsOff => 'GPS off';

  @override
  String get trackingPermissionDenied => 'Permission denied';

  @override
  String get trackingPermissionBlocked => 'Permission blocked';

  @override
  String get trackingFastUpdateHint =>
      'For faster updates, select 5 sec from the dropdown at the bottom left';

  @override
  String get trackingNoInternetBody =>
      'Turn on your internet connection to see the bus location\nand try again.';

  @override
  String get roleSelectTitle => 'Your role';

  @override
  String get roleChoosePrompt => 'Select your role';

  @override
  String get roleLoginRegisterHint => 'Pick a role to log in or register';

  @override
  String get roleStudentSubtitle => 'Log in or register as a student';

  @override
  String get roleTeacherSubtitle => 'Log in or register as a teacher';

  @override
  String get driverInfoTitle => 'Driver information';

  @override
  String get scheduleRouteTitle => 'Schedule & route';

  @override
  String get busSeeLiveLocation => 'See live location';

  @override
  String get commonError => 'Error';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get newVersionTitle => 'New version available';

  @override
  String get newVersionBody =>
      'A new version of the app is available. Please update.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get noticeTitle => 'Notices';

  @override
  String get noticeExpired => 'Expired';

  @override
  String get noticeActive => 'Active';

  @override
  String get noticeEmpty => 'There are no active notices right now';

  @override
  String get maintenanceTitle => 'Maintenance';

  @override
  String get maintenanceBody =>
      'The app is under maintenance. We\'ll be back soon.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldPhoneNumber => 'Phone number';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordConfirm => 'Confirm password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldRollNumber => 'Roll number';

  @override
  String get fieldTeacherId => 'Teacher ID';

  @override
  String get fieldEmployeeId => 'Employee ID';

  @override
  String get fieldId => 'ID';

  @override
  String get fieldDesignation => 'Designation';

  @override
  String get fieldDepartment => 'Department';

  @override
  String get fieldDepartmentOffice => 'Department/Office';

  @override
  String get fieldSession => 'Session';

  @override
  String get validationNameRequired => 'Enter your name';

  @override
  String get validationNameLength => 'Name must be 2 to 100 characters';

  @override
  String get validationPhoneRequired => 'Enter your phone number';

  @override
  String get validationPhoneInvalid =>
      'Enter a valid phone number (01XXXXXXXXX)';

  @override
  String get validationEmailRequired => 'Enter your email';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get validationPasswordLength8 =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordLength6 =>
      'Password must be at least 6 characters';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationDepartmentRequired => 'Enter your department';

  @override
  String get validationDepartmentLength =>
      'Department must be 2-100 characters';

  @override
  String get validationSessionRequired => 'Enter your session';

  @override
  String get validationSessionFormat =>
      'Enter a valid session (e.g. 16, 2020, 2021-22, or 2020-2024)';

  @override
  String get validationRollRequired => 'Enter your roll number';

  @override
  String get validationRollLength => 'Roll number must be 2-50 characters';

  @override
  String get validationEmployeeIdRequired => 'Enter your employee ID';

  @override
  String get validationEmployeeIdLength =>
      'Employee ID must be 2-50 characters';

  @override
  String get validationDesignationRequired => 'Enter your designation';

  @override
  String get validationDesignationLength =>
      'Designation must be at most 100 characters';

  @override
  String get validationIdRequired => 'Enter your ID';

  @override
  String get selectDepartment => 'Select department';

  @override
  String get selectDepartmentOffice => 'Select department/office';

  @override
  String get selectSession => 'Select session';

  @override
  String get hintExampleRoll => 'e.g. 12208055';

  @override
  String get hintExampleEmployeeId => 'e.g. 1234';

  @override
  String get hintExampleDesignation => 'e.g. Associate Professor';

  @override
  String get hintExamplePhone => 'e.g. 01712345678';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Register';

  @override
  String get authLoginBack => 'Back to log in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authStudentLogin => 'Student login';

  @override
  String get authTeacherLogin => 'Teacher login';

  @override
  String get authTeacherOfficerLogin => 'Teachers & officers login';

  @override
  String get authStudentRegister => 'Student registration';

  @override
  String get authTeacherRegister => 'Teacher registration';

  @override
  String get authTeacherOfficerRegister => 'Teachers & officers registration';

  @override
  String get passwordResetTitle => 'Password reset';

  @override
  String get authPhoneVerificationTitle => 'Phone number verification';

  @override
  String get authEmailVerificationTitle => 'Email verification';

  @override
  String get loginSubtitle => 'Log in with your phone number and password';

  @override
  String get forgotPhoneSubtitle =>
      'Enter your phone number and we\'ll send an OTP';

  @override
  String get forgotEmailSubtitle => 'Enter your email and we\'ll send an OTP';

  @override
  String get emailLoginSubtitleEdu => 'Log in with your Edumail and password';

  @override
  String get emailLoginSubtitleInst =>
      'Log in with your institutional email and password';

  @override
  String get emailFieldEdu => 'Edumail';

  @override
  String get emailFieldInst => 'Institutional email';

  @override
  String get emailRegisterSubtitleEdu => 'Register via OTP on your Edumail';

  @override
  String get emailRegisterSubtitleInst =>
      'Register via OTP on your institutional email';

  @override
  String get noEduMailHintEdu =>
      'If you don\'t have an Edumail, contact the ICT cell';

  @override
  String get noEduMailHintInst =>
      'If you don\'t have an institutional email, contact the ICT cell';

  @override
  String get googleSignInSubtitle =>
      'Sign in with your university email account';

  @override
  String get googleInstitutionalPrompt =>
      'Sign in using your university institutional email.';

  @override
  String get googleEmailFormatLabel => 'Required email format:';

  @override
  String get googleIctHelp =>
      'If you don\'t have an institutional email, please contact the university ICT cell.';

  @override
  String get googleSignInButton => 'Continue with Google';

  @override
  String get googleSignInCancelled => 'Sign-in was cancelled.';

  @override
  String get googleSignInConfigError =>
      'Google sign-in configuration problem. Please contact us.';

  @override
  String get uploadIdTitle => 'Upload ID card';

  @override
  String get uploadIdSubtitle => 'Upload your university ID card';

  @override
  String get uploadIdSuccess => 'ID card uploaded successfully';

  @override
  String get selectPhoto => 'Select photo';

  @override
  String get completeUpload => 'Complete upload';

  @override
  String get authSendOtp => 'Send OTP';

  @override
  String get authVerifyOtp => 'Verify OTP';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResendCode => 'Send code again';

  @override
  String get authChangePhoneBack =>
      'Change phone number / back to registration';

  @override
  String get authChangeEmailBack => 'Change email / back to registration';

  @override
  String get authCodeNotReceived => 'Didn\'t receive the code?';

  @override
  String authResendCountdown(String remaining) {
    return '$remaining left to send a new code';
  }

  @override
  String get otpDigitHint => '6-digit OTP';

  @override
  String get otpDigitRequired => 'Enter the 6-digit OTP';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String otpSentToPhone(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String otpSentToEmail(String email) {
    return 'OTP sent to $email';
  }

  @override
  String get otpIncomplete => 'Enter the complete 6-digit code.';

  @override
  String get verificationFailedFallback =>
      'Verification failed. Please try again.';

  @override
  String get otpExpiredResent =>
      'The OTP has expired. A new OTP has been sent.';

  @override
  String get codeSendFailed => 'The code could not be sent. Please try again.';

  @override
  String get phoneVerifySubtitle =>
      'We sent a 6-digit verification code to your phone.';

  @override
  String get emailVerifySubtitle =>
      'We sent a 6-digit verification code to your email.';

  @override
  String get invalidImageType => 'Select a JPG, JPEG or PNG image only.';

  @override
  String get idCardDetectedTeacher => '✅ Teacher ID card detected';

  @override
  String get idCardDetected => '✅ ID card detected';

  @override
  String get photoUploaded => '✅ Photo uploaded';

  @override
  String get autoFilledInfo =>
      'Information was filled in automatically. Please review it.';

  @override
  String get photoValidationFailed =>
      'There was a problem validating the photo.';

  @override
  String get registerSubtitle => 'Upload your ID card or admission form';

  @override
  String get otpWillBeSentToPhone =>
      'An OTP will be sent to this number after registration';

  @override
  String get uploadDocStudent =>
      'ID card or admission form — provide either one!';

  @override
  String get uploadDocTeacher => 'Upload your teacher ID card';

  @override
  String get uploadGuidelinesStudent =>
      '• Have an ID card → upload a photo of the ID card\n• No ID card → upload a photo of the admission form / admission voucher\n• Both must be from Comilla University';

  @override
  String get uploadGuidelinesTeacher =>
      '• Upload a photo of your teacher ID\n• It must be a Comilla University teacher ID card\n• Department and designation will be filled in automatically';

  @override
  String get docPhotoLabelStudent =>
      'Photo of ID card / admission form (MANDATORY)';

  @override
  String get docPhotoLabelTeacher => 'Photo of teacher ID (MANDATORY)';

  @override
  String get photoFormatStudent => '(JPG/PNG — ID card or admission form)';

  @override
  String get photoFormatTeacher => '(JPG/PNG — teacher ID card)';

  @override
  String photoSizeMb(String size) {
    return 'Photo size: $size MB';
  }

  @override
  String photoSizeKb(String size) {
    return 'Photo size: $size KB';
  }

  @override
  String get photoValidatingIndicator => 'Validating photo...';

  @override
  String get registerDocTitle => 'Document required';

  @override
  String get registerDocRequiredMsg =>
      'To complete registration you must upload a photo of your university ID card or admission form.';

  @override
  String get photoValidatingDialog => 'Validating photo... please wait.';

  @override
  String get validIdCardPrompt => 'Provide a valid ID card.';

  @override
  String get academicStudentTitle => 'Complete your student information';

  @override
  String get academicStaffTitle => 'Complete teacher & officer information';

  @override
  String get academicSubtitle =>
      'Provide the details below to use your account.';

  @override
  String get academicOnceOnlyNote =>
      'This information cannot be changed once submitted. Enter it correctly.';

  @override
  String get academicHelperOnce => 'Cannot be changed once submitted';

  @override
  String get academicSave => 'Save';

  @override
  String get academicLogoutTitle => 'Log out?';

  @override
  String get academicLogoutBody =>
      'You can\'t use the account without this information. You can log in again later to complete it.';

  @override
  String get errorVerifyOtpNoToken =>
      'Verification succeeded but no token was received. Please try again.';

  @override
  String get otpSent => 'OTP sent';

  @override
  String get otpResent => 'OTP resent';

  @override
  String get errorUnknownResponse => 'Unknown response';
}
