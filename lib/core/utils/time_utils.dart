import '../../l10n/l10n.dart';

class TimeUtils {
  /// Formats an `HH:mm` time for the active locale:
  /// Bengali → `সকাল ৮:৩০`, English → `8:30 AM`.
  ///
  /// Context-free (used by models), so it reads the locale from [L10n] —
  /// see docs/localization.md.
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) {
      return L10n.current.timeNotScheduled;
    }

    try {
      // Handle HH:mm format
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final displayMinute = minute.toString().padLeft(2, '0');

      if (L10n.locale.languageCode == 'bn') {
        final period = switch (hour) {
          >= 5 && < 12 => L10n.current.timeMorning,
          >= 12 && < 15 => L10n.current.timeAfternoon,
          >= 15 && < 18 => L10n.current.timeEvening,
          _ => L10n.current.timeNight,
        };

        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

        return '$period '
            '${_toBengaliDigits(displayHour.toString())}:'
            '${_toBengaliDigits(displayMinute)}';
      }

      // English: 12-hour clock with AM/PM.
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final period = hour < 12 ? 'AM' : 'PM';
      return '$displayHour:$displayMinute $period';
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
