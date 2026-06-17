

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  await tester.enterText(
    find.byKey(const Key('emailField')),
    email,
  );

  await tester.enterText(
    find.byKey(const Key('passwordField')),
    password,
  );

  await tester.tap(find.byKey(const Key('loginButton')));

  await waitFor(
    tester,
    find.byKey(const Key('userPage')),
    maxSeconds: 20,
  );

  expect(find.byKey(const Key('userPage')), findsOneWidget);
}