import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/locale_provider.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/about/about_screen.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// Every key the hamburger menu (home header) and the About Us screen read.
final _aboutKeys = <String, String Function(AppLocalizations)>{
  'aboutUsTitle': (l) => l.aboutUsTitle,
  'aboutScrollTooltip': (l) => l.aboutScrollTooltip,
  'aboutAppDescription': (l) => l.aboutAppDescription,
  'aboutDeptName': (l) => l.aboutDeptName,
  'aboutDeptNote': (l) => l.aboutDeptNote,
  'aboutRoleLeadDeveloper': (l) => l.aboutRoleLeadDeveloper,
  'aboutRoleMaintainer': (l) => l.aboutRoleMaintainer,
  'aboutRoleConsultant': (l) => l.aboutRoleConsultant,
  'aboutRoleAdvisor': (l) => l.aboutRoleAdvisor,
  'aboutInfoLeadDeveloper': (l) => l.aboutInfoLeadDeveloper,
  'aboutInfoMaintainer': (l) => l.aboutInfoMaintainer,
  'aboutInfoConsultant': (l) => l.aboutInfoConsultant,
  'aboutInfoAdvisor': (l) => l.aboutInfoAdvisor,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('about copy in the ARBs', () {
    test(
      'every key exists in bn (template) and en, and the locales differ',
      () {
        final bn = lookupAppLocalizations(const Locale('bn'));
        final en = lookupAppLocalizations(const Locale('en'));

        for (final entry in _aboutKeys.entries) {
          final bnText = entry.value(bn);
          final enText = entry.value(en);

          expect(
            bnText,
            isNotEmpty,
            reason: 'missing bn value for ${entry.key}',
          );
          expect(
            enText,
            isNotEmpty,
            reason: 'missing en value for ${entry.key}',
          );
          expect(
            bnText,
            isNot(enText),
            reason:
                '${entry.key} is untranslated — switching language would '
                'not change the About page / menu',
          );
        }
      },
    );

    test('the menu entry and the screen title share one localized string', () {
      expect(
        lookupAppLocalizations(const Locale('bn')).aboutUsTitle,
        'আমাদের সম্পর্কে',
      );
      expect(
        lookupAppLocalizations(const Locale('en')).aboutUsTitle,
        'About Us',
      );
    });
  });

  group('AboutScreen', () {
    late StorageService storage;

    setUp(() async {
      StorageService.resetInstanceForTesting();
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale('bn');
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearLocaleTestValue();
    });

    testWidgets('renders its copy in the active locale, and re-renders when '
        'the language changes at runtime', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const _AboutHarness(),
        ),
      );
      await tester.pumpAndSettle();

      // Bengali first (this is a Comilla University app).
      expect(find.text('আমাদের সম্পর্কে'), findsOneWidget); // app bar title
      expect(find.text('লিড ডেভেলপার'), findsOneWidget);
      expect(
        find.text('কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং'),
        findsOneWidget,
      );
      expect(find.text('About Us'), findsNothing);
      expect(find.text('Lead Developer'), findsNothing);

      // Switch language the way the Profile switcher does — no restart.
      final context = tester.element(find.byType(AboutScreen));
      final container = ProviderScope.containerOf(context);
      await container.read(localeProvider.notifier).setLanguageCode('en');
      await tester.pumpAndSettle();

      expect(find.text('About Us'), findsOneWidget);
      expect(find.text('Lead Developer'), findsOneWidget);
      expect(find.text('Computer Science and Engineering'), findsOneWidget);
      expect(
        find.text('Current Maintainer & Core Contributor'),
        findsOneWidget,
      );
      expect(find.text('আমাদের সম্পর্কে'), findsNothing);
      expect(find.text('লিড ডেভেলপার'), findsNothing);
      expect(storage.getLanguageCode(), 'en');

      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// Minimal replica of the `MaterialApp` wiring from `lib/app/app.dart`.
class _AboutHarness extends ConsumerWidget {
  const _AboutHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AboutScreen(),
    );
  }
}
