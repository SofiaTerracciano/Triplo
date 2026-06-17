import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can open login page and login', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('goToLoginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginPage')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'test@example.com',
    );

    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('loginPage found: ${find.byKey(const Key('loginPage')).evaluate().length}');
    print('userPage found: ${find.byKey(const Key('userPage')).evaluate().length}');
    print('goToLoginButton found: ${find.byKey(const Key('goToLoginButton')).evaluate().length}');
    print('snackBars found: ${find.byType(SnackBar).evaluate().length}');

    expect(find.byKey(const Key('userPage')), findsOneWidget);
  });
}