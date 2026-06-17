import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:triplo/main.dart' as app;

import 'login_support_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can add a diary page for a trekking', (
      WidgetTester tester,
      ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final notes = 'Diary created by integration test $timestamp';

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

    await tester.ensureVisible(find.byKey(const Key('openAddDiaryButton')));
    await tester.tap(find.byKey(const Key('openAddDiaryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addDiaryPage')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('diaryNotesField')));
    await tester.enterText(
      find.byKey(const Key('diaryNotesField')),
      notes,
    );



    await tester.ensureVisible(find.byKey(const Key('saveDiaryButton')));
    await tester.tap(find.byKey(const Key('saveDiaryButton')));

    await waitFor(
      tester,
      find.byKey(const Key('userPage')),
      maxSeconds: 40,
    );

    print('addDiaryPage: ${find.byKey(const Key('addDiaryPage')).evaluate().length}');
    print('loadingPage: ${find.byKey(const Key('loadingPage')).evaluate().length}');
    print('userPage: ${find.byKey(const Key('userPage')).evaluate().length}');
    print('SnackBars: ${find.byType(SnackBar).evaluate().length}');

    expect(find.byKey(const Key('userPage')), findsOneWidget);

  });
}