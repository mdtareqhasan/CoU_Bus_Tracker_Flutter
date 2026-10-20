import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cou_bus_tracker/app/theme.dart';

/// Dark mode must get its own gradient: [AppTheme.primaryGradient] was a
/// single `const` shared by both themes, so its brightest stop glared at
/// 9.4:1 against `backgroundDark` and looked out of place on the dark page.
///
/// [AppTheme.primaryGradientFor] picks a darker sibling in dark mode. These
/// tests pin that behaviour from both ends:
///
///  * light mode must be byte-for-byte unchanged;
///  * every dark stop must be darker than its light counterpart;
///  * and the white text painted on these gradients (header titles, button
///    labels) must never get *less* legible than it was in light mode.
void main() {
  double luminance(Color color) {
    // Color.r/g/b are already doubles in the 0.0–1.0 range.
    double channel(double value) => value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  double contrastRatio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Resolves [AppTheme.primaryGradientFor] against [data] using a bare [Theme]
  /// ancestor. Deliberately not a MaterialApp: its `themeMode` defaults to
  /// `system`, which reads as light in tests and would silently defeat a dark
  /// theme passed as `theme:`.
  Future<LinearGradient> resolve(WidgetTester tester, ThemeData data) async {
    late LinearGradient resolved;
    await tester.pumpWidget(
      Theme(
        data: data,
        child: Builder(
          builder: (context) {
            resolved = AppTheme.primaryGradientFor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return resolved;
  }

  testWidgets('light mode keeps the original gradient exactly', (tester) async {
    final gradient = await resolve(tester, AppTheme.lightTheme);

    expect(identical(gradient, AppTheme.primaryGradient), isTrue);
    expect(gradient.colors, AppTheme.primaryGradient.colors);
  });

  testWidgets('dark mode switches to the darker gradient', (tester) async {
    final gradient = await resolve(tester, AppTheme.darkTheme);

    expect(identical(gradient, AppTheme.darkPrimaryGradient), isTrue);
    expect(gradient.colors, AppTheme.darkPrimaryGradient.colors);
    // The whole point: it must not be the lit-up light-mode one.
    expect(
      gradient.colors,
      isNot(AppTheme.primaryGradient.colors),
      reason: 'dark mode must not reuse the light gradient unchanged',
    );
  });

  test('every dark stop is darker than its light counterpart', () {
    final light = AppTheme.primaryGradient.colors;
    final dark = AppTheme.darkPrimaryGradient.colors;

    expect(dark.length, light.length);
    for (var i = 0; i < light.length; i++) {
      expect(
        luminance(dark[i]),
        lessThan(luminance(light[i])),
        reason: 'dark stop $i (${dark[i]}) must be darker than ${light[i]}',
      );
    }
  });

  test('white text painted on the dark gradient never gets harder to read', () {
    final light = AppTheme.primaryGradient.colors;
    final dark = AppTheme.darkPrimaryGradient.colors;
    const white = Colors.white;

    for (var i = 0; i < light.length; i++) {
      final before = contrastRatio(white, light[i]);
      final after = contrastRatio(white, dark[i]);
      expect(
        after,
        greaterThanOrEqualTo(before),
        reason:
            'stop $i: white text went from ${before.toStringAsFixed(2)}:1 to '
            '${after.toStringAsFixed(2)}:1 — dark mode must not regress it',
      );
    }

    // The two stops that actually carry text (headers are indigo→blue, button
    // labels sit mid-gradient) must clear WCAG AA outright.
    for (var i = 0; i < 2; i++) {
      expect(
        contrastRatio(white, dark[i]),
        greaterThan(4.5),
        reason: 'stop $i carries white text and must meet WCAG AA',
      );
    }
  });

  test('dark gradient glares against the dark page far less than before', () {
    const backgroundDark = Color(0xFF0F172A);
    final before = contrastRatio(
      AppTheme.primaryGradient.colors.last,
      backgroundDark,
    );
    final after = contrastRatio(
      AppTheme.darkPrimaryGradient.colors.last,
      backgroundDark,
    );

    // This is the complaint the dark variant exists to fix.
    expect(before, greaterThan(9));
    expect(after, lessThan(before));
    expect(
      after,
      lessThan(6),
      reason:
          'the brightest stop should stop glowing off the dark page '
          '(was ${before.toStringAsFixed(2)}:1)',
    );
  });
}
