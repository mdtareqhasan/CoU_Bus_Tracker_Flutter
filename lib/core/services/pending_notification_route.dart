/// Holds an in-app route carried by a tapped push notification until the app
/// is ready to navigate to it.
///
/// A tap can arrive before the router, the navigator, or the auth session
/// exist — most sharply on a cold start, where FCM's `getInitialMessage()`
/// fires while [NotificationService.initialize] is still running, long before
/// `runApp`. So the tap handler *stores* the route here and the first
/// "you're in the app now" checkpoint (splash after session restore, or a
/// completed login) *consumes* it.
///
/// Consume-once: reading the value clears it, so a route replays exactly once
/// and never traps the user in a loop.
class PendingNotificationRoute {
  PendingNotificationRoute._();

  static String? _route;

  /// Stores [route] for later replay. Ignores null/empty.
  static void set(String? route) {
    if (route == null || route.isEmpty) return;
    _route = route;
  }

  /// Returns the stored route, clearing it. Returns null when nothing is
  /// pending (or the value was empty).
  static String? consume() {
    final route = _route;
    _route = null;
    return (route == null || route.isEmpty) ? null : route;
  }

  /// True while a route is waiting to be replayed.
  static bool get hasPending => _route != null && _route!.isNotEmpty;
}
