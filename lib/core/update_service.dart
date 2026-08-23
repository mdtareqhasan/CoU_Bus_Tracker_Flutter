import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'constants.dart';
import '../features/providers.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String? downloadUrl;
  final String? message;
  final bool forceUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    this.downloadUrl,
    this.message,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latestVersion'] ?? json['version'] ?? '',
      latestBuild: json['latestBuild'] ?? json['buildNumber'] ?? 0,
      downloadUrl: json['downloadUrl'],
      message: json['message'],
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }
}

class UpdateService {
  final Ref _ref;

  UpdateService(this._ref);

  /// Checks for app updates from the backend.
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final storage = _ref.read(storageServiceProvider);
      final dio = Dio(); // plain Dio without auth interceptors

      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiEndpoints.appVersion}',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final updateInfo = UpdateInfo.fromJson(response.data);

        // Get current app version
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

        // Check if this version is newer
        if (updateInfo.latestBuild > currentBuild) {
          // Check if user skipped this version
          final skippedVersion = storage.getSkippedVersion();
          if (skippedVersion == updateInfo.latestVersion) {
            return null;
          }
          return updateInfo;
        }
      }
    } catch (_) {
      // Silently fail — update check is non-critical
    }
    return null;
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref);
});
