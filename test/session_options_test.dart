import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cou_bus_tracker/features/auth/session_options.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// `sessionLabelFor` is what the Profile screen uses to render a stored
/// session. The profile payload carries the Bengali display form
/// (`StudentService.mapToResponse` returns `name_bn`), while older payloads
/// still hold the ASCII range — both must land on the label of the active
/// language, or an English UI keeps showing `২০২২-২০২৩`.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bn = lookupAppLocalizations(const Locale('bn'));

  group('sessionLabelFor', () {
    test('the Bengali form the profile sends follows the app language', () {
      expect(sessionLabelFor('২০২২-২০২৩', en), '2022-2023');
      expect(sessionLabelFor('২০২২-২০২৩', bn), '২০২২-২০২৩');
      expect(sessionLabelFor('২০২৫-২০২৬', en), '2025-2026');
    });

    test('the legacy ASCII form resolves the same way', () {
      expect(sessionLabelFor('2022-2023', en), '2022-2023');
      expect(sessionLabelFor('2022-2023', bn), '২০২২-২০২৩');
      // The completion screen's seeded state uses the ASCII form.
      expect(sessionLabelFor('2025-2026', bn), '২০২৫-২০২৬');
    });

    test('every bundled session has both language forms', () {
      for (final option in sessionOptions) {
        expect(option.valueBn, isNot(option.valueEn), reason: option.valueEn);
        // Both forms must resolve to the same row in either locale.
        expect(sessionLabelFor(option.valueBn, en),
            sessionLabelFor(option.valueEn, en));
        expect(sessionLabelFor(option.valueBn, bn),
            sessionLabelFor(option.valueEn, bn));
      }
    });

    test('an unknown session is passed through untouched', () {
      expect(sessionLabelFor('2030-2031', en), '2030-2031');
      expect(sessionLabelFor('২০৩০-২০৩১', bn), '২০৩০-২০৩১');
    });
  });
}
