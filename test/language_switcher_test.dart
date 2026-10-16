import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/locale_provider.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/profile/language_settings_card.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

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
