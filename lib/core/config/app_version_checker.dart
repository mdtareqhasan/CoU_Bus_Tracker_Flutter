import 'remote_config_service.dart';

/// Semantic version comparison (X.Y.Z).
/// Returns -1 if current < target, 0 if equal, 1 if current > target.
int compareVersions(String current, String target) {
  final currentParts = current
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
  final targetParts = target
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();

  while (currentParts.length < 3) currentParts.add(0);
  while (targetParts.length < 3) targetParts.add(0);

  for (var i = 0; i < 3; i++) {
    if (currentParts[i] < targetParts[i]) return -1;
    if (currentParts[i] > targetParts[i]) return 1;
  }
  return 0;
}

enum AppGateStatus {
  /// App can proceed normally.
  allowed,

  /// Below minimumAppVersion — must update, no skip.
  forceUpdate,

  /// Below latestAppVersion but above minimum — optional update (only when
  /// config.forceUpdate == true).
  optionalUpdate,

  /// Maintenance mode — full-screen overlay, no exit.
  maintenance,
}

/// Decides what the app should do based on config + current version.
AppGateStatus evaluateAppStatus({
  required String currentAppVersion,
  required PublicConfig config,
}) {
  // 1. Maintenance mode takes absolute priority
  if (config.maintenanceMode) {
    return AppGateStatus.maintenance;
  }

  // 2. Below minimum version → force update
  final minCmp = compareVersions(currentAppVersion, config.minimumAppVersion);
  if (minCmp < 0) {
    return AppGateStatus.forceUpdate;
  }

  // 3. Below latest version with forceUpdate enabled → force update
  if (config.forceUpdate) {
    final latestCmp = compareVersions(
      currentAppVersion,
      config.latestAppVersion,
    );
    if (latestCmp < 0) {
      return AppGateStatus.forceUpdate;
    }
  }

  return AppGateStatus.allowed;
}
