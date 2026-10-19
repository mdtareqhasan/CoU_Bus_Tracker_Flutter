import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/app/app.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // SplashScreen._init() calls PackageInfo.fromPlatform(). Without a mock
    // this throws MissingPluginException, _init() aborts, and the app is
    // stuck on the splash frame forever — no route ever resolves.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async {
            if (call.method == 'getAll') {
              return <String, dynamic>{
                'appName': 'CoU Bus Tracker',
                'packageName': 'com.cou.bustracker',
                'version': '1.0.0',
                'buildNumber': '1',
                'buildSignature': '',
                'installerStore': null,
              };
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          null,
        );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // CoUBusTrackerApp reads localeProvider, which reads storageServiceProvider;
    // without the override the scope throws "must be overridden".
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const CoUBusTrackerApp(),
      ),
    );
    // The splash screen waits out a bounded session-restore timeout before
    // deciding where to land. In the test environment the restore future
    // never settles, so the app only navigates once that safety timeout
    // fires. Pump past it (fake time → cheap in wall-clock).
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // With no saved session the app lands on the Google-only role picker —
    // not /home, so the bottom-nav 'হোম' never renders here. With no saved
    // language choice the picker must come up in Bangla regardless of the
    // (English) test-host locale: its title is roleSelectTitle = 'আপনার ভূমিকা'.
    expect(find.text('আপনার ভূমিকা'), findsOneWidget);
  });
}
