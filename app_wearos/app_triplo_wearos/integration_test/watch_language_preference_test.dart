import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app_triplo_wearos/main.dart' as app;

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

  throw TestFailure('Widget not found after $maxSeconds seconds: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Watch user can change language preference', (
      WidgetTester tester,
      ) async {
    await app.main();
    await tester.pumpAndSettle();

    await waitFor(
      tester,
      find.byKey(const Key('openWatchLanguageButton')),
      maxSeconds: 20,
    );

    expect(find.byKey(const Key('openWatchLanguageButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openWatchLanguageButton')));
    await tester.pumpAndSettle();

    await waitFor(
      tester,
      find.byKey(const Key('watchLanguageOptionItalian')),
      maxSeconds: 10,
    );

    expect(find.byKey(const Key('watchLanguageOptionItalian')), findsOneWidget);

    await tester.tap(find.byKey(const Key('watchLanguageOptionItalian')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openWatchLanguageButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openWatchLanguageButton')));
    await tester.pumpAndSettle();

    await waitFor(
      tester,
      find.byKey(const Key('watchLanguageOptionEnglish')),
      maxSeconds: 10,
    );

    expect(find.byKey(const Key('watchLanguageOptionEnglish')), findsOneWidget);

    await tester.tap(find.byKey(const Key('watchLanguageOptionEnglish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openWatchLanguageButton')), findsOneWidget);
  });
}