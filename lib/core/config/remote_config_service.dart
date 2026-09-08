import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage_service.dart';

class PublicConfig {
  final String latestAppVersion;
  final String minimumAppVersion;
  final bool forceUpdate;
  final String updateMessage;
  final String playStoreUrl;
  final bool maintenanceMode;
  final String maintenanceMessage;

  const PublicConfig({
    required this.latestAppVersion,
    required this.minimumAppVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.playStoreUrl,
    required this.maintenanceMode,
    required this.maintenanceMessage,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) {
    return PublicConfig(
      latestAppVersion: json['latestAppVersion'] as String? ?? '1.0.0',
      minimumAppVersion: json['minimumAppVersion'] as String? ?? '1.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      updateMessage: json['updateMessage'] as String? ?? '',
      playStoreUrl: json['playStoreUrl'] as String? ?? kDefaultPlayStoreUrl,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'latestAppVersion': latestAppVersion,
    'minimumAppVersion': minimumAppVersion,
    'forceUpdate': forceUpdate,
    'updateMessage': updateMessage,
    'playStoreUrl': playStoreUrl,
    'maintenanceMode': maintenanceMode,
    'maintenanceMessage': maintenanceMessage,
  };

  static const empty = PublicConfig(
    latestAppVersion: '1.0.0',
    minimumAppVersion: '1.0.0',
    forceUpdate: false,
    updateMessage: '',
    playStoreUrl: kDefaultPlayStoreUrl,
    maintenanceMode: false,
    maintenanceMessage: '',
  );
}

class RemoteConfigService {
  final Dio _dio;
  final StorageService _storage;
  PublicConfig? _config;

  RemoteConfigService(this._dio, this._storage);

  PublicConfig? get config => _config;

  /// Cold-launch: fetch config from backend `/api/config`.
  /// Cache-first — loads from cache instantly, refreshes in background.
  Future<PublicConfig> initConfig() async {
    // Try cache first
    final cached = _loadFromCache();
    if (cached != null) {
      _config = cached;
      _backgroundRefresh();
      return cached;
    }

    // No cache — fetch synchronously
    final fresh = await _fetchConfig();
    if (fresh != null) {
      _config = fresh;
      await _saveToCache(fresh);
      return fresh;
    }

    return PublicConfig.empty;
  }

  Future<void> _backgroundRefresh() async {
    try {
      final fresh = await _fetchConfig();
      if (fresh == null || _config == null) return;
      if (fresh.toJson().toString() != _config!.toJson().toString()) {
        _config = fresh;
        await _saveToCache(fresh);
      }
    } catch (_) {}
  }

  Future<PublicConfig?> _fetchConfig() async {
    try {
      final response = await _dio.get(
        '$kBaseUrl/api/config',
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PublicConfig.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  PublicConfig? _loadFromCache() {
    final raw = _storage.getCachedConfig();
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PublicConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(PublicConfig config) async {
    await _storage.saveCachedConfig(jsonEncode(config.toJson()));
  }

  Future<PublicConfig> forceRefresh() async {
    final fresh = await _fetchConfig();
    if (fresh != null) {
      _config = fresh;
      await _saveToCache(fresh);
    }
    return _config ?? PublicConfig.empty;
  }
}
