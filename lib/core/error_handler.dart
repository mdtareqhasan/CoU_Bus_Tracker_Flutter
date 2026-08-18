class ErrorHandler {
  static String getMessage(int? statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return 'তথ্য সঠিক নয়। আবার চেষ্টা করুন।';
      case 401:
        return 'সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';
      case 403:
        return 'অনুমতি নেই।';
      case 404:
        return 'তথ্যটি পাওয়া যায়নি।';
      case 409:
        return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।';
      case 502:
      case 503:
      case 504:
        return serverBusyMessage;
      case 500:
        return 'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
        }
        return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
    }
  }

  static String get serverBusyMessage =>
      'সার্ভার চালু হচ্ছে বা সাময়িকভাবে ব্যস্ত। ১–২ মিনিট পরে আবার চেষ্টা করুন।';
  static String get timeoutMessage => serverBusyMessage;
  static String get networkMessage => 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
  static String get sessionExpired => 'সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';
  static String get defaultError => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
  static String get coldStartMessage =>
      'সার্ভার চালু হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...';

  static String get otpInvalid => 'ভুল ওটিপি। আবার চেষ্টা করুন।';
  static String get otpExpired =>
      'ওটিপির মেয়াদ শেষ হয়ে গেছে। আবার কোড পাঠান।';
  static String get otpExceeded =>
      'অনেকবার ভুল চেষ্টা। ওটিপি বাতিল হয়েছে। আবার কোড পাঠান।';
  static String get resendCooldown => 'আবার কোড পাঠাতে একটু অপেক্ষা করুন।';
  static String get verifyEmailFirst =>
      'অনুগ্রহ করে লগইন করার আগে আপনার ইমেইল যাচাই করুন।';

  /// Converts backend English messages into friendly Bengali equivalents.
  /// Falls back to the raw message when no mapping exists.
  static String friendly(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid otp') ||
        m.contains('invalid verification code') ||
        m.contains('incorrect otp')) {
      return otpInvalid;
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
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।';
    }
    if (m.contains('invalid credentials') ||
        m.contains('wrong password') ||
        m.contains('invalid email or password')) {
      return 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';
    }
    if (m.contains('register first') || m.contains('not registered')) {
      return 'আপনার অ্যাকাউন্ট পাওয়া যায়নি। আগে নিবন্ধন করুন।';
    }
    return message;
  }
}
