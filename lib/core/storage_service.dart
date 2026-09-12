import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class StorageService {
  static StorageService? _instance;
  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      final instance = StorageService._();
      instance._secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      instance._prefs = await SharedPreferences.getInstance();
      _instance = instance;
    }
    return _instance!;
  }

  Future<void> saveSession({
    required String token,
    String? tokenType,
    required String role,
    required String name,
    required String email,
    String? phone,
    int? userId,
    bool isVerified = false,
    bool isEduMail = false,
  }) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
    if (tokenType != null && tokenType.isNotEmpty) {
      await _secureStorage.write(key: StorageKeys.tokenType, value: tokenType);
    }
    await _prefs.setString(StorageKeys.userRole, role);
    await _prefs.setString(StorageKeys.displayName, name);
    await _prefs.setString(StorageKeys.userEmail, email);
    if (phone != null && phone.isNotEmpty) {
      await _prefs.setString(StorageKeys.userPhone, phone);
    }
    if (userId != null) await _prefs.setInt(StorageKeys.userId, userId);
    await _prefs.setBool(StorageKeys.isVerified, isVerified);
    await _prefs.setBool(StorageKeys.isEduMail, isEduMail);
    await _prefs.setBool('_has_token', true);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: StorageKeys.accessToken);
  }

  Future<String?> getTokenType() async {
    return await _secureStorage.read(key: StorageKeys.tokenType);
  }

  String? getRole() => _prefs.getString(StorageKeys.userRole);
  String? getDisplayName() => _prefs.getString(StorageKeys.displayName);
  String? getUserEmail() => _prefs.getString(StorageKeys.userEmail);
  String? getUserPhone() => _prefs.getString(StorageKeys.userPhone);
  int? getUserId() => _prefs.getInt(StorageKeys.userId);
  bool isVerified() => _prefs.getBool(StorageKeys.isVerified) ?? false;
  bool isEduMail() => _prefs.getBool(StorageKeys.isEduMail) ?? false;

  /// Pending OTP verification session. Stored securely so it survives app
  /// restart. The OTP value itself is NEVER persisted.
  Future<void> setPendingVerification(String? phone, String? role) async {
    if (phone == null) {
      await _secureStorage.delete(key: StorageKeys.pendingPhone);
      await _secureStorage.delete(key: StorageKeys.verificationRole);
    } else {
      await _secureStorage.write(key: StorageKeys.pendingPhone, value: phone);
      await _secureStorage.write(
        key: StorageKeys.verificationRole,
        value: role ?? 'STUDENT',
      );
    }
  }

  Future<String?> getPendingPhone() async {
    return await _secureStorage.read(key: StorageKeys.pendingPhone);
  }

  Future<String?> getPendingRole() async {
    return await _secureStorage.read(key: StorageKeys.verificationRole);
  }

  bool isLoggedIn() {
    // Explicitly check for both token and the boolean flag
    final hasToken = _prefs.getBool('_has_token') ?? false;
    return hasToken;
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    final hasFlag = _prefs.getBool('_has_token') ?? false;
    return (token != null && token.isNotEmpty) || hasFlag;
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.tokenType);
    await _secureStorage.delete(key: StorageKeys.pendingPhone);
    await _secureStorage.delete(key: StorageKeys.verificationRole);
    await _prefs.remove(StorageKeys.userRole);
    await _prefs.remove(StorageKeys.displayName);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userPhone);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.isVerified);
    await _prefs.remove(StorageKeys.isEduMail);
    await _prefs.setBool('_has_token', false);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(StorageKeys.themeMode, mode);
  }

  String getThemeMode() => _prefs.getString(StorageKeys.themeMode) ?? 'system';

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(StorageKeys.languageCode, code);
  }

  String getLanguageCode() =>
      _prefs.getString(StorageKeys.languageCode) ?? 'bn';

  // --- Caching Support ---

  /// Save raw JSON string to local storage
  Future<void> saveCache(String key, String json) async {
    await _prefs.setString(key, json);
    await _prefs.setInt(
      '${key}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get raw JSON string from local storage
  String? getCache(String key) {
    return _prefs.getString(key);
  }

  /// Check if cache is still valid (e.g., less than 24 hours old)
  bool isCacheValid(String key, {Duration maxAge = const Duration(hours: 24)}) {
    final timestamp = _prefs.getInt('${key}_timestamp');
    if (timestamp == null) return false;

    final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(cacheDate);
    return diff < maxAge;
  }

  Future<void> clearAllCache() async {
    final keys = [
      StorageKeys.cachedBuses,
      StorageKeys.cachedSchedules,
      StorageKeys.cachedNotices,
    ];
    for (var key in keys) {
      await _prefs.remove(key);
      await _prefs.remove('${key}_timestamp');
    }
  }

  String? getSkippedVersion() {
    return _prefs.getString(StorageKeys.skippedVersion);
  }

  Future<void> setSkippedVersion(String version) async {
    await _prefs.setString(StorageKeys.skippedVersion, version);
  }

  Future<void> clearSkippedVersion() async {
    await _prefs.remove(StorageKeys.skippedVersion);
  }

  // --- Super Admin Config Cache ---

  static const _configKey = 'super_admin_config';

  String? getCachedConfig() => _prefs.getString(_configKey);

  Future<void> saveCachedConfig(String json) async {
    await _prefs.setString(_configKey, json);
  }

  Future<void> clearCachedConfig() async {
    await _prefs.remove(_configKey);
  }

  // --- Registration draft (survives OTP round-trip & app background) ---
  Future<void> saveRegistrationDraft(Map<String, String> draft) async {
    // store as simple string map; image File path is saved separately
    for (final e in draft.entries) {
      await _prefs.setString('${StorageKeys.registrationDraft}_${e.key}', e.value);
    }
  }

  Map<String, String> getRegistrationDraft() {
    const keys = [
      'name', 'phone', 'studentId', 'teacherId',
      'department', 'batch', 'designation', 'password', 'confirmPassword', 'role',
    ];
    final out = <String, String>{};
    for (final k in keys) {
      final v = _prefs.getString('${StorageKeys.registrationDraft}_$k');
      if (v != null && v.isNotEmpty) out[k] = v;
    }
    return out;
  }

  Future<void> clearRegistrationDraft() async {
    const keys = [
      'name', 'phone', 'studentId', 'teacherId',
      'department', 'batch', 'designation', 'password', 'confirmPassword', 'role', 'imagePath',
    ];
    for (final k in keys) {
      await _prefs.remove('${StorageKeys.registrationDraft}_$k');
    }
  }

  Future<void> saveRegistrationImagePath(String path) async {
    await _prefs.setString('${StorageKeys.registrationDraft}_imagePath', path);
  }

  String? getRegistrationImagePath() =>
      _prefs.getString('${StorageKeys.registrationDraft}_imagePath');
}
