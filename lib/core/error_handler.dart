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
      case 500:
        return 'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
        }
        return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
    }
  }

  static String get timeoutMessage =>
      'সার্ভার চালু হচ্ছে। অনুগ্রহ করে ১-২ মিনিট অপেক্ষা করুন এবং আবার চেষ্টা করুন।';
  static String get networkMessage => 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
  static String get sessionExpired => 'সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';
  static String get defaultError => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
  static String get coldStartMessage =>
      'সার্ভার চালু হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...';
}
