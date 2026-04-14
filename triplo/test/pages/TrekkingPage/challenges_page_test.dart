import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/model/challenges.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'start_trekking_page_test.mocks.dart';

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
    when(mockController.getCachedImage('image.png'))  // <-- aggiunto
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Sfida Test'), findsOneWidget);
    expect(find.text('Desc Test'), findsOneWidget);
  });

  testWidgets('Mostra messaggio quando non ci sono sfide', (tester) async {
    when(mockController.allChallenges).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Sostituisci con la stringa esatta dal tuo it.arb per la chiave no_challenge
    expect(find.textContaining('Nessuna'), findsOneWidget);
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

  testWidgets('Mostra placeholder su riga dispari se immagine nulla', (tester) async {
    final listaSfide = [
      Challenges(documentId: '1', title: ['T','T','T','T','Prima'], description: ['D','D','D','D','Desc1'], photo: 'a.png'),
      Challenges(documentId: '2', title: ['T','T','T','T','Seconda'], description: ['D','D','D','D','Desc2'], photo: 'b.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('a.png')).thenAnswer((_) async => null);
    when(mockController.getCachedImage('b.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image), findsWidgets);
  });

  testWidgets('Usa fallback index 0 se langIndex fuori range', (tester) async {
    final listaSfide = [
      Challenges(documentId: '1', title: ['Titolo Fallback'], description: ['Desc Fallback'], photo: 'c.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('c.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Titolo Fallback'), findsOneWidget);
    expect(find.text('Desc Fallback'), findsOneWidget);
  });

  testWidgets('Usa no_title e no_description se liste vuote', (tester) async {
    final listaSfide = [
      Challenges(documentId: '1', title: [], description: [], photo: 'd.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('d.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('Mostra sfida in tedesco (de)', (tester) async {
    final listaSfide = [
      Challenges(documentId: '1', title: ['Titel DE','T','T','T','T'], description: ['Beschr DE','D','D','D','D'], photo: 'e.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('e.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider<ChallengesController>.value(value: mockController)],
      child: const MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: [Locale('de'), Locale('en')],
        locale: Locale('de'),
        home: ChallengesPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Titel DE'), findsOneWidget);
  });

  testWidgets('Mostra sfida in spagnolo (es)', (tester) async {
    final listaSfide = [
      Challenges(documentId: '1', title: ['T','T','Titulo ES','T','T'], description: ['D','D','Desc ES','D','D'], photo: 'f.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('f.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider<ChallengesController>.value(value: mockController)],
      child: const MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: [Locale('es'), Locale('en')],
        locale: Locale('es'),
        home: ChallengesPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Titulo ES'), findsOneWidget);
  });

  testWidgets('Apre drawer e mostra tutte le voci', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('Tap su Sfide nel drawer chiude il drawer', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.emoji_events));
    await tester.pumpAndSettle();

    expect(find.byType(ChallengesPage), findsOneWidget);
  });

  testWidgets('Mostra CircularProgressIndicator durante caricamento immagine', (tester) async {
    final completer = Completer<File?>();
    final listaSfide = [
      Challenges(documentId: '1', title: ['T','T','T','T','Loading Test'], description: ['D','D','D','D','Desc'], photo: 'slow.png'),
    ];
    when(mockController.allChallenges).thenReturn(listaSfide);
    when(mockController.getCachedImage('slow.png')).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // un solo pump, non pumpAndSettle

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

}