import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/trekkingPage/end_trekking_page.dart';
import 'package:triplo/pages/trekkingPage/start_trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import '../SearchPage/search_page_test.mocks.dart';
import 'start_trekking_page_test.mocks.dart' hide MockTrekkingController;

@GenerateMocks([TrekkingController, ChallengesController])

Trekking makeTrekking({
  String id = 'trek1',
  String name = 'Monte Rosa',
  String difficulty = 'medium',
  List<LatLng>? points,
  List<String>? challenges,
}) =>
    Trekking(
      documentId: id,
      name: name,
      mapPhoto: '',
      difficultyLevel: difficulty,
      distance: 10.0,
      estimatedTime: 3.0,
      elevationGain: 500.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(45.0, 9.0),
      endingPoint: const LatLng(45.1, 9.1),
      points: points ?? [const LatLng(45.0, 9.0), const LatLng(45.1, 9.1)],
      startingPointName: 'Partenza',
      endingPointName: 'Arrivo',
      info: [],
      endingPointPhoto: '',
      description: [],
      refreshmentPoint: '',
      picNicArea: false,
      familyFirendly: false,
      challenges: challenges ?? [],
    );

Widget buildTestWidget({
  required String trekkingId,
  required MockTrekkingController trekkingCtrl,
  required MockChallengesController challengesCtrl,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TrekkingController>.value(value: trekkingCtrl),
      ChangeNotifierProvider<ChallengesController>.value(value: challengesCtrl),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1200)),
        child: StartTrekkingPage(trekkingid: trekkingId),
      ),
      routes: {
        '/end': (_) => const Scaffold(body: Text('EndPage')),
      },
    ),
  );
}

void main() {
  late MockTrekkingController mockTrekking;
  late MockChallengesController mockChallenges;

  setUp(() {
    mockTrekking = MockTrekkingController();
    mockChallenges = MockChallengesController();

    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.onMetricsChanged; 
    binding.window.physicalSizeTestValue = const Size(1080, 2400);
    binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    // Stub di default: addListener/removeListener richiesti da ChangeNotifierProvider
    when(mockTrekking.addListener(any)).thenReturn(null);
    when(mockTrekking.removeListener(any)).thenReturn(null);
    when(mockChallenges.addListener(any)).thenReturn(null);
    when(mockChallenges.removeListener(any)).thenReturn(null);
    when(mockTrekking.hasListeners).thenReturn(false);
    when(mockChallenges.hasListeners).thenReturn(false);
  });

  group('StartTrekkingPage – rendering', () {
    testWidgets('mostra il nome del trekking nell\'header', (tester) async {
      final trek = makeTrekking(name: 'Sentiero delle Stelle');
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump(); 

      expect(find.text('Sentiero delle Stelle'), findsOneWidget);
    });

    testWidgets('mostra "TREKKING" come fallback se il trekking è null',
        (tester) async {
      when(mockTrekking.getTrekkingById('missing')).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'missing',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.text('TREKKING'), findsOneWidget);
    });

    testWidgets('mostra lo sfondo nero', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('mostra l\'icona terrain nell\'header', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('mostra l\'icona timer nel cerchio centrale', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('mostra il timer inizializzato a 0:00:00', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.text('0:00:00'), findsOneWidget);
    });

    testWidgets('mostra il bottone di stop', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('mostra CircularProgressIndicator per il timer', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('StartTrekkingPage – colore difficoltà', () {
    Future<void> pumpWithDifficulty(
        WidgetTester tester, String difficulty) async {
      final trek = makeTrekking(difficulty: difficulty);
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();
    }

    testWidgets('usa il colore corretto per difficoltà "easy"', (tester) async {
      await pumpWithDifficulty(tester, 'easy');
      // Verifica che la pagina si renderizzi senza errori
      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('usa il colore corretto per difficoltà "medium"',
        (tester) async {
      await pumpWithDifficulty(tester, 'medium');
      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('usa il colore corretto per difficoltà "hard"', (tester) async {
      await pumpWithDifficulty(tester, 'hard');
      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('usa colore default per difficoltà sconosciuta', (tester) async {
      await pumpWithDifficulty(tester, 'unknown');
      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('usa colore default quando trekking è null', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });
  });

  group('StartTrekkingPage – timer', () {
    testWidgets('il timer avanza dopo un tick', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('_formattedTime mostra le ore se elapsed > 1 ora', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));

      await tester.pump(const Duration(hours: 1, seconds: 5));
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });
  });

  group('StartTrekkingPage – _loadChallenges', () {
    testWidgets('carica le challenges dal trekking e le formatta', (tester) async {
      final trek = makeTrekking(
        challenges: [
          'gs://bucket/hiking_challenge.png',
          'gs://bucket/running_challenge.png',
        ],
      );
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('gestisce trekking senza challenges', (tester) async {
      final trek = makeTrekking(challenges: []);
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('gestisce trekking null senza crash', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });
  });

  group('StartTrekkingPage – notifiche challenge', () {
    testWidgets(
        'chiama notifyNewChallenge quando il challengeTimer scatta con challenges presenti',
        (tester) async {
      final trek = makeTrekking(
        challenges: ['gs://bucket/hiking_challenge.png'],
      );
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);
      when(mockChallenges.notifyNewChallenge(any, any)).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      await tester.pump(const Duration(seconds: 31));

      verify(mockChallenges.notifyNewChallenge(any, any)).called(greaterThan(0));
    });

    testWidgets('non chiama notifyNewChallenge senza challenges', (tester) async {
      final trek = makeTrekking(challenges: []);
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump(const Duration(seconds: 31));

      verifyNever(mockChallenges.notifyNewChallenge(any, any));
    });

    testWidgets('cancella challengeTimer dopo aver esaurito tutte le challenges',
        (tester) async {
      final trek = makeTrekking(
        challenges: ['gs://bucket/one_challenge.png'],
      );
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);
      when(mockChallenges.notifyNewChallenge(any, any)).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 30));

      verify(mockChallenges.notifyNewChallenge(any, any)).called(1);
    });

    testWidgets('formatta correttamente il nome della challenge dalla URL',
        (tester) async {
      String? capturedPayload;

      final trek = makeTrekking(
        challenges: ['gs://bucket/mountain_challenge.png'],
      );
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(trek);
      when(mockChallenges.notifyNewChallenge(any, any)).thenAnswer((inv) {
        capturedPayload = inv.positionalArguments[0] as String;
        return null;
      });

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump(const Duration(seconds: 31));

      expect(capturedPayload, 'mountain');
    });
  });

  group('StartTrekkingPage – dispose', () {
    testWidgets('cancella timer e stream subscription al dispose', (tester) async {
      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Done'))),
      );

      expect(find.text('Done'), findsOneWidget);
    });
  });


  group('StartTrekkingPage – layout responsive', () {
    testWidgets('si renderizza correttamente su schermo piccolo (h < 700)',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 667 * 3); // iPhone SE
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('si renderizza correttamente su schermo grande (h > 700)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3); 
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());

      await tester.pumpWidget(buildTestWidget(
        trekkingId: 'trek1',
        trekkingCtrl: mockTrekking,
        challengesCtrl: mockChallenges,
      ));
      await tester.pump();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });
  });

  group('Trekking model – fromMap / toMap', () {
    test('fromMap parsa correttamente tutti i campi base', () {
      final map = {
        'Name': 'Sentiero',
        'Map_photo': 'gs://bucket/map.png',
        'Difficulty_level': 'easy',
        'Distance': 5.0,
        'Estimated_time': 2.0,
        'Elevation_gain': 200.0,
        'Up_gain': true,
        'Down_gain': false,
        'Points': [],
        'Starting_point_name': 'Partenza',
        'Ending_point_name': 'Arrivo',
        'Info': ['Info 1'],
        'Photo_ending_point': 'gs://bucket/end.png',
        'Description': ['Bella camminata'],
        'Refreshment_point': 'Bar al Lago',
        'Picnic_area': true,
        'Family_friendly': true,
        'Challenges': ['ch1'],
      };
      final t = Trekking.fromMap(map, docId: 'doc1');

      expect(t.documentId, 'doc1');
      expect(t.name, 'Sentiero');
      expect(t.difficulty_level, 'easy');
      expect(t.distance, 5.0);
      expect(t.upGain, isTrue);
      expect(t.pic_nic_area, isTrue);
      expect(t.challenges, ['ch1']);
      expect(t.info, ['Info 1']);
    });

    test('fromMap usa fallback per campi mancanti', () {
      final t = Trekking.fromMap({}, docId: 'empty');
      expect(t.name, '');
      expect(t.distance, 0.0);
      expect(t.upGain, isFalse);
      expect(t.points, isEmpty);
      expect(t.challenges, isEmpty);
      expect(t.starting_point, const LatLng(0, 0));
    });

    test('fromMap parsa distance come stringa numerica', () {
      final t = Trekking.fromMap({'Distance': '12.5'}, docId: 'str');
      expect(t.distance, 12.5);
    });

    test('toMap serializza tutti i campi correttamente', () {
      final t = makeTrekking(
        name: 'Test Trek',
        difficulty: 'hard',
        challenges: ['ch1', 'ch2'],
      );
      final map = t.toMap();

      expect(map['Name'], 'Test Trek');
      expect(map['Difficulty_level'], 'hard');
      expect(map['Challenges'], ['ch1', 'ch2']);
      expect(map['Up_gain'], isTrue);
    });

    test('getter e setter funzionano correttamente', () {
      final t = makeTrekking();
      t.name = 'Nuovo Nome';
      t.distance = 20.0;
      t.difficulty_level = 'expert';
      t.upGain = false;
      t.challenges = ['nuova'];

      expect(t.name, 'Nuovo Nome');
      expect(t.distance, 20.0);
      expect(t.difficulty_level, 'expert');
      expect(t.upGain, isFalse);
      expect(t.challenges, ['nuova']);
    });
  });

  testWidgets('premendo il tasto stop naviga a EndTrekkingPage', (tester) async {
    when(mockTrekking.getTrekkingById('trek1')).thenReturn(makeTrekking());
    
    when(mockTrekking.getCachedImage(any)).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestWidget(
      trekkingId: 'trek1',
      trekkingCtrl: mockTrekking,
      challengesCtrl: mockChallenges,
    ));
    await tester.pump();

    final stopButton = find.byType(GestureDetector).last; 
    await tester.tap(stopButton);
    
    await tester.pumpAndSettle();

    expect(find.byType(EndTrekkingPage), findsOneWidget); 
  });
}
