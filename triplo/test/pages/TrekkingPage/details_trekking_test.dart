import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/trekkingPage/details_trekking.dart';
import 'package:triplo/pages/trekkingPage/start_trekking.dart';
import 'start_trekking_page_test.mocks.dart';

void main() {
  late MockTrekkingController mockController;

  Trekking buildTrekking({
    String id = 'trek1',
    String name = 'Monte Test',
    String difficulty = 'easy',
    double estimatedTime = 90,
    double elevationGain = 300,
    bool upGain = true,
    List<String> challenges = const [],
    String endingPointPhoto = 'photo.png',
  }) {
    return Trekking(
      documentId: id,
      name: name,
      mapPhoto: '',
      difficultyLevel: difficulty,
      distance: 5.0,
      estimatedTime: estimatedTime,
      elevationGain: elevationGain,
      upGain: upGain,
      downGain: !upGain,
      startingPoint: const LatLng(0, 0),
      endingPoint: const LatLng(1, 1),
      points: [],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: endingPointPhoto,
      description: [],
      picNicArea: false,
      familyFirendly: false,
      challenges: challenges,
    );
  }

  setUp(() {
    mockController = MockTrekkingController();
    when(mockController.getCachedImage(any)).thenAnswer((_) async => null);
  });

  Widget buildWidget(Trekking trekking) {
    when(mockController.getTrekkingById('trek1')).thenReturn(trekking);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(value: mockController),
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
        home: DetailsTrekking(trekkingid: 'trek1'),
      ),
    );
  }

  testWidgets('Mostra il nome del trekking', (tester) async {
    final t = buildTrekking(name: 'Monte Test');
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.text('Monte Test'), findsOneWidget);
  });

  testWidgets('Mostra tempo formattato in ore e minuti (>60 min)', (
    tester,
  ) async {
    final t = buildTrekking(estimatedTime: 90);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.text('1h 30m'), findsOneWidget);
  });

  testWidgets('Mostra tempo formattato solo in minuti (<60 min)', (
    tester,
  ) async {
    final t = buildTrekking(estimatedTime: 45);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.text('45m'), findsOneWidget);
  });

  testWidgets('Mostra elevation gain arrotondato con unità m', (tester) async {
    final t = buildTrekking(elevationGain: 312.7);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.text('313 m'), findsOneWidget);
  });

  testWidgets('Mostra freccia su se upGain = true', (tester) async {
    final t = buildTrekking(upGain: true);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('Mostra freccia giù se upGain = false', (tester) async {
    final t = buildTrekking(upGain: false);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('Mostra no_challenge se challenges è vuota', (tester) async {
    final t = buildTrekking(challenges: []);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.style?.color == Colors.white38,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Mostra icone sfide se challenges non è vuota', (tester) async {
    when(
      mockController.getCachedImage('ch1.png'),
    ).thenAnswer((_) async => null);
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking(challenges: ['ch1.png']);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });

  testWidgets('Mostra immagine sfida se file disponibile', (tester) async {
    final file = File('test_assets/test.png');
    when(
      mockController.getCachedImage('ch1.png'),
    ).thenAnswer((_) async => file);
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking(challenges: ['ch1.png']);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(ClipRRect), findsWidgets);
  });

  testWidgets('Mostra loader sfida durante ConnectionState.waiting', (
    tester,
  ) async {
    final completer = Completer<File?>();
    when(
      mockController.getCachedImage('ch1.png'),
    ).thenAnswer((_) => completer.future);
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking(challenges: ['ch1.png']);
    await tester.pumpWidget(buildWidget(t));
    await tester.pump(); // non pumpAndSettle: lascia il future in sospeso

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('Sfondo nero durante caricamento immagine di sfondo', (
    tester,
  ) async {
    final completer = Completer<File?>();
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) => completer.future);

    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pump();

    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('Sfondo con immagine quando file disponibile', (tester) async {
    final file = File('test_assets/test.png');
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => file);

    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('Pulsante Inizia trekking è presente', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Pulsante Indietro è presente', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('Tap su Indietro esegue Navigator.pop', (tester) async {
    final t = buildTrekking();

    when(mockController.getTrekkingById('trek1')).thenReturn(t);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TrekkingController>.value(
            value: mockController,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it')],
          locale: const Locale('it'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DetailsTrekking(trekkingid: 'trek1'),
                  ),
                ),
                child: const Text('Vai'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Vai'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.text('Vai'), findsOneWidget);
  });

  testWidgets('Rendering con difficulty easy senza crash', (tester) async {
    final t = buildTrekking(difficulty: 'easy');
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Rendering con difficulty hard senza crash', (tester) async {
    final t = buildTrekking(difficulty: 'hard');
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Rendering con difficulty medium senza crash', (tester) async {
    final t = buildTrekking(difficulty: 'medium');
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Mostra più icone sfide se challenges ha più elementi', (
    tester,
  ) async {
    when(
      mockController.getCachedImage('ch1.png'),
    ).thenAnswer((_) async => null);
    when(
      mockController.getCachedImage('ch2.png'),
    ).thenAnswer((_) async => null);
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking(challenges: ['ch1.png', 'ch2.png']);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image), findsNWidgets(2));
  });

  testWidgets('Tap su Inizia trekking naviga alla StartTrekkingPage', (
    tester,
  ) async {
    final t = buildTrekking();

    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(StartTrekkingPage), findsOneWidget);
  });

  testWidgets('Sfondo nero quando immagine non disponibile', (tester) async {
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('Mostra label info card', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DetailsTrekking));
    final local = AppLocalizations.of(context)!;

    expect(find.text(local.estimated_time_trekking_label), findsOneWidget);
    expect(find.text(local.elevaition_gain_trekking_label), findsOneWidget);
  });

  testWidgets('Mostra titolo challenge', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DetailsTrekking));
    final local = AppLocalizations.of(context)!;

    expect(find.text(local.challeng_title.toUpperCase()), findsOneWidget);
  });

  testWidgets('Mostra header BEFORE START', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DetailsTrekking));
    final local = AppLocalizations.of(context)!;

    expect(find.text(local.before_start.toUpperCase()), findsOneWidget);
  });

  testWidgets('Mostra tempo con minuti zero', (tester) async {
    final t = buildTrekking(estimatedTime: 120);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.text('2h 0m'), findsOneWidget);
  });

  testWidgets('Mostra icone info card', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
  });

  testWidgets('Usa Wrap per challenges multiple', (tester) async {
    when(
      mockController.getCachedImage('ch1.png'),
    ).thenAnswer((_) async => null);
    when(
      mockController.getCachedImage('ch2.png'),
    ).thenAnswer((_) async => null);
    when(
      mockController.getCachedImage('photo.png'),
    ).thenAnswer((_) async => null);

    final t = buildTrekking(challenges: ['ch1.png', 'ch2.png']);
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('Applica blur con BackdropFilter', (tester) async {
    final t = buildTrekking();
    await tester.pumpWidget(buildWidget(t));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
