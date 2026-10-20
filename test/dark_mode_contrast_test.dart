import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/shell_screen.dart';
import 'package:cou_bus_tracker/app/theme.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/features/profile/language_settings_card.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// Contrast checks for dark-mode text that used to be invisible or nearly so:
///
///  * the Profile "Language" card title was hard-coded to [AppTheme.textPrimary]
///    on a card whose background is `colorScheme.surface` — and in dark mode
///    `surface` is `surfaceDark`, i.e. *the same colour*, so it vanished;
///  * the bottom navigation bar's unselected labels used `Colors.white24`,
///    white at 24% opacity, which is ~2.2:1 on the dark bar — barely readable.
///
/// Both must clear WCAG AA (4.5:1) in dark mode.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Composites [foreground] over [background] as the screen actually renders
  /// it. Needed for translucent colors like `Colors.white24`, whose `r`/`g`/`b`
  /// read as pure white even though only 24% of it is painted.
  Color over(Color foreground, Color background) =>
      Color.alphaBlend(foreground, background);

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

  Future<ProviderContainer> pumpDarkLanguageCard(WidgetTester tester) async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // themeMode defaults to `system`, which is light in tests — force
          // dark, or the whole check would silently inspect the light theme.
          themeMode: ThemeMode.dark,
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LanguageSettingsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(LanguageSettingsCard)),
    );
  }

  testWidgets('profile "Language" title is legible on its card in dark mode', (
    tester,
  ) async {
    await pumpDarkLanguageCard(tester);

    final title = tester.widget<Text>(find.text('ভাষা'));
    final color = title.style!.color;
    expect(color, isNotNull);
    expect(
      color,
      isNot(AppTheme.textPrimary),
      reason:
          'textPrimary is the same slate as the dark card surface — the '
          'title would be invisible',
    );

    // The card paints its own background, so read it from the nearest
    // decorated ancestor rather than assuming the scaffold colour.
    final card = tester.widget<Container>(
      find
          .ancestor(of: find.text('ভাষা'), matching: find.byType(Container))
          .first,
    );
    final background = (card.decoration! as BoxDecoration).color;
    expect(background, isNotNull);

    expect(
      contrastRatio(color!, background!),
      greaterThan(4.5),
      reason: 'Language title $color on $background must meet WCAG AA',
    );
  });

  testWidgets('bottom nav unselected labels are legible in dark mode', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/tab0',
      routes: [
        StatefulShellRoute(
          navigatorContainerBuilder: buildShellNavigatorContainer,
          builder: (context, state, navigationShell) =>
              ShellScreen(navigationShell: navigationShell),
          branches: [
            for (var i = 0; i < 5; i++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/tab$i',
                    pageBuilder: (context, state) =>
                        NoTransitionPage(child: Text('tab-$i')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // themeMode defaults to `system`, which is light in tests — force
          // dark, or the whole check would silently inspect the light theme.
          themeMode: ThemeMode.dark,
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    final background = bar.backgroundColor;
    final unselected = bar.unselectedItemColor;
    expect(background, isNotNull);
    expect(unselected, isNotNull);

    // The bar paints unselectedItemColor at its own alpha over
    // `backgroundColor`, so compare the composited colour, not the raw
    // (translucent) one — white24 reads as pure white without compositing.
    final rendered = over(unselected!, background!);
    expect(
      contrastRatio(rendered, background),
      greaterThan(4.5),
      reason:
          'unselected nav labels render as $rendered on $background and must '
          'meet WCAG AA — white24 is only ~2.2:1 on the dark bar',
    );
  });
}
