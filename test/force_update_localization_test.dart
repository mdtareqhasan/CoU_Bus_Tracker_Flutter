import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cou_bus_tracker/core/config/remote_config_service.dart';
import 'package:cou_bus_tracker/features/splash/force_update_screen.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

/// The super admin writes the update copy in both languages. These tests pin
/// the selection rules so an English-locale rider never sees the Bangla
/// message (and vice versa), including the fallback chain:
/// own language → other language → legacy single message → localized default.
void main() {
  Widget appWith({
    required Locale locale,
    String legacy = '',
    String bn = '',
    String en = '',
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ForceUpdateScreen(
        message: legacy,
        messageBn: bn,
        messageEn: en,
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.cou.bustracker',
        forceUpdate: true,
      ),
    );
  }

  group('ForceUpdateScreen message selection', () {
    testWidgets('Bangla locale shows the Bangla copy', (tester) async {
      await tester.pumpWidget(appWith(
        locale: const Locale('bn'),
        bn: 'নতুন ভার্সন এসেছে',
        en: 'A new version is here',
      ));

      expect(find.text('নতুন ভার্সন এসেছে'), findsOneWidget);
      expect(find.text('A new version is here'), findsNothing);
    });

    testWidgets('English locale shows the English copy', (tester) async {
      await tester.pumpWidget(appWith(
        locale: const Locale('en'),
        bn: 'নতুন ভার্সন এসেছে',
        en: 'A new version is here',
      ));

      expect(find.text('A new version is here'), findsOneWidget);
      expect(find.text('নতুন ভার্সন এসেছে'), findsNothing);
    });

    testWidgets('empty English copy falls back to Bangla', (tester) async {
      await tester.pumpWidget(appWith(
        locale: const Locale('en'),
        bn: 'শুধু বাংলা লেখা আছে',
      ));

      expect(find.text('শুধু বাংলা লেখা আছে'), findsOneWidget);
    });

    testWidgets('both empty falls back to the legacy message', (tester) async {
      await tester.pumpWidget(appWith(
        locale: const Locale('en'),
        legacy: 'Legacy update text',
      ));

      expect(find.text('Legacy update text'), findsOneWidget);
    });

    testWidgets('no admin copy at all uses the translated default',
        (tester) async {
      await tester.pumpWidget(appWith(locale: const Locale('en')));

      expect(find.text('A new version of the app is available. Please update.'),
          findsOneWidget);
    });
  });

  group('PublicConfig parsing', () {
    test('reads both language variants', () {
      final config = PublicConfig.fromJson(const {
        'updateMessage': 'legacy',
        'updateMessageBn': 'বাংলা',
        'updateMessageEn': 'English',
        'latestAppVersion': '1.2.0',
        'minimumAppVersion': '1.0.0',
        'forceUpdate': true,
        'playStoreUrl': 'https://example.com/store',
        'maintenanceMode': false,
        'maintenanceMessage': '',
      });

      expect(config.updateMessageBn, 'বাংলা');
      expect(config.updateMessageEn, 'English');
      expect(config.updateMessage, 'legacy');
    });

    test('older payload without language keys reuses the legacy message', () {
      final config = PublicConfig.fromJson(const {
        'updateMessage': 'Only one language',
        'latestAppVersion': '1.0.0',
        'minimumAppVersion': '1.0.0',
        'forceUpdate': false,
        'playStoreUrl': 'https://example.com/store',
        'maintenanceMode': false,
        'maintenanceMessage': '',
      });

      expect(config.updateMessageBn, 'Only one language');
      expect(config.updateMessageEn, 'Only one language');
    });
  });
}
