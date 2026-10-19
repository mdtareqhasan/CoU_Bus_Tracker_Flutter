import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/core/api_client.dart';
import 'package:cou_bus_tracker/core/result.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/auth/academic_details_screen.dart';
import 'package:cou_bus_tracker/features/auth/academic_options_provider.dart';
import 'package:cou_bus_tracker/features/auth/academic_reference_repository.dart';
import 'package:cou_bus_tracker/features/auth/auth_provider.dart';
import 'package:cou_bus_tracker/features/auth/auth_repository.dart';
import 'package:cou_bus_tracker/features/notifications/fcm_token_service.dart';
import 'package:cou_bus_tracker/features/notifications/notification_repository.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:cou_bus_tracker/shared/models/academic_reference_option.dart';

/// Serves canned option lists (or a canned failure) without touching the
/// network. [gate] withholds every response until the test releases it, which
/// is how the loading placeholder gets observed.
class _FakeAcademicRepository extends AcademicReferenceRepository {
  _FakeAcademicRepository(StorageService storage) : super(ApiClient(storage));

  List<AcademicReferenceOption> units = const [];
  List<AcademicReferenceOption> sessions = const [];
  Completer<void>? gate;
  String? failWith;
  int unitRequests = 0;

  @override
  Future<Result<List<AcademicReferenceOption>>> getUnits() async {
    unitRequests += 1;
    await gate?.future;
    final failure = failWith;
    if (failure != null) return Failure(message: failure);
    return Success(units);
  }

  @override
  Future<Result<List<AcademicReferenceOption>>> getSessions() async {
    await gate?.future;
    final failure = failWith;
    if (failure != null) return Failure(message: failure);
    return Success(sessions);
  }
}

/// Auth state as the completion screen finds it after a profile fetch: the
/// academic values are stored as *text* but the profile carried no option ids
/// — the case the screen must recover from the fetched list on save.
///
/// [updateAcademicDetails] records what the screen submitted and reports a
/// failure so the screen stays put (it navigates to /home on success, and
/// there is no GoRouter in these tests).
class _CapturingAuthNotifier extends AuthNotifier {
  _CapturingAuthNotifier(StorageService storage)
    : super(
        AuthRepository(ApiClient(storage)),
        storage,
        FcmTokenService(NotificationRepository(ApiClient(storage)), storage),
      ) {
    state = const AuthState(
      status: AuthStateStatus.needsProfileDetails,
      role: 'student',
      department: 'নতুন বিভাগ',
      rollNumber: '21-01-01',
      session: '2025-2026',
    );
  }

  int? submittedDepartmentId;
  int? submittedSessionId;
  String? submittedRollNumber;

  @override
  Future<Result<Map<String, dynamic>>> updateAcademicDetails({
    required int departmentId,
    String? rollNumber,
    int? sessionId,
    String? employeeId,
    String? designation,
  }) async {
    submittedDepartmentId = departmentId;
    submittedSessionId = sessionId;
    submittedRollNumber = rollNumber;
    return const Failure<Map<String, dynamic>>(
      message: 'save rejected by test server',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
  });

  AcademicReferenceOption unit(int id, {String type = 'DEPARTMENT'}) {
    return AcademicReferenceOption(
      id: id,
      value: id == 101 ? 'নতুন বিভাগ' : 'পদার্থবিজ্ঞান',
      labelBn: id == 101 ? 'নতুন বিভাগ' : 'পদার্থবিজ্ঞান',
      labelEn: id == 101 ? 'New Department (XYZ)' : 'Physics',
      type: type,
      sortOrder: id,
    );
  }

  AcademicReferenceOption office(int id) => AcademicReferenceOption(
    id: id,
    value: 'আইসিটি সেল',
    labelBn: 'আইসিটি সেল',
    labelEn: 'ICT Cell',
    type: 'OFFICE',
    sortOrder: id,
  );

  AcademicReferenceOption session(int id) => AcademicReferenceOption(
    id: id,
    value: '2025-2026',
    labelBn: '২০২৫-২০২৬',
    labelEn: '2025-2026',
    sortOrder: id,
  );

  // ---------------------------------------------------------------------------
  // Reference model + option filtering
  // ---------------------------------------------------------------------------

  group('AcademicReferenceOption', () {
    test('fromJson reads the reference payload', () {
      final option = AcademicReferenceOption.fromJson({
        'id': 7,
        'value': 'গণিত',
        'labelBn': 'গণিত',
        'labelEn': 'Mathematics',
        'type': 'DEPARTMENT',
        'sortOrder': 3,
        'active': true,
      });

      expect(option.id, 7);
      expect(option.value, 'গণিত');
      expect(option.labelBn, 'গণিত');
      expect(option.labelEn, 'Mathematics');
      expect(option.type, 'DEPARTMENT');
      expect(option.isDepartment, isTrue);
      expect(option.sortOrder, 3);
      expect(option.active, isTrue);
    });

    test('fromJson tolerates missing optional fields', () {
      final option = AcademicReferenceOption.fromJson({
        'id': 7,
        'value': 'x',
        'labelBn': 'x',
        'labelEn': 'x',
      });

      expect(option.type, isNull);
      expect(option.isDepartment, isFalse);
      expect(option.sortOrder, 0);
      expect(option.active, isTrue);
    });

    test('labelFor picks the locale and falls back to Bangla', () {
      final option = AcademicReferenceOption(
        id: 7,
        value: 'গণিত',
        labelBn: 'গণিত',
        labelEn: 'Mathematics',
      );

      expect(option.labelFor('en'), 'Mathematics');
      expect(option.labelFor('bn'), 'গণিত');
      // Regional or unknown codes still render the source language, never
      // the raw id.
      expect(option.labelFor('en_US'), 'Mathematics');
      expect(option.labelFor('de'), 'গণিত');
    });
  });

  group('AcademicOptions.unitsForRole', () {
    final options = AcademicOptions(
      units: [unit(101), unit(102), office(103)],
      sessions: [session(201)],
    );

    test('students are offered teaching departments only', () {
      final forStudent = options.unitsForRole('student');
      expect(forStudent, hasLength(2));
      expect(forStudent.every((option) => option.isDepartment), isTrue);
      // Order is preserved (sort order comes back from the server).
      expect(forStudent.map((option) => option.id), [101, 102]);
    });

    test('teachers get departments and offices in the combined order', () {
      final forTeacher = options.unitsForRole('TEACHER');
      expect(forTeacher.map((option) => option.id), [101, 102, 103]);
    });
  });

  // ---------------------------------------------------------------------------
  // Provider (both lists, single loading/error story)
  // ---------------------------------------------------------------------------

  group('academicOptionsProvider', () {
    test('combines the units and sessions lists', () async {
      final repository = _FakeAcademicRepository(storage)
        ..units = [unit(101), unit(102)]
        ..sessions = [session(201)];
      final container = ProviderContainer(
        overrides: [
          academicReferenceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final options = await container.read(academicOptionsProvider.future);

      expect(options.units, hasLength(2));
      expect(options.sessions, hasLength(1));
      expect(repository.unitRequests, 1);
    });

    test('surfaces the repository failure message', () async {
      final repository = _FakeAcademicRepository(storage)
        ..failWith = 'Check your internet connection.';
      final container = ProviderContainer(
        overrides: [
          academicReferenceRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(academicOptionsProvider.future),
        throwsA(
          isA<AcademicOptionsException>().having(
            (error) => error.message,
            'message',
            'Check your internet connection.',
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // The completion screen's pickers
  // ---------------------------------------------------------------------------

  Future<void> pumpScreen(
    WidgetTester tester, {
    required String role,
    required _FakeAcademicRepository repository,
    AuthNotifier Function()? auth,
    Locale locale = const Locale('en'),
  }) async {
    final overrides = <Override>[
      storageServiceProvider.overrideWithValue(storage),
      academicReferenceRepositoryProvider.overrideWithValue(repository),
      if (auth != null) authProvider.overrideWith((_) => auth()),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AcademicDetailsScreen(role: role),
        ),
      ),
    );
    // flutter_animate entrance delays run up to ~600ms; settle them.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
    'student pickers fill from the backend: placeholder while loading, '
    'server labels only, selection keeps the option id',
    (tester) async {
      final repository = _FakeAcademicRepository(storage)
        ..units = [unit(101), unit(102), office(103)]
        ..sessions = [session(201)]
        ..gate = Completer<void>();

      await pumpScreen(tester, role: 'student', repository: repository);

      // While the list is in flight the picker is a placeholder, not an empty
      // dropdown.
      expect(find.text('Loading list…'), findsWidgets);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);

      repository.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Department + session; the office (teacher-only) is not offered.
      expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2));
      expect(find.text('Loading list…'), findsNothing);

      final departmentDropdown = find.byType(DropdownButtonFormField<int>)
          .first;
      await tester.ensureVisible(departmentDropdown);
      await tester.pumpAndSettle();
      await tester.tap(departmentDropdown);
      await tester.pumpAndSettle();

      // The list is exactly what the server sent — none of the labels the old
      // hardcoded list bundled (e.g. l10n 'Mathematics') leak in.
      expect(find.text('New Department (XYZ)'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Mathematics'), findsNothing);

      await tester.tap(find.text('New Department (XYZ)'));
      await tester.pumpAndSettle();

      // The button now shows the picked option (in the app's language)…
      expect(find.text('New Department (XYZ)'), findsOneWidget);
      expect(find.text('Select department'), findsNothing);
    },
  );

  testWidgets('teacher picker offers departments and offices, no session', (
    tester,
  ) async {
    final repository = _FakeAcademicRepository(storage)
      ..units = [unit(101), office(103)]
      ..sessions = [session(201)];

    await pumpScreen(tester, role: 'teacher', repository: repository);

    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

    final unitDropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(unitDropdown);
    await tester.pumpAndSettle();
    await tester.tap(unitDropdown);
    await tester.pumpAndSettle();

    expect(find.text('New Department (XYZ)'), findsOneWidget);
    expect(find.text('ICT Cell'), findsOneWidget);
  });

  testWidgets('a failed list shows the message and the retry refetches', (
    tester,
  ) async {
    final repository = _FakeAcademicRepository(storage)
      ..failWith = 'Check your internet connection.';

    await pumpScreen(tester, role: 'student', repository: repository);

    // Both pickers explain themselves instead of vanishing silently…
    expect(find.textContaining('Check your internet connection.'), findsNWidgets(2));
    expect(find.text('Try again'), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);

    // …and the retry actually refetches once the cause is gone.
    repository.failWith = null;
    await tester.tap(find.text('Try again').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2));
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets(
    'locked values render server labels and Save submits the option ids',
    (tester) async {
      final repository = _FakeAcademicRepository(storage)
        ..units = [unit(101), unit(102)]
        ..sessions = [session(201)];
      final auth = _CapturingAuthNotifier(storage);

      await pumpScreen(
        tester,
        role: 'student',
        repository: repository,
        auth: () => auth,
      );

      // Everything the profile already stored is locked, and its label comes
      // from the fetched option — not from the bundled list, which has no
      // entry for 'নতুন বিভাগ' and would render the raw value.
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      expect(find.text('New Department (XYZ)'), findsOneWidget);
      expect(find.text('নতুন বিভাগ'), findsNothing);

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The submission carried row ids (recovered from the fetched list —
      // the seeded profile had none), never the name strings.
      expect(auth.submittedDepartmentId, 101);
      expect(auth.submittedSessionId, 201);
      expect(auth.submittedRollNumber, '21-01-01');

      // The failure the fake notifier reported is shown as a banner.
      expect(find.text('save rejected by test server'), findsOneWidget);
    },
  );
}
