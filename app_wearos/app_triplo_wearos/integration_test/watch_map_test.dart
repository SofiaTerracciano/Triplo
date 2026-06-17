import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:app_triplo_wearos/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Watch user can open the map and use map controls', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openWatchHomeButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openWatchHomeButton')));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('watchExplorePage')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('watchExplorePage')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}