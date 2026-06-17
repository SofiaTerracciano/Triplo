import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
      int maxSeconds = 15,
    }) async {
  for (int i = 0; i < maxSeconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can login with Google and reach the user page', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('goToLoginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginPage')), findsOneWidget);

    await tester.tap(find.byKey(const Key('google_login_button')));

    await waitFor(
      tester,
      find.byKey(const Key('userPage')),
      maxSeconds: 15,
    );

    expect(find.byKey(const Key('userPage')), findsOneWidget);
  });
}