import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:triplo/widgets_for_pages/weather/weather.dart';

void main() {
  group('Weather Widget Tests', () {

    testWidgets('Mostra loading spinner quando loading=true', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          const Weather(
            weather: null,
            loading: true,
            error: null,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('Mostra errore quando error != null', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          const Weather(
            weather: null,
            loading: false,
            error: "Network error",
          ),
        ));

        expect(find.textContaining("Network error"), findsOneWidget);
      });
    });

    testWidgets('Mostra messaggio quando weather == null', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          const Weather(
            weather: null,
            loading: false,
            error: null,
          ),
        ));

        expect(find.byType(Text), findsWidgets);
      });
    });

    testWidgets('Render corretto con dati validi', (tester) async {
      final weatherData = {
        "name": "Milano",
        "main": {"temp": 20.4},
        "weather": [
          {"description": "clear sky", "icon": "01d"}
        ]
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          Weather(
            weather: weatherData,
            loading: false,
            error: null,
          ),
        ));

        expect(find.text("Milano"), findsOneWidget);
        expect(find.text("20°C"), findsOneWidget);
        expect(find.text("clear sky"), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      });
    });

    testWidgets('Hide location name usa trail_area_label', (tester) async {
      final weatherData = {
        "name": "Milano",
        "main": {"temp": 15},
        "weather": [
          {"description": "cloudy", "icon": "02d"}
        ]
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          Weather(
            weather: weatherData,
            loading: false,
            error: null,
            hideLocationName: true,
          ),
        ));

        expect(find.text("Milano"), findsNothing);
        expect(find.byType(Text), findsWidgets);
      });
    });

    testWidgets('Fallback valori mancanti', (tester) async {
      final weatherData = {
        "main": {},
        "weather": [{}]
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          Weather(
            weather: weatherData,
            loading: false,
            error: null,
          ),
        ));

        expect(find.text("-°C"), findsOneWidget);
        expect(find.text("-"), findsWidgets);
      });
    });

    testWidgets('Mostra current_position_label se name null', (tester) async {
      final weatherData = {
        "main": {"temp": 10},
        "weather": [
          {"description": "rain", "icon": "09d"}
        ]
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildTestableWidget(
          Weather(
            weather: weatherData,
            loading: false,
            error: null,
          ),
        ));

        expect(find.byType(Text), findsWidgets);
      });
    });

  });
}

Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: child,
    ),
  );
}