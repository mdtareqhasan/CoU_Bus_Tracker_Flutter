import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/locale_provider.dart';
import 'package:cou_bus_tracker/core/error_handler.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('generated localizations', () {
    test('bn (template) and en both provide every key', () {
      final bn = lookupAppLocalizations(const Locale('bn'));
      final en = lookupAppLocalizations(const Locale('en'));

      expect(bn.sessionExpiredMessage, contains('সেশন'));
      expect(
        en.sessionExpiredMessage,
        'Your session has expired. Please log in again.',
      );
      // The two locales must actually differ, or the switcher is a no-op.
      expect(bn.sessionExpiredMessage, isNot(en.sessionExpiredMessage));
      // ICU quoting: a literal apostrophe is written as '' in the ARB.
      expect(en.homeStatTodayTrips, "Today's trips");
      expect(bn.homeStatTodayTrips, 'আজকের ট্রিপ');
    });

    test('unsupported locale falls back to bn instead of throwing', () {
      final l10n = L10n.activate(const Locale('fr'));
      expect(l10n.localeName, 'bn');
      expect(L10n.locale, const Locale('bn'));
      expect(() => L10n.current.sessionExpiredMessage, returnsNormally);
    });
  });

  group('context.l10n in widgets', () {
    testWidgets('renders the string matching MaterialApp.locale', (
      tester,
    ) async {
      Widget tree(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(
            'msg:${context.l10n.sessionExpiredMessage}',
            textDirection: TextDirection.ltr,
          ),
        ),
      );

      await tester.pumpWidget(tree(const Locale('bn')));
      expect(
        find.text('msg:আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার লগইন করুন।'),
        findsOneWidget,
      );

      await tester.pumpWidget(tree(const Locale('en')));
      expect(
        find.text('msg:Your session has expired. Please log in again.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ErrorHandler localization', () {
    tearDown(() => L10n.activate(const Locale('bn')));

    test('every error message resolves in bn and en', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        final messages = <String>[
          l10n.errorBadRequest,
          l10n.errorSessionExpired,
          l10n.errorForbidden,
          l10n.errorNotFound,
          l10n.errorEmailTaken,
          l10n.errorServerIssue,
          l10n.errorNetwork,
          l10n.errorServerBusy,
          l10n.errorDefault,
          l10n.errorColdStart,
          l10n.errorInvalidLogin,
          l10n.errorInvalidOtp,
          l10n.errorOtpExpired,
          l10n.errorOtpExceeded,
          l10n.errorResendCooldown,
          l10n.errorVerifyPhoneFirst,
          l10n.errorVerifyEmailFirst,
          l10n.errorPhoneNotFound,
          l10n.errorAccountDeactivated,
          l10n.errorPhoneAlreadyUsed,
          l10n.errorAccountNotFound,
        ];
        expect(messages, isNot(contains(anyOf(isEmpty, isNull))));
        expect(messages.toSet(), hasLength(messages.length),
            reason: 'duplicate error copy in $locale');
      }
    });

    test('identity checks match a message built in another locale', () {
      final bnText = lookupAppLocalizations(const Locale('bn')).errorOtpExpired;
      final enText = lookupAppLocalizations(const Locale('en')).errorOtpExpired;
      expect(bnText, isNot(enText));

      // A bn message stays recognized once the app switches to en — this is
      // exactly what `message == ErrorHandler.otpExpired` would get wrong.
      expect(ErrorHandler.isOtpExpired(bnText), isTrue);
      expect(ErrorHandler.isOtpExpired(enText), isTrue);

      final invalidOtp =
          lookupAppLocalizations(const Locale('en')).errorInvalidOtp;
      expect(ErrorHandler.isOtpExpired(invalidOtp), isFalse);
      expect(ErrorHandler.isVerifyPhoneFirst(
        lookupAppLocalizations(const Locale('bn')).errorVerifyPhoneFirst,
      ), isTrue);
    });

    test('friendly() maps backend English into the active locale', () {
      L10n.activate(const Locale('bn'));
      expect(ErrorHandler.friendly('OTP has expired'), contains('মেয়াদ'));
      expect(
        ErrorHandler.friendly('Invalid credentials'),
        equals(ErrorHandler.invalidLogin),
      );

      L10n.activate(const Locale('en'));
      expect(
        ErrorHandler.friendly('OTP has expired'),
        lookupAppLocalizations(const Locale('en')).errorOtpExpired,
      );

      // Unmapped backend text is passed through untouched.
      expect(ErrorHandler.friendly('weird backend text'), 'weird backend text');
    });

    test('HTTP status codes map to localized copy', () {
      L10n.activate(const Locale('en'));
      expect(ErrorHandler.getMessage(503, null), contains('1–2 minutes'));
      expect(ErrorHandler.getMessage(409, null), contains('email'));
      expect(ErrorHandler.getMessage(401, null), contains('sign in'));
      expect(ErrorHandler.getMessage(null, null), contains('internet'));

      L10n.activate(const Locale('bn'));
      expect(ErrorHandler.getMessage(503, null), contains('মিনিট'));
    });
  });

  group('localeProvider', () {
    late StorageService storage;

    setUp(() async {
      // Fresh singleton + empty store for every test, on a "Bengali device"
      // so the default-language assertions are deterministic.
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

    test('first launch follows the system locale when nothing is saved', () async {
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;

      dispatcher.localeTestValue = const Locale('en');
      var container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      expect(container.read(localeProvider), const Locale('en'));
      container.dispose();

      dispatcher.localeTestValue = const Locale('bn');
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      expect(container.read(localeProvider), const Locale('bn'));
      container.dispose();
    });

    test('a saved choice wins over the system locale', () async {
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale('en');
      await storage.setLanguageCode('bn');

      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      expect(container.read(localeProvider), const Locale('bn'));
    });

    test('defaults to bn on a Bengali device, persists a change, and drives L10n.current', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      expect(storage.getLanguageCode(), 'bn');
      expect(container.read(localeProvider), const Locale('bn'));
      expect(L10n.current.sessionExpiredMessage, contains('সেশন'));

      await container.read(localeProvider.notifier).setLanguageCode('en');
      expect(container.read(localeProvider), const Locale('en'));
      expect(storage.getLanguageCode(), 'en');
      expect(
        L10n.current.sessionExpiredMessage,
        'Your session has expired. Please log in again.',
      );

      await container.read(localeProvider.notifier).setLanguageCode('bn');
      expect(container.read(localeProvider), const Locale('bn'));
      expect(L10n.current.sessionExpiredMessage, contains('সেশন'));
    });

    testWidgets('changing language re-renders the app at runtime', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const _LanguageSwitcherHarness(),
        ),
      );
      expect(find.textContaining('সেশন'), findsOneWidget);

      await tester.tap(find.text('switch-to-en'));
      await tester.pumpAndSettle();
      expect(find.textContaining('session has expired'), findsOneWidget);
      expect(find.textContaining('সেশন'), findsNothing);

      await tester.tap(find.text('switch-to-bn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('সেশন'), findsOneWidget);
      expect(find.textContaining('session has expired'), findsNothing);

      // The choice survives a restart (read back from storage).
      expect(storage.getLanguageCode(), 'bn');
      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// Minimal replica of `MaterialApp` wiring from `lib/app/app.dart`: watches
/// [localeProvider] as `locale:` and renders `context.l10n`, with buttons to
/// switch language the same way the Profile screen will.
class _LanguageSwitcherHarness extends ConsumerWidget {
  const _LanguageSwitcherHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // l10n must be read from a context *inside* MaterialApp.
      home: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.sessionExpiredMessage,
              textDirection: TextDirection.ltr,
            ),
            TextButton(
              onPressed: () =>
                  ref.read(localeProvider.notifier).setLanguageCode('en'),
              child: const Text('switch-to-en'),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(localeProvider.notifier).setLanguageCode('bn'),
              child: const Text('switch-to-bn'),
            ),
          ],
        ),
      ),
    );
  }
}
