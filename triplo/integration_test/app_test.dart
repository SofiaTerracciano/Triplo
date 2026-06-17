import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts correctly', (WidgetTester tester) async {
    await app.main();

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appMain')), findsOneWidget);
  });
}