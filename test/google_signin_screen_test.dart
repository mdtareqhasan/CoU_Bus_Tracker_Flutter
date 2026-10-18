import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/auth/google_signin_screen.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
  });

  // The screen navigates only on auth-state changes and user taps, so it can
  // render standalone with just a storage override (no GoRouter needed).
  Future<void> pumpScreen(
    WidgetTester tester, {
    required String role,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GoogleSigninScreen(role: role),
        ),
      ),
    );
    // flutter_animate entrance delays run up to ~500ms; settle them.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
  }

  const reminderTitleEn = 'Before you continue';
  const reminderMessageEn =
      'Make sure you have access to your university email and that it is '
      'already signed in to the Gmail app. When signing in, select your '
      'university email account.';
  const reminderTitleBn = 'এগিয়ে যাওয়ার আগে';
  const reminderMessageBn =
      'আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টে প্রবেশাধিকার আছে এবং অ্যাকাউন্টটি '
      'Gmail অ্যাপে আগে থেকেই সাইন ইন করা আছে কিনা নিশ্চিত করুন। সাইন ইন করার '
      'সময় আপনার বিশ্ববিদ্যালয়ের ইমেইল অ্যাকাউন্টটি নির্বাচন করুন।';

  testWidgets(
    'student login: Gmail reminder shown, redundant institutional prompt gone, '
    'existing format chips + ICT help + button intact',
    (tester) async {
      await pumpScreen(tester, role: 'student');

      // New reminder card (above the required-email-format section).
      expect(find.text(reminderTitleEn), findsOneWidget);
      expect(find.text(reminderMessageEn), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);

      // Redundant institutional prompt is no longer displayed.
      expect(
        find.text('Sign in using your university institutional email.'),
        findsNothing,
      );

      // Existing subtitle unchanged, still below the role heading.
      expect(
        find.text('Sign in with your university email account'),
        findsOneWidget,
      );

      // Existing content preserved (student sees BOTH accepted formats).
      expect(find.text('Required email format:'), findsOneWidget);
      expect(find.text('example@stud.cou.ac.bd'), findsOneWidget);
      expect(find.text('example@cou.ac.bd'), findsOneWidget);
      expect(
        find.text(
          "If you don't have a university email, please contact Comilla "
          'University ICT cell.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
    },
  );

  testWidgets(
    'teacher/officer login: reminder shown, only example@cou.ac.bd chip',
    (tester) async {
      await pumpScreen(tester, role: 'teacher');

      expect(find.text(reminderTitleEn), findsOneWidget);
      expect(find.text(reminderMessageEn), findsOneWidget);

      // Role-specific formats: teacher gets only the staff address.
      expect(find.text('example@cou.ac.bd'), findsOneWidget);
      expect(find.text('example@stud.cou.ac.bd'), findsNothing);
    },
  );

  testWidgets('Bangla: reminder title and message localize correctly', (
    tester,
  ) async {
    await pumpScreen(tester, role: 'student', locale: const Locale('bn'));

    expect(find.text(reminderTitleBn), findsOneWidget);
    expect(find.text(reminderMessageBn), findsOneWidget);
    // English reminder must not leak through under the Bangla locale.
    expect(find.text(reminderTitleEn), findsNothing);
  });
}
