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

Future<void> loginWithEmailAndPassword(
    WidgetTester tester, {
      String email = 'test@example.com',
      String password = 'password123',
    }) async {
  await tester.tap(find.byKey(const Key('goToLoginButton')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('loginPage')), findsOneWidget);

  await tester.enterText(find.byKey(const Key('emailField')), email);
  await tester.enterText(find.byKey(const Key('passwordField')), password);

  await tester.tap(find.byKey(const Key('loginButton')));

  await waitFor(
    tester,
    find.byKey(const Key('userPage')),
    maxSeconds: 20,
  );

  expect(find.byKey(const Key('userPage')), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can search a trekking and open its details', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    await loginWithEmailAndPassword(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSearchPageButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('searchPage')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trekkingModeFilter')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('searchTextField')),
      'Monte',
    );

    await waitFor(
      tester,
      find.byKey(const Key('trekkingResult_0')),
      maxSeconds: 20,
    );

    expect(find.byKey(const Key('trekkingResult_0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trekkingResult_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trekkingDetailsPage')), findsOneWidget);
  });
}