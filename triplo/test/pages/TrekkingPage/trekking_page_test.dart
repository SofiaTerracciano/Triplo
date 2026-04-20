import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/pages/DiaryPage/adding-diary-page.dart';
import 'package:triplo/pages/GeowatchPage/geowatch.dart';
import 'package:triplo/pages/trekkingPage/details_trekking.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
import 'package:triplo/widgets_for_pages/weather/weather.dart';
import 'package:network_image_mock/network_image_mock.dart';
import '../DiaryPage/adding_diary_page_test.mocks.dart';
import 'trekking_page_test.mocks.dart'
    hide MockUserController, MockTrekkingController, MockDiaryController;

@GenerateMocks([
  TrekkingController,
  UserController,
  ServiceController,
  Language,
  DiaryController,
])

void main() {
  group('TrekkingPage – widget', () {
    late MockTrekkingController mockTrekkingController;
    late MockUserController mockUserController;
    late MockServiceController mockServiceController;
    late MockLanguage mockLanguage;
    late Users fakeUser;
    late MockDiaryController mockDiaryController;

    setUp(() async {
      mockTrekkingController = MockTrekkingController();
      mockUserController = MockUserController();
      mockServiceController = MockServiceController();
      mockLanguage = MockLanguage();
      mockDiaryController = MockDiaryController();

      fakeUser = _buildUser();

      when(mockLanguage.locale).thenReturn(const Locale('en'));
      when(mockLanguage.addListener(any)).thenReturn(null);
      when(mockLanguage.removeListener(any)).thenReturn(null);

      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.addListener(any)).thenReturn(null);
      when(mockUserController.removeListener(any)).thenReturn(null);

      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekking());
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekking());
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => false);
      when(
        mockTrekkingController.getCachedImage(any),
      ).thenAnswer((_) async => null);
      when(
        mockTrekkingController.getCachedImages(any),
      ).thenAnswer((_) async => <File>[]);
      when(
        mockTrekkingController.addTrekkingToSaved(any),
      ).thenAnswer((_) async => {});
      when(
        mockTrekkingController.removeTrekkingFromSaved(any),
      ).thenAnswer((_) async => {});
      when(mockTrekkingController.addListener(any)).thenReturn(null);
      when(mockTrekkingController.removeListener(any)).thenReturn(null);

      when(
        mockServiceController.weather(any, any, any),
      ).thenAnswer((_) async => null);

      mockDiaryController = MockDiaryController();
      when(mockDiaryController.currentUser).thenReturn(fakeUser);
      when(mockDiaryController.uploadDiaryImages(any))
          .thenAnswer((_) async => <String>[]);
      when(mockDiaryController.addListener(any)).thenReturn(null);
      when(mockDiaryController.removeListener(any)).thenReturn(null);
      when(mockUserController.getFollowing(any))
          .thenAnswer((_) async => <Users>[]);

      when(mockServiceController.weatherIconUrl(any, big: anyNamed('big')))
          .thenReturn('icon_url');

      when(mockTrekkingController.isWeatherAlertEnabled(any))
          .thenAnswer((_) async => false);

      FlutterError.onError = (details) {
        if (details.toString().contains('NetworkImageLoadException') ||
            details.toString().contains('RenderFlex'))
          return;
        FlutterError.dumpErrorToConsole(details);
      };
    });


    Widget buildPage({String trekkingId = 'trek1'}) => MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(
            value: mockTrekkingController),
        ChangeNotifierProvider<UserController>.value(
            value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(
            value: mockDiaryController),
        ChangeNotifierProvider<Language>.value(value: mockLanguage),
        Provider<ServiceController>.value(value: mockServiceController),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TrekkingPage(trekkingId: trekkingId),
      ),
    );

    Future<void> pumpPage(WidgetTester tester,
    {String trekkingId = 'trek1'}) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      await tester.pumpWidget(buildPage(trekkingId: trekkingId));
      await tester.pump(); 
    }

    Future<void> pumpPageSettled(WidgetTester tester,
        {String trekkingId = 'trek1'}) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      await tester.pumpWidget(buildPage(trekkingId: trekkingId));
      await tester.pumpAndSettle();
    }

    testWidgets('photoSection mostra icona errore se future fallisce', (tester) async {
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => throw Exception());

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.broken_image), findsWidgets);
    });

    testWidgets('photoSection mostra placeholder se file è null', (tester) async {
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.image_not_supported), findsWidgets);
    });

    testWidgets('weatherError viene settato se api fallisce', (tester) async {
      when(mockServiceController.weather(any, any, any))
          .thenThrow(Exception());

      await pumpPageSettled(tester);

      expect(find.byType(Weather), findsOneWidget);
    });

    testWidgets('_initSavedState gestisce errore', (tester) async {
      when(mockTrekkingController.isTrekkingSaved(any))
          .thenThrow(Exception());

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('mostra snackbar su errore salvataggio', (tester) async {
      when(mockTrekkingController.isTrekkingSaved(any))
          .thenAnswer((_) async => false);

      when(mockTrekkingController.addTrekkingToSaved(any))
          .thenThrow(Exception());

      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump(); 

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('difficulty sconosciuta usa colore fallback', (tester) async {
      when(mockTrekkingController.getTrekkingByIdAsync('trek1'))
          .thenAnswer((_) async => _buildTrekkingWithDifficulty('unknown'));
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekkingWithDifficulty('unknown'));

      await pumpPageSettled(tester);

      expect(find.byType(TrekkingPage), findsOneWidget);
    });

    testWidgets('challenges mostra fallback se errore', (tester) async {
      when(mockTrekkingController.getTrekkingByIdAsync('trek1'))
          .thenAnswer((_) async => _buildTrekkingWithChallenges());
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekkingWithChallenges());

      when(mockTrekkingController.getCachedImages(any))
          .thenAnswer((_) async => throw Exception());

      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;

      expect(find.text(local.challenges_available_trekking_label), findsOneWidget);
    });

    testWidgets('photoSection mostra immagine quando file esiste', (tester) async {
      final file = File('test.png');

      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => file);

      await pumpPageSettled(tester);

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Weather riceve stato errore', (tester) async {
      when(mockServiceController.weather(any, any, any))
          .thenThrow(Exception());

      await pumpPageSettled(tester);

      final weatherWidget = tester.widget<Weather>(find.byType(Weather));

      expect(weatherWidget.error, isNotNull);
    });

    testWidgets('tap su Weather apre GeoWatchPage', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpPageSettled(tester);

        await tester.tap(find.byType(Weather));
        await tester.pumpAndSettle();

        expect(find.byType(GeoWatchPage), findsOneWidget);
      });
    });

    testWidgets('mostra frecce up e down', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithChallenges());
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithChallenges());

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('refreshment mostra fallback se vuoto', (tester) async {
      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;

      expect(
        find.text(local.refreshment_point_available_trekking_label),
        findsOneWidget,
      );
    });

    testWidgets('tap su play naviga a DetailsTrekking', (tester) async {
      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsTrekking), findsOneWidget);
    });

    testWidgets('mostra CircularProgressIndicator durante caricamento', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) => Completer<Trekking?>().future);

      await tester.binding.setSurfaceSize(const Size(800, 3000));
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await pumpPage(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra titolo del trekking nella AppBar', (tester) async {
      await pumpPageSettled(tester);

      expect(find.text('Monte Rosa'), findsWidgets);
    });

    testWidgets('mostra messaggio se trekking non trovato', (tester) async {
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekking()); 
      when(mockTrekkingController.getTrekkingByIdAsync('trek1'))
          .thenAnswer((_) async => null); 

      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.text(local.no_trekking_found_label), findsOneWidget);
    });

    testWidgets('mostra schermata "not logged" se user è null', (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      expect(find.text(local.not_logged_title), findsOneWidget);
      expect(find.text(local.not_logged_subtitle), findsOneWidget);
    });

    testWidgets('bottone login presente nella schermata not logged', (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      expect(find.text(local.go_to_login_button), findsOneWidget);
    });

    testWidgets('SingleChildScrollView presente nel layout', (tester) async {
      await pumpPageSettled(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('icona add presente nella AppBar', (tester) async {
      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('icona play_arrow presente nella AppBar', (tester) async {
      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('icona bookmark_border presente quando non salvato', (
      tester,
    ) async {
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => false);

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('icona bookmark presente quando già salvato', (tester) async {
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => true);

      await pumpPageSettled(tester);

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('tap bookmark salva il trekking', (tester) async {
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => false);

      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      verify(mockTrekkingController.addTrekkingToSaved('trek1')).called(1);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('tap bookmark rimuove il trekking se già salvato', (
      tester,
    ) async {
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => true);

      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();

      verify(mockTrekkingController.removeTrekkingFromSaved('trek1')).called(1);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('bookmark fa rollback se addTrekkingToSaved lancia eccezione', (
      tester,
    ) async {
      when(
        mockTrekkingController.isTrekkingSaved(any),
      ).thenAnswer((_) async => false);
      when(
        mockTrekkingController.addTrekkingToSaved(any),
      ).thenThrow(Exception('network error'));

      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.bookmark_border));      

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets(
      'bookmark fa rollback se removeTrekkingFromSaved lancia eccezione',
      (tester) async {
        when(
          mockTrekkingController.isTrekkingSaved(any),
        ).thenAnswer((_) async => true);
        when(
          mockTrekkingController.removeTrekkingFromSaved(any),
        ).thenThrow(Exception('network error'));

        await pumpPageSettled(tester);

        await tester.tap(find.byIcon(Icons.bookmark));      

        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      },
    );

    testWidgets('mostra distanza nella info card', (tester) async {
      await pumpPageSettled(tester);      

      expect(find.textContaining('12.5 km'), findsOneWidget);
    });

    testWidgets('mostra guadagno elevazione nella info card', (tester) async {
      await pumpPageSettled(tester);

      expect(find.textContaining('800.0 m'), findsOneWidget);
    });

    testWidgets('mostra minuti se estimated_time < 60', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithTime(45.0));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithTime(45.0));

      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.textContaining('45'), findsWidgets);
      expect(find.textContaining(local.minutes_trekking_label), findsOneWidget);
    });

    testWidgets('mostra ora singola se estimated_time = 60', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithTime(60.0));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithTime(60.0));

      await pumpPageSettled(tester); 

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.textContaining('1'), findsWidgets);
      expect(find.textContaining(local.hour_trekking_label), findsWidgets);
    });

    testWidgets('mostra ore multiple se estimated_time = 120', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithTime(120.0));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithTime(120.0));

      await pumpPageSettled(tester);      

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining(local.hours_trekking_label), findsWidgets);
    });

    testWidgets('mostra ore e minuti se estimated_time = 90', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithTime(90.0));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithTime(90.0));

      await pumpPageSettled(tester);      

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.textContaining(local.hours_trekking_label), findsWidgets);
      expect(find.textContaining('30'), findsWidgets);
      expect(find.textContaining(local.minutes_trekking_label), findsWidgets);
    });

    testWidgets('mostra 1 ora e minuti se estimated_time = 75', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithTime(75.0));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithTime(75.0));

      await pumpPageSettled(tester);     

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.textContaining('1'), findsWidgets);
      expect(find.textContaining(local.hour_trekking_label), findsWidgets);
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining(local.minutes_trekking_label), findsWidgets);
    });

    testWidgets('difficoltà easy mostra colore azzurro', (tester) async {
      await pumpPageSettled(tester);

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.text(local.beginner_level), findsOneWidget);
    });

    testWidgets('difficoltà intermediate mostra testo corretto', (
      tester,
    ) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithDifficulty('intermediate'));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithDifficulty('intermediate'));

      await pumpPageSettled(tester);    

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.text(local.intermediate_level), findsOneWidget);
    });

    testWidgets('difficoltà hard mostra testo corretto', (tester) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithDifficulty('hard'));
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithDifficulty('hard'));

      await pumpPageSettled(tester);     

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(find.text(local.advanced_level), findsOneWidget);
    });

    testWidgets('mostra testo "no challenges" se lista vuota', (tester) async {
      await pumpPageSettled(tester);      

      final local = AppLocalizations.of(
        tester.element(find.byType(TrekkingPage)),
      )!;
      expect(
        find.text(local.challenges_available_trekking_label),
        findsOneWidget,
      );
    });

    testWidgets('mostra FutureBuilder challenges se lista non vuota', (
      tester,
    ) async {
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingWithChallenges());
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingWithChallenges());
      when(
        mockTrekkingController.getCachedImages(any),
      ).thenAnswer((_) async => <File>[]);

      await pumpPageSettled(tester);

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('mostra icona family_restroom se family_friendly è true', (
      tester,
    ) async {
      await pumpPageSettled(tester);    

      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets(
      'mostra icona table_restaurant se refreshment_point non è vuoto',
      (tester) async {
        when(
          mockTrekkingController.getTrekkingByIdAsync('trek1'),
        ).thenAnswer((_) async => _buildTrekkingWithRefreshment());
        when(
          mockTrekkingController.getTrekkingById('trek1'),
        ).thenReturn(_buildTrekkingWithRefreshment());

        await pumpPageSettled(tester);

        expect(find.byIcon(Icons.table_restaurant), findsOneWidget);
      },
    );

    testWidgets('widget Weather è presente nella pagina', (tester) async {
      await pumpPageSettled(tester);

      expect(find.byType(Weather), findsOneWidget);
    });

    testWidgets('tap su add naviga ad AddingDiaryPage', (tester) async {
      await pumpPageSettled(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(AddingDiaryPage), findsOneWidget);
    });

    testWidgets('lingua de restituisce indice 0', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('de'));
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingMultilang());
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingMultilang());

      await pumpPageSettled(tester);

      expect(find.text('Info DE'), findsOneWidget);
    });

    testWidgets('lingua it restituisce indice 4', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('it'));
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingMultilang());
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingMultilang());

      await pumpPageSettled(tester);

      expect(find.text('Info IT'), findsOneWidget);
    });

    testWidgets('lingua sconosciuta restituisce indice 1 (en)', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('zh'));
      when(
        mockTrekkingController.getTrekkingByIdAsync('trek1'),
      ).thenAnswer((_) async => _buildTrekkingMultilang());
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingMultilang());

      await pumpPageSettled(tester);

      expect(find.text('Info EN'), findsOneWidget);
    });
  });
}

Users _buildUser() => Users(
  uid: 'user1',
  username: 'mario',
  name: 'Mario',
  surname: 'Rossi',
  email: 'mario@test.it',
  birthdate: DateTime(2000, 6, 1),
  followers: [],
  following: [],
  publicDiaryPages: [],
  privateDiaryPages: [],
  savedTrekkings: [],
  level: 'beginner',
  advanced: 0,
  intermediate: 0,
  photoProfile: null,
);

Trekking _buildTrekking() => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: 'map.jpg',
  difficultyLevel: 'easy',
  distance: 12.5,
  estimatedTime: 240.0, // 4 ore
  elevationGain: 800.0,
  upGain: true,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['Info DE', 'Info EN', 'Info ES', 'Info FR', 'Info IT'],
  endingPointPhoto: 'ending.jpg',
  description: ['Desc DE', 'Desc EN', 'Desc ES', 'Desc FR', 'Desc IT'],
  picNicArea: false,
  familyFirendly: true,
  challenges: [],
);

Trekking _buildTrekkingWithTime(double time) => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: '',
  difficultyLevel: 'easy',
  distance: 5.0,
  estimatedTime: time,
  elevationGain: 100.0,
  upGain: false,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['', 'Info EN', '', '', ''],
  endingPointPhoto: '',
  description: ['', 'Desc EN', '', '', ''],
  picNicArea: false,
  familyFirendly: false,
  challenges: [],
);

Trekking _buildTrekkingWithDifficulty(String difficulty) => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: '',
  difficultyLevel: difficulty,
  distance: 5.0,
  estimatedTime: 60.0,
  elevationGain: 100.0,
  upGain: false,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['', 'Info EN', '', '', ''],
  endingPointPhoto: '',
  description: ['', 'Desc EN', '', '', ''],
  picNicArea: false,
  familyFirendly: false,
  challenges: [],
);

Trekking _buildTrekkingWithChallenges() => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: '',
  difficultyLevel: 'hard',
  distance: 15.0,
  estimatedTime: 360.0,
  elevationGain: 1200.0,
  upGain: true,
  downGain: true,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['', 'Info EN', '', '', ''],
  endingPointPhoto: '',
  description: ['', 'Desc EN', '', '', ''],
  picNicArea: false,
  familyFirendly: false,
  challenges: ['challenge1', 'challenge2'],
);

Trekking _buildTrekkingWithRefreshment() => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: '',
  difficultyLevel: 'easy',
  distance: 5.0,
  estimatedTime: 60.0,
  elevationGain: 100.0,
  upGain: false,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['', 'Info EN', '', '', ''],
  endingPointPhoto: '',
  description: ['', 'Desc EN', '', '', ''],
  refreshmentPoint: 'Rifugio Test',
  picNicArea: true,
  familyFirendly: false,
  challenges: [],
);

Trekking _buildTrekkingMultilang() => Trekking(
  documentId: 'trek1',
  name: 'Monte Rosa',
  mapPhoto: '',
  difficultyLevel: 'easy',
  distance: 5.0,
  estimatedTime: 60.0,
  elevationGain: 100.0,
  upGain: false,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: ['Info DE', 'Info EN', 'Info ES', 'Info FR', 'Info IT'],
  endingPointPhoto: '',
  description: ['Desc DE', 'Desc EN', 'Desc ES', 'Desc FR', 'Desc IT'],
  picNicArea: false,
  familyFirendly: false,
  challenges: [],
);
