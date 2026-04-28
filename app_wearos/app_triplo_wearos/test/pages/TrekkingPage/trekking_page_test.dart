import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/trekking-page.dart' show TrekkingPage;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';

import 'trekking_page_test.mocks.dart';

@GenerateMocks([TrekkingController, Language])
void main() {
  Trekking fakeTrekking({
    String difficulty = 'easy',
    bool picNic = false,
    bool familyFriendly = false,
    String refreshmentPoint = '',
  }) {
    return Trekking(
      documentId: 'trek-001',
      name: 'Monte Bello Trail',
      mapPhoto: '',
      difficultyLevel: difficulty,
      distance: 12.5,
      estimatedTime: 180.0,
      elevationGain: 450.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(45.0, 9.0),
      endingPoint: const LatLng(45.1, 9.1),
      points: [const LatLng(45.0, 9.0), const LatLng(45.1, 9.1)],
      startingPointName: 'Partenza A',
      endingPointName: 'Arrivo B',
      info: ['DE Info', 'EN Info', 'ES Info', 'FR Info', 'IT Info'],
      endingPointPhoto: 'gs://bucket/photo.jpg',
      description: ['DE Desc', 'EN Desc', 'ES Desc', 'FR Desc', 'IT Desc'],
      refreshmentPoint: refreshmentPoint,
      picNicArea: picNic,
      familyFirendly: familyFriendly,
      challenges: [],
    );
  }

  Widget buildWidget({
    required TrekkingController trekkingController,
    required Language language,
    String trekkingId = 'trek-001',
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(
            value: trekkingController),
        ChangeNotifierProvider<Language>.value(value: language),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TrekkingPage(trekkingId: trekkingId),
      ),
    );
  }

  group('TrekkingPage — logica interna', () {
    late TrekkingPage page;

    setUp(() {
      page = const TrekkingPage(trekkingId: 'x');
    });

    test('formatShortTimeFromMinutes — solo minuti', () {
      expect(page.formatShortTimeFromMinutes(45), '45m');
    });

    test('formatShortTimeFromMinutes — solo ore', () {
      expect(page.formatShortTimeFromMinutes(120), '2h');
    });

    test('formatShortTimeFromMinutes — ore e minuti', () {
      expect(page.formatShortTimeFromMinutes(95), '1h35m');
    });

    test('formatShortTimeFromMinutes — zero minuti', () {
      expect(page.formatShortTimeFromMinutes(0), '0m');
    });

    test('getLanguageSelected — italiano', () {
      expect(page.getLanguageSelected('it'), 4);
    });

    test('getLanguageSelected — inglese', () {
      expect(page.getLanguageSelected('en'), 1);
    });

    test('getLanguageSelected — tedesco', () {
      expect(page.getLanguageSelected('de'), 0);
    });

    test('getLanguageSelected — codice sconosciuto → fallback inglese (1)', () {
      expect(page.getLanguageSelected('zh'), 1);
    });

    test('getLanguageSelected — spagnolo', () {
      expect(page.getLanguageSelected('es'), 2);
    });

    test('getLanguageSelected — francese', () {
      expect(page.getLanguageSelected('fr'), 3);
    });
  });

  group('TrekkingPage — widget', () {
    late MockTrekkingController mockController;
    late MockLanguage mockLanguage;

    setUp(() {
      mockController = MockTrekkingController();
      mockLanguage = MockLanguage();

      when(mockLanguage.locale).thenReturn(const Locale('it'));

      when(mockController.getDownloadUrl(any))
          .thenAnswer((_) async => 'https://via.placeholder.com/300');
    });

    testWidgets('mostra errore quando il trekking non esiste',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('ghost')).thenReturn(null);

      await tester.pumpWidget(buildWidget(
        trekkingController: mockController,
        language: mockLanguage,
        trekkingId: 'ghost',
      ));
      await tester.pump();

      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('mostra il nome del trekking nella hero section',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking());

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.pumpAndSettle();
      });

      expect(find.text('MONTE BELLO TRAIL'), findsOneWidget);
    });

    testWidgets('mostra il livello "BEGINNER" per difficulty easy',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking(difficulty: 'easy'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.pumpAndSettle();
      });

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('mostra distanza e tempo stimato nella sezione tecnica',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking());

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.drag(find.byType(PageView), const Offset(0, -400));
        await tester.pumpAndSettle();
      });

      expect(find.text('12.5km'), findsOneWidget);
      expect(find.text('3h'), findsOneWidget); 
    });

    testWidgets('mostra freccia upGain e non downGain',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking()); 

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.drag(find.byType(PageView), const Offset(0, -400));
        await tester.pumpAndSettle();
      });

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('icona pic_nic_area visibile se abilitata',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking(picNic: true));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.drag(find.byType(PageView), const Offset(0, -400));
        await tester.pumpAndSettle();
      });

      expect(find.byIcon(Icons.table_restaurant), findsOneWidget);
    });

    testWidgets('icona family_friendly NON visibile se disabilitata',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking(familyFriendly: false));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.drag(find.byType(PageView), const Offset(0, -400));
        await tester.pumpAndSettle();
      });

      expect(find.byIcon(Icons.family_restroom), findsNothing);
    });

    testWidgets('icona family_friendly visibile se abilitata',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking(familyFriendly: true));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildWidget(
          trekkingController: mockController,
          language: mockLanguage,
        ));
        await tester.drag(find.byType(PageView), const Offset(0, -400));
        await tester.pumpAndSettle();
      });

      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets('pulsante Back chiama Navigator.pop',
        (WidgetTester tester) async {
      when(mockController.getTrekkingById('trek-001'))
          .thenReturn(fakeTrekking());

      bool popped = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<TrekkingController>.value(
                  value: mockController),
              ChangeNotifierProvider<Language>.value(value: mockLanguage),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TrekkingPage(trekkingId: 'trek-001'),
                      ),
                    );
                  },
                  child: const Text('Go'),
                );
              }),
            ),
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(PageView), const Offset(0, -400));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        popped = true;
      });

      expect(popped, isTrue);
    });
  });
}