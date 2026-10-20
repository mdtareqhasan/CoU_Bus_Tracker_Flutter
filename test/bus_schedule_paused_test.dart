import 'package:cou_bus_tracker/features/buses/bus_detail_screen.dart';
import 'package:cou_bus_tracker/shared/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schedulesToShow', () {
    final all = [trip(1), trip(2), trip(3)];

    test('shows every trip when the page was opened without a deep link', () {
      expect(schedulesToShow(all, null), all);
    });

    test('narrows to the deep-linked trip when it exists', () {
      expect(schedulesToShow(all, 2).map((s) => s.id), [2]);
    });

    test('falls back to every trip when the tapped trip was deleted', () {
      // A "no longer runs" push points at a schedule id that no longer
      // exists; rendering an empty section would leave the rider with no
      // context at all.
      expect(schedulesToShow(all, 99), all);
    });
  });

  group('Schedule.isActive', () {
    test('parses a paused trip', () {
      expect(Schedule.fromJson(const {'isActive': false}).isActive, isFalse);
    });

    test('a running trip stays flagged active', () {
      expect(Schedule.fromJson(const {'isActive': true}).isActive, isTrue);
    });

    test('missing flag (older cache payload) counts as running', () {
      expect(Schedule.fromJson(const {}).isActive, isTrue);
    });
  });
}

Schedule trip(int id) => Schedule(id: id);
