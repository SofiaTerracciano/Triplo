import 'dart:async';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/GeowatchPage/geowatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'geowatchpage_test.mocks.dart'
    show MockTrekkingController, MockServiceController, MockLanguage;

@GenerateMocks([TrekkingController, Language])
@GenerateNiceMocks([MockSpec<ServiceController>()])

void main() {
  late MockTrekkingController mockTrekkingController;
  late MockServiceController mockServiceController;
  late MockLanguage mockLanguage;

  final fakeLatLng = const LatLng(45.0, 9.0);

  Trekking makeTrekking({
    String id = 'trek-1',
    String name = 'Monte Rosa',
    String difficulty = 'hard',
    LatLng? startingPoint,
    LatLng? endingPoint,
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
        startingPoint: startingPoint ?? fakeLatLng,
        endingPoint: endingPoint ?? fakeLatLng,
        points: [],
        startingPointName: 'Partenza',
        endingPointName: 'Arrivo',
        info: [],
        endingPointPhoto: '',
        description: [],
        picNicArea: false,
        familyFirendly: false,
      );

  final fakeWeather = {
    'main': {'temp': 18.7},
    'weather': [
      {'description': 'cielo sereno', 'icon': '01d'}
    ],
  };

  final fakeForecastRaw = <Map<String, dynamic>>[
    {
      'dt_txt': '2026-04-28 12:00:00',
      'main': {'temp': 15.0},
      'weather': [{'icon': '02d'}]
    },
    {
      'dt_txt': '2026-04-29 12:00:00',
      'main': {'temp': 12.0},
      'weather': [{'icon': '10d'}]
    },
  ];

  final fakeForecastParsed = <Map<String, dynamic>>[
    {'date': DateTime(2026, 4, 28), 'temp': 15, 'icon': '02d'},
    {'date': DateTime(2026, 4, 29), 'temp': 12, 'icon': '10d'},
  ];

  Widget buildWidget(String trekkingId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(
            value: mockTrekkingController),
        Provider<ServiceController>.value(value: mockServiceController),
        ChangeNotifierProvider<Language>.value(value: mockLanguage),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GeowatchPage(trekkingId: trekkingId),
      ),
    );
  }

  /// Naviga il PageView fino alla pagina degli alerts (pagina 3).
  Future<void> goToAlertsPage(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockTrekkingController = MockTrekkingController();
    mockServiceController = MockServiceController();
    mockLanguage = MockLanguage();

    when(mockLanguage.locale).thenReturn(const Locale('it'));
    when(mockServiceController.weatherIconUrl(any))
        .thenReturn('https://openweathermap.org/img/wn/01d@2x.png');
    when(mockServiceController.parseForecast(any))
        .thenReturn(fakeForecastParsed);
    when(mockServiceController.weatherbitAlerts(any, any))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(mockServiceController.mockAlerts())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  group('GeowatchPage – trekking non trovato', () {
    testWidgets('mostra "Error" se getTrekkingById restituisce null',
        (tester) async {
      when(mockTrekkingController.getTrekkingById('unknown')).thenReturn(null);

      await tester.pumpWidget(buildWidget('unknown'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
    });
  });

  group('GeowatchPage – caricamento', () {
    testWidgets('mostra CircularProgressIndicator durante il fetch',
        (tester) async {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());

      final completer = Completer<Map<String, dynamic>?>();
      when(mockServiceController.weather(any, any, any))
          .thenAnswer((_) => completer.future);
      when(mockServiceController.forecast(any, any, any)).thenAnswer(
          (_) => completer.future.then((_) => <Map<String, dynamic>>[]));

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('mostra il messaggio di errore se weather lancia eccezione',
        (tester) async {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());
      when(mockServiceController.weather(any, any, any))
          .thenThrow(Exception('network error'));
      when(mockServiceController.forecast(any, any, any))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsOneWidget);
    });

    testWidgets('mostra "No weather data" se weather restituisce null',
        (tester) async {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());
      when(mockServiceController.weather(45.0, 9.0, 'it'))
          .thenAnswer((_) async => null);
      when(mockServiceController.forecast(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeForecastRaw);

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.text('No weather data'), findsOneWidget);
    });
  });

  group('GeowatchPage – meteo corrente', () {
    setUp(() {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());
      when(mockServiceController.weather(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeWeather);
      when(mockServiceController.forecast(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeForecastRaw);
    });

    testWidgets('mostra il nome del trekking in maiuscolo', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.text('MONTE ROSA'), findsOneWidget);
    });

    testWidgets('mostra la temperatura arrotondata (18.7 -> 19)',
        (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.text('19°'), findsOneWidget);
    });

    testWidgets('mostra la descrizione meteo', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.text('cielo sereno'), findsOneWidget);
    });

    testWidgets('mostra il PageView con 3 pagine', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('weather senza campo icon non crasha il render', (tester) async {
      when(mockServiceController.weather(45.0, 9.0, 'it')).thenAnswer(
        (_) async => {
          'main': {'temp': 20.0},
          'weather': [
            {'description': 'nuvoloso'} 
          ],
        },
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      expect(find.text('20°'), findsOneWidget);
      expect(find.text('nuvoloso'), findsOneWidget);
    });
  });

  group('GeowatchPage – forecast', () {
    setUp(() {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());
      when(mockServiceController.weather(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeWeather);
      when(mockServiceController.forecast(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeForecastRaw);
    });

    testWidgets('scorrendo mostra la sezione FORECAST', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('FORECAST'), findsOneWidget);
    });

    testWidgets('mostra le abbreviazioni dei giorni corrette', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 28 apr 2026 = Tue, 29 apr 2026 = Wed
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
    });

    testWidgets(
        'mostra "No forecast data" se parseForecast restituisce lista vuota',
        (tester) async {
      when(mockServiceController.parseForecast(any)).thenReturn([]);

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('No forecast data'), findsOneWidget);
    });

    testWidgets('mostra al massimo 4 voci anche con 5 elementi in lista',
        (tester) async {
      when(mockServiceController.parseForecast(any)).thenReturn([
        {'date': DateTime(2026, 4, 27), 'temp': 10, 'icon': '01d'},
        {'date': DateTime(2026, 4, 28), 'temp': 11, 'icon': '01d'}, 
        {'date': DateTime(2026, 4, 29), 'temp': 12, 'icon': '01d'}, 
        {'date': DateTime(2026, 4, 30), 'temp': 13, 'icon': '01d'}, 
        {'date': DateTime(2026, 5, 1), 'temp': 14, 'icon': '01d'}, 
      ]);

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsNothing);
    });
  });

  group('GeowatchPage – alerts', () {
    setUp(() {
      when(mockTrekkingController.getTrekkingById('trek-1'))
          .thenReturn(makeTrekking());
      when(mockServiceController.weather(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeWeather);
      when(mockServiceController.forecast(45.0, 9.0, 'it'))
          .thenAnswer((_) async => fakeForecastRaw);
    });

    testWidgets('mostra "No alerts" se non ci sono allerte', (tester) async {
      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('No alerts'), findsOneWidget);
    });

    testWidgets('mostra ALERTS e il titolo quando ci sono allerte reali',
        (tester) async {
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer(
        (_) async => [
          {'event': 'Forte Vento', 'severity': 'Extreme'},
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('ALERTS'), findsOneWidget);
      expect(find.text('Forte Vento'), findsOneWidget);
    });

    testWidgets('mostra la severity di un alert', (tester) async {
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer(
        (_) async => [
          {'event': 'Temporale', 'severity': 'Severe'},
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('Severe'), findsOneWidget);
    });

    testWidgets('mostra gli alert provenienti da mockAlerts', (tester) async {
      when(mockServiceController.mockAlerts()).thenAnswer(
        (_) async => [
          {'event': 'Mock Alert', 'severity': 'Advisory'},
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('Mock Alert'), findsOneWidget);
    });

    testWidgets('combina alert reali e mock', (tester) async {
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer(
        (_) async => [
          {'event': 'Allerta Neve', 'severity': 'Moderate'},
        ],
      );
      when(mockServiceController.mockAlerts()).thenAnswer(
        (_) async => [
          {'event': 'Mock Pioggia', 'severity': ''},
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('Allerta Neve'), findsOneWidget);
      expect(find.text('Mock Pioggia'), findsOneWidget);
    });

    testWidgets('mostra al massimo 3 alert anche se ce ne sono di piu',
        (tester) async {
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer(
        (_) async => [
          {'event': 'Alert A', 'severity': ''},
          {'event': 'Alert B', 'severity': ''},
          {'event': 'Alert C', 'severity': ''},
          {'event': 'Alert D', 'severity': ''}, 
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('Alert A'), findsOneWidget);
      expect(find.text('Alert C'), findsOneWidget);
      expect(find.text('Alert D'), findsNothing);
    });

    testWidgets('alert senza campo event mostra "Weather alert" come fallback',
        (tester) async {
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer(
        (_) async => [
          {'severity': 'Low'}, 
        ],
      );

      await tester.pumpWidget(buildWidget('trek-1'));
      await tester.pumpAndSettle();

      await goToAlertsPage(tester);

      expect(find.text('Weather alert'), findsOneWidget);
    });
  });

  group('GeowatchPage – _shortDay', () {
    test('converte correttamente tutti i giorni della settimana', () {
      final helper = ShortDayHelper();
      expect(helper.shortDay(DateTime(2026, 4, 27)), 'Mon');
      expect(helper.shortDay(DateTime(2026, 4, 28)), 'Tue');
      expect(helper.shortDay(DateTime(2026, 4, 29)), 'Wed');
      expect(helper.shortDay(DateTime(2026, 4, 30)), 'Thu');
      expect(helper.shortDay(DateTime(2026, 5, 1)),  'Fri');
      expect(helper.shortDay(DateTime(2026, 5, 2)),  'Sat');
      expect(helper.shortDay(DateTime(2026, 5, 3)),  'Sun');
    });
  });
}

class ShortDayHelper {
  String shortDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}