class TimeUtils {
  static String formatTimeBengali(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'নির্ধারিত নয়';
    
    try {
      // Handle HH:mm format
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = '';
      if (hour >= 5 && hour < 12) {
        period = 'সকাল';
      } else if (hour >= 12 && hour < 15) {
        period = 'দুপুর';
      } else if (hour >= 15 && hour < 18) {
        period = 'বিকাল';
      } else {
        period = 'রাত';
      }
      
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String displayMinute = minute.toString().padLeft(2, '0');
      
      // Convert digits to Bengali
      String bengaliHour = _toBengaliDigits(displayHour.toString());
      String bengaliMinute = _toBengaliDigits(displayMinute);
      
      return '$period $bengaliHour:$bengaliMinute';
    } catch (e) {
      return timeStr;
    }
  }

  static String _toBengaliDigits(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    
    String output = input;
    for (int i = 0; i < englishDigits.length; i++) {
      output = output.replaceAll(englishDigits[i], bengaliDigits[i]);
    }
    return output;
  }

  static String toEnglishDigits(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    
    String output = input;
    for (int i = 0; i < bengaliDigits.length; i++) {
      output = output.replaceAll(bengaliDigits[i], englishDigits[i]);
    }
    return output;
  }

  static bool isScheduleForToday(String? daysStr) {
    if (daysStr == null || daysStr.isEmpty) return true;
    
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Mon, 7 = Sun
    
    final normalizedDays = daysStr.toUpperCase().trim();
    
    // Working Days ranges
    if (normalizedDays == 'SAT-THU' || normalizedDays == 'SUN-THU') {
      if (normalizedDays == 'SAT-THU') {
        return weekday != DateTime.friday;
      } else {
        return weekday != DateTime.friday && weekday != DateTime.saturday;
      }
    }
    
    // Check for explicit day codes
    final dayCodes = {
      DateTime.monday: 'MON',
      DateTime.tuesday: 'TUE',
      DateTime.wednesday: 'WED',
      DateTime.thursday: 'THU',
      DateTime.friday: 'FRI',
      DateTime.saturday: 'SAT',
      DateTime.sunday: 'SUN',
    };
    
    final todayCode = dayCodes[weekday];
    return normalizedDays.contains(todayCode!);
  }
}
