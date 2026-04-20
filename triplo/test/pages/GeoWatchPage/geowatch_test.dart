import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/GeowatchPage/geowatch.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'fake_http.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';

@GenerateMocks([ServiceController, TrekkingController])
void main() {
  late MockServiceController mockService;
  late MockTrekkingController mockTrekking;

  setUpAll(() {
    HttpOverrides.global = FakeHttpOverrides();
  });

  setUp(() {
    mockService = MockServiceController();
    mockTrekking = MockTrekkingController();

    when(mockService.userLocation())
        .thenAnswer((_) async => const LatLng(45.0, 9.0));

    when(mockService.weather(any, any, any)).thenAnswer((_) async => {
          'main': {'temp': 22.5},
          'weather': [
            {'icon': '01d', 'description': 'soleggiato'}
          ]
        });

    when(mockService.forecast(any, any, any))
        .thenAnswer((_) async => []);

    when(mockService.parseForecast(any)).thenReturn([]);

    when(mockService.weatherbitAlerts(any, any))
        .thenAnswer((_) async => []);

    when(mockService.mockAlerts())
        .thenAnswer((_) async => []);

    when(mockService.weatherIconUrl(any, big: anyNamed('big')))
        .thenReturn('https://example.com/icon.png');

    when(mockTrekking.isWeatherAlertEnabled(any))
        .thenAnswer((_) async => false);

    when(mockService.googleSatelliteTile())
      .thenReturn('https://example.com/tile/{z}/{x}/{y}.png');
  });

  Widget makeTestableWidget() {
    return MultiProvider(
      providers: [
        Provider<ServiceController>.value(value: mockService),
        ChangeNotifierProvider<TrekkingController>.value(
            value: mockTrekking),
      ],
      child: MaterialApp(
        localizationsDelegates:
            AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: const GeoWatchPage(
            trekkingId: "test_id",
            trailCenter: LatLng(46.0, 11.0),
          ),
        ),
      ),
    );
  }

  group('GeoWatchPage Tests', () {

    testWidgets('Mostra meteo corretto', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('23°C'), findsOneWidget);
        expect(find.textContaining('Soleggiato'), findsOneWidget);
      });
    });

    testWidgets('GPS button aggiorna posizione', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();

        final gpsButton = find.byType(GestureDetector).at(1);
        await tester.tap(gpsButton);
        await tester.pumpAndSettle();

        verify(mockService.userLocation()).called(greaterThanOrEqualTo(1));
      });
    });

    testWidgets('Toggle notifiche ON', (tester) async {
      when(mockTrekking.enableWeatherAlertForTrekking(any))
          .thenAnswer((_) async => true);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pump();

        verify(mockTrekking.enableWeatherAlertForTrekking("test_id"))
            .called(1);
      });
    });

    testWidgets('Errore meteo gestito', (tester) async {
      when(mockService.weather(any, any, any))
          .thenThrow(Exception('Network Error'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Errore'), findsOneWidget);
      });
    });
  });

  testWidgets('Switch Trail <-> GPS', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      final gpsButton = find.byType(GestureDetector).at(1);
      final trailButton = find.byType(GestureDetector).at(0);

      await tester.tap(gpsButton);
      await tester.pumpAndSettle();

      await tester.tap(trailButton);
      await tester.pumpAndSettle();

      verify(mockService.weather(any, any, any))
          .called(greaterThan(1));
    });
  });

  testWidgets('Forecast viene processato (robusto)', (tester) async {
    when(mockService.forecast(any, any, any))
        .thenAnswer((_) async => [{}]);

    when(mockService.parseForecast(any)).thenReturn([
      {
        "date": DateTime(2025, 1, 1),
        "temp": 20,
        "icon": "01d",
        "description": "sole"
      }
    ]);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });
  });

  testWidgets('Alerts mostrati', (tester) async {
    when(mockService.weatherbitAlerts(any, any)).thenAnswer((_) async => [
          {
            "event": "Storm",
            "severity": "severe",
            "description": "Heavy storm"
          }
        ]);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Storm'), findsOneWidget);
    });
  });

  testWidgets('Tap alert non crasha', (tester) async {
    when(mockService.weatherbitAlerts(any, any)).thenAnswer((_) async => [
          {
            "event": "Storm",
            "severity": "severe",
            "description": "Heavy storm"
          }
        ]);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Storm'),
        300,
      );

      await tester.tap(find.text('Storm'));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  testWidgets('Navigazione mappa', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  testWidgets('Loading state', (tester) async {
    when(mockService.weather(any, any, any))
    .thenAnswer((_) => Future.value({
          'main': {'temp': 22.5},
          'weather': [
            {'icon': '01d', 'description': 'soleggiato'}
          ]
        }));

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());

      // stato loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  testWidgets('Toggle notifiche OFF (robusto)', (tester) async {
    when(mockTrekking.isWeatherAlertEnabled(any))
        .thenAnswer((_) async => true);

    when(mockTrekking.disableWeatherAlertForTrekking(any))
        .thenAnswer((_) async => true);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_active));
      await tester.pumpAndSettle();

      verify(mockTrekking.disableWeatherAlertForTrekking("test_id"))
          .called(1);
    });
  });

  testWidgets('No forecast non crasha', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}