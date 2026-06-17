import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
      int maxSeconds = 20,
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

  testWidgets('User can register and reach the user page', (
      WidgetTester tester,
      ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'testuser$timestamp@example.com';

    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('goToLoginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginPage')), findsOneWidget);

    await tester.tap(find.byKey(const Key('goToRegistrationButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('registrationPage')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('registrationEmailField')),
      email,
    );

    await tester.enterText(
      find.byKey(const Key('registrationPasswordField')),
      'Password123!',
    );

    await tester.enterText(
      find.byKey(const Key('registrationConfirmPasswordField')),
      'Password123!',
    );

    await tester.tap(find.byKey(const Key('registrationButton')));

    await waitFor(
      tester,
      find.byKey(const Key('userPage')),
      maxSeconds: 20,
    );
    print('registrationPage: ${find.byKey(const Key('registrationPage')).evaluate().length}');
    print('loginPage: ${find.byKey(const Key('loginPage')).evaluate().length}');
    print('userPage: ${find.byKey(const Key('userPage')).evaluate().length}');
    print('goToLoginButton: ${find.byKey(const Key('goToLoginButton')).evaluate().length}');
    print('SnackBars: ${find.byType(SnackBar).evaluate().length}');
    expect(find.byKey(const Key('settingPage')), findsOneWidget);
  });
}