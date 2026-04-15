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
import 'package:triplo/pages/DiaryPage/adding-diary-page.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:triplo/pages/trekkingPage/end_trekking_page.dart';
import 'start_trekking_page_test.mocks.dart';

void main() {
  late MockTrekkingController mockController;

  Trekking buildTrekking() {
    return Trekking(
      documentId: 'trek1',
      name: 'Test Trek',
      mapPhoto: '',
      difficultyLevel: 'easy',
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

  Widget buildWidget(Duration duration) {
    final trekking = buildTrekking();
    when(mockController.getTrekkingById('trek1')).thenReturn(trekking);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(value: mockController),
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
        home: EndTrekkingPage(
          trekkingid: 'trek1',
          elapsedTime: duration,
        ),
      ),
    );
  }

  setUp(() {
    mockController = MockTrekkingController();
    when(mockController.getCachedImage(any))
        .thenAnswer((_) async => null);
  });

  testWidgets('Mostra tempo con ore', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(hours: 1, minutes: 5, seconds: 9)));
    await tester.pumpAndSettle();

    expect(find.text('1:05:09'), findsOneWidget);
  });

  testWidgets('Mostra tempo senza ore', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 5, seconds: 9)));
    await tester.pumpAndSettle();

    expect(find.text('05:09'), findsOneWidget);
  });

  testWidgets('Mostra testi localizzati', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(EndTrekkingPage));
    final local = AppLocalizations.of(context)!;

    expect(find.text(local.trekking_completed_label.toUpperCase()), findsOneWidget);
    expect(find.text(local.add_to_diary_question_label.toUpperCase()), findsOneWidget);
    expect(find.text(local.add_to_diary_label), findsOneWidget);
    expect(find.text(local.not_now), findsOneWidget);
  });


  testWidgets('Tap su aggiungi al diario naviga', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddingDiaryPage), findsOneWidget);
  });

  testWidgets('Tap su not now triggera Navigator.push', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(find.byType(EndTrekkingPage), findsNothing);
  });

  testWidgets('Background in loading', (tester) async {
    final completer = Completer<File?>();
    when(mockController.getCachedImage('photo.png'))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pump();

    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('Background senza immagine', (tester) async {
    when(mockController.getCachedImage('photo.png'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    expect(find.byType(Stack), findsWidgets);
  });

  testWidgets('Background con immagine', (tester) async {
    final file = File('test_assets/test.png');

    when(mockController.getCachedImage('photo.png'))
        .thenAnswer((_) async => file);

    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Mostra icona completamento', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('Presenza BackdropFilter (blur)', (tester) async {
    await tester.pumpWidget(buildWidget(const Duration(minutes: 1)));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}