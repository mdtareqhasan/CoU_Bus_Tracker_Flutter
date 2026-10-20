import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/theme.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/features/schedules/schedule_screen.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// The role banner on the Schedules screen ("Student bus" / "Teacher bus")
/// paints its background `surfaceDark` in dark mode. Its text used to be
/// hard-coded to `AppTheme.textPrimary`, which is *the same colour* as
/// `surfaceDark` — so the label disappeared entirely. This test pins the
/// regression: the banner text must be legible against its own background in
/// both themes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSchedules(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ScheduleScreen(),
        ),
      ),
    );
    // Let the providers settle their initial (network-less) load.
    await tester.pumpAndSettle();
  }

  /// Relative luminance per WCAG 2.1, used to judge contrast.
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

  Color bannerBackgroundColor(WidgetTester tester, Brightness brightness) {
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('শিক্ষার্থী বাস'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      container.decoration,
      isA<BoxDecoration>(),
      reason: 'the role banner should be decorated with a background colour',
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    // Sanity: the background really is the theme-adapted one.
    expect(
      decoration.color,
      brightness == Brightness.dark
          ? AppTheme.surfaceDark
          : AppTheme.accentBlue.withValues(alpha: 0.3),
    );
    return decoration.color!;
  }

  testWidgets('schedules role banner text is legible in light mode', (
    tester,
  ) async {
    await pumpSchedules(tester, brightness: Brightness.light);

    final text = tester.widget<Text>(find.text('শিক্ষার্থী বাস'));
    final color = text.style!.color;
    expect(color, isNotNull);

    final background = bannerBackgroundColor(tester, Brightness.light);
    expect(
      contrastRatio(color!, background),
      greaterThan(4.5),
      reason: 'banner text $color on $background must meet WCAG AA contrast',
    );
  });

  testWidgets('schedules role banner text is legible in dark mode', (
    tester,
  ) async {
    await pumpSchedules(tester, brightness: Brightness.dark);

    final text = tester.widget<Text>(find.text('শিক্ষার্থী বাস'));
    final color = text.style!.color;
    expect(color, isNotNull);
    expect(
      color,
      isNot(AppTheme.textPrimary),
      reason:
          'textPrimary is the same slate as surfaceDark — the label '
          'would be invisible on the dark banner',
    );

    final background = bannerBackgroundColor(tester, Brightness.dark);
    expect(
      contrastRatio(color!, background),
      greaterThan(4.5),
      reason: 'banner text $color on $background must meet WCAG AA contrast',
    );
  });
}
