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
import 'package:cou_bus_tracker/features/routes/route_detail_screen.dart';
import 'package:cou_bus_tracker/features/routes/route_repository.dart';
import 'package:cou_bus_tracker/l10n/l10n.dart';
import 'package:cou_bus_tracker/shared/models/bus_route.dart';
import 'package:cou_bus_tracker/shared/models/schedule.dart';
import 'package:cou_bus_tracker/shared/widgets/schedule_card.dart';

/// `GET /schedules/route/{id}` is public and returns every category's trips —
/// a route is shared by student, staff and teacher buses. The role gate is
/// therefore applied in the detail screen itself, exactly as the Home, Buses
/// and Schedules tabs do it. This test pins that the screen keeps applying it:
/// a teacher who taps a route must never see a student trip (and vice versa).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const route = BusRoute(
    id: 1,
    nameEn: 'Kandirpar → Campus',
    nameBn: 'কান্দিরপার → ক্যাম্পাস',
  );

  /// One trip per category so each expectation keys off a unique bus number
  /// (bus numbers are data, not localized copy, so the assertions hold in
  /// either app language).
  final trips = <Schedule>[
    _trip(id: 1, category: 'TEACHER', busNumber: 'T-01'),
    _trip(id: 2, category: 'OFFICER', busNumber: 'O-01'),
    _trip(id: 3, category: 'BLUE', busNumber: 'B-01'),
    _trip(id: 4, category: 'RED', busNumber: 'R-01'),
    _trip(id: 5, category: 'STAFF', busNumber: 'S-01'),
    // In no role's allowed set: must not leak to either rider.
    _trip(id: 6, category: 'CHARTER', busNumber: 'C-01'),
  ];

  Future<void> pumpRouteDetail(WidgetTester tester, {required String role}) async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    final repository = _FakeRouteRepository(storage)
      ..routes = const [route]
      ..schedules = trips;

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
          home: const RouteDetailScreen(routeId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a teacher only sees teacher/officer trips on the route',
      (tester) async {
    await pumpRouteDetail(tester, role: 'teacher');

    expect(find.byType(ScheduleCard), findsNWidgets(2));
    expect(find.text('T-01'), findsOneWidget);
    expect(find.text('O-01'), findsOneWidget);

    expect(find.text('B-01'), findsNothing);
    expect(find.text('R-01'), findsNothing);
    expect(find.text('S-01'), findsNothing);
    expect(find.text('C-01'), findsNothing);
  });

  testWidgets('a student only sees student trips on the route',
      (tester) async {
    await pumpRouteDetail(tester, role: 'student');

    expect(find.byType(ScheduleCard), findsNWidgets(3));
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('R-01'), findsOneWidget);
    expect(find.text('S-01'), findsOneWidget);

    expect(find.text('T-01'), findsNothing);
    expect(find.text('O-01'), findsNothing);
    expect(find.text('C-01'), findsNothing);
  });

  testWidgets('a route holding only the other role\'s trips reads as empty '
      'rather than listing foreign trips', (tester) async {
    StorageService.resetInstanceForTesting();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();

    final repository = _FakeRouteRepository(storage)
      ..routes = const [route]
      ..schedules = [trips[0], trips[1]]; // TEACHER + OFFICER only

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          routeRepositoryProvider.overrideWithValue(repository),
          authProvider.overrideWith((_) => _RoleAuthNotifier(storage, 'student')),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RouteDetailScreen(routeId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleCard), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsWidgets); // empty state
  });
}

Schedule _trip({
  required int id,
  required String category,
  required String busNumber,
}) {
  return Schedule(
    id: id,
    busId: 100 + id,
    busNumber: busNumber,
    category: category,
    departureTime: '07:00',
    direction: 'UP',
    routeId: 1,
    routeNameEn: 'Kandirpar → Campus',
    routeNameBn: 'কান্দিরপার → ক্যাম্পাস',
    days: 'SUN-THU',
  );
}

/// Serves the route listing and this route's trips without touching the
/// network — same fake-repository style as the rest of the suite.
class _FakeRouteRepository extends RouteRepository {
  _FakeRouteRepository(StorageService storage) : super(ApiClient(storage));

  List<BusRoute> routes = const [];
  List<Schedule> schedules = const [];

  @override
  Future<Result<List<BusRoute>>> getRoutes() async => Success(routes);

  @override
  Future<Result<List<Schedule>>> getSchedulesByRoute(int routeId) async =>
      Success(schedules.where((s) => s.routeId == routeId).toList());
}

/// An [AuthNotifier] pinned to one signed-in role. Its constructor kicks off
/// a session restore that only ever rewrites `status` (the stored role is
/// absent under the empty mock prefs), so the role set here survives.
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
