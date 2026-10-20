import 'package:cou_bus_tracker/core/services/pending_notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PendingNotificationRoute.consume); // drain any value a test left behind

  test('routes are stored and handed back exactly once', () {
    PendingNotificationRoute.set('/bus/3?scheduleId=9');

    expect(PendingNotificationRoute.hasPending, isTrue);
    expect(PendingNotificationRoute.consume(), '/bus/3?scheduleId=9');

    // Consume-once: a replayed route must never fire a second navigation,
    // or the user would be pushed back onto the page they just left.
    expect(PendingNotificationRoute.hasPending, isFalse);
    expect(PendingNotificationRoute.consume(), isNull);
  });

  test('null and empty routes are ignored', () {
    PendingNotificationRoute.set(null);
    expect(PendingNotificationRoute.hasPending, isFalse);

    PendingNotificationRoute.set('');
    expect(PendingNotificationRoute.hasPending, isFalse);
    expect(PendingNotificationRoute.consume(), isNull);
  });

  test('a newer tap replaces the older pending route', () {
    PendingNotificationRoute.set('/bus/1?scheduleId=1');
    PendingNotificationRoute.set('/notices');

    expect(PendingNotificationRoute.consume(), '/notices');
    expect(PendingNotificationRoute.hasPending, isFalse);
  });
}
