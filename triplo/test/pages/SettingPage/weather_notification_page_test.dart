import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/SettingsPage/weather_notification_page.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';
import 'weather_notification_page_test.mocks.dart' hide MockTrekkingController;

@GenerateMocks([TrekkingController])

void main() {
  group('WeatherAlertSubscriptionPage – widget', () {
    late MockTrekkingController mockTrekkingController;

    setUp(() {
      mockTrekkingController = MockTrekkingController();
      when(mockTrekkingController.addListener(any)).thenReturn(null);
      when(mockTrekkingController.removeListener(any)).thenReturn(null);
    });

    Trekking _buildTrekking({
      String id = 'trek-1',
      String name = 'Monte Bianco',
      String difficulty = 'hard',
      double distance = 12.5,
    }) =>
        Trekking(
          documentId: id,
          name: name,
          mapPhoto: 'photo.jpg',
          difficultyLevel: difficulty,
          distance: distance,
          estimatedTime: 4.0,
          elevationGain: 800,
          upGain: true,
          downGain: true,
          startingPoint: const LatLng(45.0, 7.0),
          endingPoint: const LatLng(45.1, 7.1),
          points: [],
          startingPointName: 'Start',
          endingPointName: 'End',
          info: [],
          endingPointPhoto: '',
          description: [],
          picNicArea: false,
          familyFirendly: false,
        );

    Widget buildPage() => ChangeNotifierProvider<TrekkingController>.value(
          value: mockTrekkingController,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WeatherAlertSubscriptionPage(),
          ),
        );

    testWidgets('mostra CircularProgressIndicator durante il caricamento',
        (tester) async {
      final completer = Completer<List<Trekking>>();
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra messaggio errore se Future lancia eccezione',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => throw Exception('network error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
      expect(find.text(local.error_loading_trekkings), findsOneWidget);
    });

    testWidgets('errore non mostra ListView', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => throw Exception('error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('mostra messaggio no_weather_alerts se lista vuota',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
      expect(find.text(local.no_weather_alerts), findsOneWidget);
    });

    testWidgets('lista vuota non mostra ListView', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('mostra AppBar con titolo weather_alerts_label', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
      expect(find.text(local.weather_alerts_label), findsOneWidget);
    });

    testWidgets('mostra nome trekking nella card', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking(name: 'Monte Bianco')]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Monte Bianco'), findsOneWidget);
    });

    testWidgets('mostra distanza trekking nella card', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking(distance: 12.5)]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('12.5'), findsOneWidget);
    });

    testWidgets('mostra livello difficoltà nella card', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking(difficulty: 'hard')]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('hard'), findsOneWidget);
    });

    testWidgets('mostra ListView quando ci sono trekking', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('mostra tante Card quanti sono i trekking', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings()).thenAnswer(
        (_) async => [
          _buildTrekking(id: 'trek-1', name: 'Monte Bianco'),
          _buildTrekking(id: 'trek-2', name: 'Monte Rosa'),
          _buildTrekking(id: 'trek-3', name: 'Monte Cervino'),
        ],
      );
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('mostra bottone open_button per ogni trekking', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
      expect(find.text(local.open_button), findsOneWidget);
    });

    testWidgets('mostra bottone remove_button per ogni trekking', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
      expect(find.text(local.remove_button), findsOneWidget);
    });

    testWidgets('mostra icona notifications_off nel bottone remove',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    });

    testWidgets('mostra icona open_in_new nel bottone open', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('senza immagine cached mostra icona terrain', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('tap remove chiama disableWeatherAlertForTrekking',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final trek = _buildTrekking(id: 'trek-1');
      var callCount = 0;
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? [trek] : [];
      });
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
      when(mockTrekkingController.disableWeatherAlertForTrekking(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;

      await tester.tap(find.text(local.remove_button));
      await tester.pumpAndSettle();

      verify(mockTrekkingController.disableWeatherAlertForTrekking('trek-1'))
          .called(1);
    });

    testWidgets('tap remove mostra SnackBar weather_alert_removed',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final trek = _buildTrekking(id: 'trek-1');
      var callCount = 0;
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? [trek] : [];
      });
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
      when(mockTrekkingController.disableWeatherAlertForTrekking(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;

      await tester.tap(find.text(local.remove_button));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(local.weather_alert_removed), findsOneWidget);
    });

    testWidgets('mostra RefreshIndicator quando ci sono trekking',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('pull-to-refresh richiama getWeatherAlertTrekkings',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 400),
        800,
      );
      await tester.pumpAndSettle();

      verify(mockTrekkingController.getWeatherAlertTrekkings())
          .called(greaterThanOrEqualTo(2));
    });
  });
}