/// Bangladeshi phone number utilities.
///
/// Accepted input formats: `01XXXXXXXXX`, `8801XXXXXXXXX`, `+8801XXXXXXXXX`.
/// All are normalized to `8801XXXXXXXXX` before being sent to the backend.
library;

final RegExp _bdPhoneRaw = RegExp(r'^1[3-9]\d{8}$');

/// Accepts formats like `01XXXXXXXXX`, `8801XXXXXXXXX` and `+8801XXXXXXXXX`.
bool isValidBangladeshiPhone(String input) {
  final cleaned = _clean(input);
  if (cleaned.startsWith('+880')) {
    return _bdPhoneRaw.hasMatch(cleaned.substring(4));
  }
  if (cleaned.startsWith('880')) {
    return _bdPhoneRaw.hasMatch(cleaned.substring(3));
  }
  if (cleaned.startsWith('0')) {
    return _bdPhoneRaw.hasMatch(cleaned.substring(1));
  }
  return _bdPhoneRaw.hasMatch(cleaned);
}

/// Converts any accepted format to `8801XXXXXXXXX` (13 digits).
String normalizeBangladeshiPhone(String input) {
  var cleaned = _clean(input);
  if (cleaned.startsWith('+880')) {
    cleaned = cleaned.substring(4);
  } else if (cleaned.startsWith('880')) {
    cleaned = cleaned.substring(3);
  } else if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }
  return '880$cleaned';
}

/// Masks a phone for display, e.g. `8801712345678` -> `8801****5678`.
String maskBangladeshiPhone(String phone) {
  final normalized = normalizeBangladeshiPhone(phone);
  if (normalized.length < 8) return normalized;
  final head = normalized.substring(0, 4);
  final tail = normalized.substring(normalized.length - 4);
  return '$head****$tail';
}

String _clean(String input) {
  return input.replaceAll(RegExp(r'[\s\-()+.]'), '');
}
