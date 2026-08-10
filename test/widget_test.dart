import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cou_bus_tracker/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CoUBusTrackerApp()),
    );
    expect(find.text('হোম'), findsOneWidget);
  });
}
