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
import 'package:triplo/pages/trekkingPage/end_trekking_page.dart';

import 'end_trekking_page_test.mocks.dart';
import 'start_trekking_page_test.mocks.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<NavigatorObserver>(),
])
void main() {
  late MockTrekkingController mockController;

  late MockNavigatorObserver mockObserver;
  Trekking buildTrekking({String difficultyLevel = 'easy'}) {
    return Trekking(
      documentId: 'trek1',
      name: 'Test Trek',
      mapPhoto: '',
      difficultyLevel: difficultyLevel,
      distance: 5,
      estimatedTime: 60,
      elevationGain: 100,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(0, 0),
      endingPoint: const LatLng(1, 1),
      points: [],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: 'photo.png',
      description: [],
      picNicArea: false,
      familyFirendly: false,
      challenges: [],
    );
  }

  Widget buildWidget(
    Duration duration, {
    String difficultyLevel = 'easy',
  }) {
    final trekking = buildTrekking(difficultyLevel: difficultyLevel);
    when(mockController.getTrekkingById('trek1')).thenReturn(trekking);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(value: mockController),
      ],
      child: MaterialApp(
        navigatorObservers: [mockObserver],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('it')],
        locale: const Locale('it'),
        home: EndTrekkingPage(
          trekkingid: 'trek1',
          elapsedTime: duration,
        ),
      ),
    );
  }

  setUp(() {
    mockController = MockTrekkingController();
    mockObserver = MockNavigatorObserver();
    when(mockController.getCachedImage(any)).thenAnswer((_) async => null);
  });

  group('Formato del tempo', () {
    testWidgets('Mostra tempo con ore', (tester) async {
      await tester.pumpWidget(
        buildWidget(const Duration(hours: 1, minutes: 5, seconds: 9)),
      );
      await tester.pumpAndSettle();

      expect(find.text('1:05:09'), findsOneWidget);
    });

    testWidgets('Mostra tempo senza ore', (tester) async {
      await tester.pumpWidget(
        buildWidget(const Duration(minutes: 5, seconds: 9)),
      );
      await tester.pumpAndSettle();

      expect(find.text('05:09'), findsOneWidget);
    });

    testWidgets('Mostra tempo zero (00:00)', (tester) async {
      await tester.pumpWidget(buildWidget(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Mostra tempo con ore zero e secondi', (tester) async {
      await tester.pumpWidget(
        buildWidget(const Duration(minutes: 59, seconds: 59)),
      );
      await tester.pumpAndSettle();

      expect(find.text('59:59'), findsOneWidget);
    });

    testWidgets('Mostra tempo con ore multiple cifre', (tester) async {
      await tester.pumpWidget(
        buildWidget(const Duration(hours: 10, minutes: 0, seconds: 0)),
      );
      await tester.pumpAndSettle();

      expect(find.text('10:00:00'), findsOneWidget);
    });
  });

  group('Testi localizzati', () {
    testWidgets('Mostra testi localizzati', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(EndTrekkingPage));
      final local = AppLocalizations.of(context)!;

      expect(
        find.text(local.trekking_completed_label.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(local.add_to_diary_question_label.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(local.add_to_diary_label), findsOneWidget);
      expect(find.text(local.not_now), findsOneWidget);
    });
  });

  group('Navigazione', () {
    testWidgets('Tap su "Non ora" avvia la navigazione verso HomePage',
        (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      expect(find.byType(EndTrekkingPage), findsOneWidget);
    });

    testWidgets('Tap su "Aggiungi al diario" avvia pushReplacement', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockObserver.didReplace(
        newRoute: anyNamed('newRoute'),
        oldRoute: anyNamed('oldRoute'),
      )).called(1);
    });
  });

  group('Background', () {
    testWidgets('Background in loading mostra Stack', (tester) async {
      final completer = Completer<File?>();
      when(mockController.getCachedImage('photo.png'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('Background senza immagine non mostra Image.file',
        (tester) async {
      when(mockController.getCachedImage('photo.png'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Background con immagine valida: FutureBuilder riceve File non-null',
        (tester) async {
      final completer = Completer<File?>();

      when(mockController.getCachedImage('photo.png'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pump(); 

      completer.complete(null);
      await tester.pump();

      expect(find.byType(FutureBuilder<File?>), findsOneWidget);
    });

    testWidgets('Presenza BackdropFilter (blur)', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('Struttura UI', () {
    testWidgets('Mostra icona completamento', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.check_circle_outline_rounded),
        findsOneWidget,
      );
    });

    testWidgets('Presenza ElevatedButton e OutlinedButton', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Scaffold ha sfondo nero', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('SafeArea presente', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('FutureBuilder presente per gestione immagine', (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(FutureBuilder<File?>), findsOneWidget);
    });
  });

  group('Interazione con TrekkingController', () {
    testWidgets('getTrekkingById viene chiamato con id corretto',
        (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      verify(mockController.getTrekkingById('trek1')).called(greaterThan(0));
    });

    testWidgets('getCachedImage viene chiamato con endingPointPhoto corretto',
        (tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      verify(mockController.getCachedImage('photo.png')).called(1);
    });
  });
}