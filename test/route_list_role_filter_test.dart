import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cou_bus_tracker/core/api_client.dart';
import 'package:cou_bus_tracker/core/result.dart';
import 'package:cou_bus_tracker/core/storage_service.dart';
import 'package:cou_bus_tracker/features/auth/auth_provider.dart';
import 'package:cou_bus_tracker/features/auth/auth_repository.dart';
import 'package:cou_bus_tracker/features/notifications/fcm_token_service.dart';
import 'package:cou_bus_tracker/features/notifications/notification_repository.dart';
import 'package:cou_bus_tracker/features/providers.dart';
import 'package:cou_bus_tracker/features/routes/route_repository.dart';
import 'package:cou_bus_tracker/features/routes/route_screen.dart';
import 'package:cou_bus_tracker/features/routes/routes_provider.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:cou_bus_tracker/shared/models/bus_route.dart';
import 'package:cou_bus_tracker/shared/models/route_preference.dart';
import 'package:cou_bus_tracker/shared/widgets/route_card.dart';

/// `GET /routes` is public and carries one total per route, so the role gate
/// for the Routes tab has to be applied client-side — twice:
///
///  * the trip badge counts only the categories the signed-in role may ride
///    (a student must not be told a teacher bus runs 4 trips on this line),
///  * a corridor whose trips *all* belong to the other role is not listed at
///    all, while a genuinely empty one still is ("No trips yet" is its story).
///
/// The count needs the server's per-category breakdown, so the badge degrades
/// to the route total on a backend that predates it — pinned here as well.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // --- Fixtures -----------------------------------------------------------

  final teacherOnly = BusRoute(
    id: 1,
    nameEn: 'Teacher Loop',
    nameBn: 'শিক্ষক লুপ',
    activeScheduleCount: 4,
    activeScheduleCountsByCategory: const {'TEACHER': 4},
  );
  final mixed = BusRoute(
    id: 2,
    nameEn: 'Mixed Line',
    nameBn: 'মিক্সড লাইন',
    activeScheduleCount: 5,
    activeScheduleCountsByCategory: const {'BLUE': 2, 'TEACHER': 3},
  );
  final studentOnly = BusRoute(
    id: 3,
    nameEn: 'Student Line',
    nameBn: 'ছাত্র লাইন',
    activeScheduleCount: 6,
    activeScheduleCountsByCategory: const {'STAFF': 6},
  );
  final empty = BusRoute(
    id: 4,
    nameEn: 'Empty Line',
    nameBn: 'খালি লাইন',
    activeScheduleCount: 0,
    activeScheduleCountsByCategory: const {},
  );
  final legacy = BusRoute(
    id: 5,
    nameEn: 'Legacy Line',
    nameBn: 'লিগেসি লাইন',
    activeScheduleCount: 7, // served before the breakdown existed
  );

  const student = {'BLUE', 'RED', 'STAFF'};
  const teacher = {'TEACHER', 'OFFICER'};

  group('BusRoute trip gate', () {
    test('visibleTripCount sums only the categories the role may ride', () {
      expect(mixed.visibleTripCount(student), 2,
          reason: 'the teacher buses on a mixed line are not the rides');
      expect(mixed.visibleTripCount(teacher), 3);
      expect(teacherOnly.visibleTripCount(student), 0);
      expect(studentOnly.visibleTripCount(teacher), 0);
    });

    test('a listing with no breakdown falls back to the route total', () {
      expect(legacy.visibleTripCount(student), 7,
          reason: 'a missing field must not hide or zero every route');
      expect(legacy.visibleTripCount(teacher), 7);
    });

    test('shouldListFor hides a corridor whose trips are all the other role', () {
      expect(teacherOnly.shouldListFor(student), isFalse);
      expect(studentOnly.shouldListFor(teacher), isFalse);
      expect(mixed.shouldListFor(student), isTrue);
      expect(studentOnly.shouldListFor(student), isTrue);
    });

    test('a route with no trips at all is still listed', () {
      expect(empty.shouldListFor(student), isTrue,
          reason: '"No trips yet" is its honest label, not a role problem');
      expect(empty.shouldListFor(teacher), isTrue);
      expect(empty.visibleTripCount(student), 0);
    });

    test('an unroutable legacy row is listed rather than guessed away', () {
      expect(legacy.shouldListFor(student), isTrue);
    });

    test('a pair stays when only one direction has rides for this role', () {
      final group = RouteGroup(
        route: teacherOnly,
        opposite: BusRoute(
          id: 6,
          nameEn: 'Student Return',
          activeScheduleCount: 2,
          activeScheduleCountsByCategory: const {'BLUE': 2},
        ),
      );

      expect(group.shouldListFor(student), isTrue,
          reason: 'the corridor is one card or none — never a torn pair');
      expect(
        RouteGroup(route: teacherOnly, opposite: mixed).shouldListFor(student),
        isTrue,
      );
      expect(RouteGroup(route: teacherOnly).shouldListFor(student), isFalse);
    });
  });

  group('Routes tab', () {
    Future<void> pumpRoutes(WidgetTester tester, {required String role}) async {
      StorageService.resetInstanceForTesting();
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();

      // RouteCard picks the route name through the static L10n.locale (which
      // the app's LocaleController keeps in step with the MaterialApp locale)
      // while labels come from the context — sync both to English so one test
      // asserts both halves in the same language.
      L10n.activate(const Locale('en'));

      final repository = _FakeRouteRepository(storage)
        ..routes = [teacherOnly, mixed, studentOnly, empty];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            routeRepositoryProvider.overrideWithValue(repository),
            authProvider.overrideWith((_) => _RoleAuthNotifier(storage, role)),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RouteScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a student gets student corridors and student counts', (
      tester,
    ) async {
      await pumpRoutes(tester, role: 'student');

      // Three of the four corridors: the teacher-only one is not listed.
      expect(find.byType(RouteCard), findsNWidgets(3));
      expect(find.text('Teacher Loop'), findsNothing);

      expect(find.text('Mixed Line'), findsOneWidget);
      expect(
        find.text('2 trips'),
        findsOneWidget,
        reason: 'only the BLUE trips — the 3 teacher buses are not counted',
      );
      expect(find.text('Student Line'), findsOneWidget);
      expect(find.text('6 trips'), findsOneWidget);

      // A corridor with no trips at all still shows, with its own label.
      expect(find.text('Empty Line'), findsOneWidget);
      expect(find.text('No trips yet'), findsOneWidget);
    });

    testWidgets('a teacher sees the same list flipped', (tester) async {
      await pumpRoutes(tester, role: 'teacher');

      expect(find.byType(RouteCard), findsNWidgets(3));
      expect(find.text('Student Line'), findsNothing);
      expect(find.text('6 trips'), findsNothing,
          reason: "the student bus's count must not appear for a teacher");

      expect(find.text('Teacher Loop'), findsOneWidget);
      expect(find.text('4 trips'), findsOneWidget);
      expect(find.text('Mixed Line'), findsOneWidget);
      expect(find.text('3 trips'), findsOneWidget, reason: 'the TEACHER share');
      expect(find.text('No trips yet'), findsOneWidget);
    });
  });
}

/// Serves the route listing (and an empty pin list, which the screen loads)
/// without touching the network — the house fake-repository style.
class _FakeRouteRepository extends RouteRepository {
  _FakeRouteRepository(StorageService storage) : super(ApiClient(storage));

  List<BusRoute> routes = const [];

  @override
  Future<Result<List<BusRoute>>> getRoutes() async => Success(routes);

  @override
  Future<Result<List<RoutePreference>>> getMyPreferences() async =>
      Success(const <RoutePreference>[]);
}

/// An [AuthNotifier] pinned to one signed-in role. Its constructor kicks off a
/// session restore that only rewrites `status`, so the role set here survives.
class _RoleAuthNotifier extends AuthNotifier {
  _RoleAuthNotifier(StorageService storage, String role)
    : super(
        AuthRepository(ApiClient(storage)),
        storage,
        FcmTokenService(NotificationRepository(ApiClient(storage)), storage),
      ) {
    state = AuthState(
      status: AuthStateStatus.authenticated,
      role: role,
      displayName: 'Test Rider',
    );
  }
}
