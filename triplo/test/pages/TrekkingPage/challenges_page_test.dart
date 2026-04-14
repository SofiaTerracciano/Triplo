import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/model/challenges.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import 'package:triplo/l10n/app_localizations.dart';


class MockChallengesController extends Mock implements ChallengesController {}


void main() {
  late MockChallengesController mockController;

  setUp(() {
    mockController = MockChallengesController();

    when(mockController.loadChallenges())
        .thenAnswer((_) async {});

    when(mockController.allChallenges).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChallengesController>.value(
          value: mockController,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('it'), Locale('en')],
        locale: Locale('it'),
        home: ChallengesPage(),
      ),
    );
  }

  testWidgets('Mostra loader iniziale', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Mostra la lista delle sfide', (tester) async {
    final listaSfide = [
      Challenges(
        documentId: '1',
        title: ['T', 'T', 'T', 'T', 'Sfida Test'],
        description: ['D', 'D', 'D', 'D', 'Desc Test'],
        photo: 'image.png',
      ),
    ];

    when(mockController.allChallenges).thenReturn(listaSfide);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.pumpAndSettle();

    expect(find.text('Sfida Test'), findsOneWidget);
    expect(find.text('Desc Test'), findsOneWidget);
  });

  testWidgets('Mostra messaggio quando non ci sono sfide', (tester) async {
    when(mockController.allChallenges).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('No'), findsOneWidget);
  });

  testWidgets('Mostra placeholder se immagine nulla', (tester) async {
    final listaSfide = [
      Challenges(
        documentId: '2',
        title: ['T', 'T', 'T', 'T', 'Test Foto'],
        description: ['D', 'D', 'D', 'D', 'Desc'],
        photo: 'broken.png',
      ),
    ];

    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('broken.png'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image), findsWidgets);
  });

  testWidgets('Mostra immagine quando disponibile', (tester) async {
    final file = File('test.png');

    final listaSfide = [
      Challenges(
        documentId: '3',
        title: ['T', 'T', 'T', 'T', 'Con immagine'],
        description: ['D', 'D', 'D', 'D', 'Desc'],
        photo: 'ok.png',
      ),
    ];

    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('ok.png'))
        .thenAnswer((_) async => file);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Apre drawer e clicca Home', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.textContaining('Home'), findsOneWidget);
  });
}