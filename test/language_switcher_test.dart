import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/locale_provider.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/auth/role_screen.dart';
import 'package:cou_bus_tracker/features/profile/language_settings_card.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:cou_bus_tracker/shared/widgets/app_bar_language_switcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
    // Simulate a Bengali device with no saved choice → app starts in bn.
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('bn');
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocaleTestValue();
  });

  testWidgets('switcher lists both languages and applies a change instantly', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const _LocaleHarness(child: LanguageSettingsCard()),
      ),
    );
    await tester.pumpAndSettle();

    // Default state: Bengali device, nothing saved yet.
    expect(find.text('ভাষা'), findsOneWidget); // card header
    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Tap English → header re-renders in English without a restart, and the
    // choice is persisted for the next launch.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('ভাষা'), findsNothing);
    expect(storage.getLanguageCode(), 'en');
    expect(L10n.current.profileLanguage, 'Language');

    // Switch back to বাংলা.
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(find.text('ভাষা'), findsOneWidget);
    expect(storage.getLanguageCode(), 'bn');
    expect(L10n.current.profileLanguage, 'ভাষা');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'pre-login role screen defaults to Bangla on an English device, and its '
    'switcher sits under the header and toggles/persists',
    (tester) async {
      // Simulate an *English* device with no saved choice — the app must still
      // come up in Bangla (this is a Comilla University app), proving the
      // system locale does not decide the language.
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale('en');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const _RoleHarness(),
        ),
      );
      // RoleScreen uses flutter_animate entrance animations; settle them.
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Bangla by default regardless of the English system locale.
      expect(find.text('আপনার ভূমিকা'), findsOneWidget);
      expect(find.text('Your role'), findsNothing);

      // The compact switcher is present, offering both languages.
      expect(find.text('বাং'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);

      // Placement: it must sit BELOW the header title (this screen has no app
      // bar — the title header plays that role) and toward the top-LEFT of the
      // screen, not on the right where it used to float.
      final titleTop =
          tester.getTopLeft(find.text('আপনার ভূমিকা')).dy;
      final switcherTopLeft = tester.getTopLeft(find.byType(AppBarLanguageSwitcher));
      final screenWidth = tester.getSize(find.byType(_RoleHarness)).width;
      expect(switcherTopLeft.dy, greaterThan(titleTop),
          reason: 'switcher must be under the header, not beside/above it');
      expect(switcherTopLeft.dx, lessThan(screenWidth / 2),
          reason: 'switcher must be on the left side of the screen');

      // Tap EN → the whole screen re-renders in English without a restart.
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.text('Your role'), findsOneWidget);
      expect(find.text('আপনার ভূমিকা'), findsNothing);
      expect(storage.getLanguageCode(), 'en');
      expect(L10n.current.roleSelectTitle, 'Your role');

      // Tap বাং → back to Bangla, persisted.
      await tester.tap(find.text('বাং'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.text('আপনার ভূমিকা'), findsOneWidget);
      expect(storage.getLanguageCode(), 'bn');
      expect(L10n.current.roleSelectTitle, 'আপনার ভূমিকা');

      await tester.pumpWidget(const SizedBox());
    },
  );
}

/// Minimal replica of the `MaterialApp` wiring from `lib/app/app.dart`.
class _LocaleHarness extends ConsumerWidget {
  const _LocaleHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }
}

/// Same locale wiring, but renders [RoleScreen] as the [MaterialApp] home.
///
/// Unlike `LanguageSettingsCard`, the role screen owns a `Scaffold` with an
/// `Expanded` column, so it must be the home itself — wrapping it in a
/// `SingleChildScrollView` would give it unbounded height and blow up layout.
class _RoleHarness extends ConsumerWidget {
  const _RoleHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RoleScreen(),
    );
  }
}
