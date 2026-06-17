
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

import 'login_support_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can change language preference from Italian to English', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    await loginWithEmailAndPassword(tester);

    expect(find.byKey(const Key('userPage')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openSettingsButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingPage')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('languageSettingsButton')));
    await tester.tap(find.byKey(const Key('languageSettingsButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('languageOptionItalian')), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageOptionItalian')));
    await tester.pumpAndSettle();

    expect(find.text('Italiano'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('languageSettingsButton')));
    await tester.tap(find.byKey(const Key('languageSettingsButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('languageOptionEnglish')), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageOptionEnglish')));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
  });
}