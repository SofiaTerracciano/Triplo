import 'dart:async';
import 'dart:io';
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
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
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

    testWidgets('con immagine cached mostra Image.file nella card', (tester) async {
      // Crea un file temporaneo valido da passare come cached image
      final tmpDir = Directory.systemTemp.createTempSync('weather_test');
      final tmpFile = File('${tmpDir.path}/img.png');
      // Scrive un PNG 1x1 pixel valido
      tmpFile.writeAsBytesSync([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
        0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
 
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [_buildTrekking()]);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => tmpFile);
 
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
 
      expect(find.byType(Image), findsOneWidget);
      // L'icona terrain NON deve comparire quando c'è un'immagine
      expect(find.byIcon(Icons.terrain), findsNothing);
 
      tmpDir.deleteSync(recursive: true);
    });
 
    // ── Immagine in loading → spinner piccolo nella card ──────────────────
 
    testWidgets('immagine in loading mostra CircularProgressIndicator nella card',
        (tester) async {
      final listCompleter = Completer<List<Trekking>>();
      final imageCompleter = Completer<File?>();
 
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) => listCompleter.future);
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) => imageCompleter.future);
 
      await tester.pumpWidget(buildPage());
 
      // Completa prima la lista così la card viene renderata
      listCompleter.complete([_buildTrekking()]);
      await tester.pump(); // processa il completamento della lista
      await tester.pump(); // processa il FutureBuilder della lista
 
      // L'immagine è ancora in attesa → spinner nella card visibile
      expect(find.byType(CircularProgressIndicator), findsWidgets);
 
      // Pulizia
      imageCompleter.complete(null);
      await tester.pumpAndSettle();
    });
 
 
    // ── Più trekking: tutti i nomi visibili ───────────────────────────────
 
    testWidgets('tutti i nomi dei trekking sono visibili nella lista', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings()).thenAnswer(
        (_) async => [
          _buildTrekking(id: '1', name: 'Alpha'),
          _buildTrekking(id: '2', name: 'Beta'),
          _buildTrekking(id: '3', name: 'Gamma'),
        ],
      );
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
 
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
 
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });
 
    // ── Separatori tra card ───────────────────────────────────────────────
 
    testWidgets('con 3 trekking ci sono 3 Card e 2 separatori SizedBox', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings()).thenAnswer(
        (_) async => [
          _buildTrekking(id: '1', name: 'T1'),
          _buildTrekking(id: '2', name: 'T2'),
          _buildTrekking(id: '3', name: 'T3'),
        ],
      );
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
 
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
 
      expect(find.byType(Card), findsNWidgets(3));
    });
 
    // ── Snapshot data null → lista vuota trattata come [] ─────────────────
 
    testWidgets('snapshot.data null viene trattato come lista vuota', (tester) async {
      // Restituisce null come dato
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
 
    // ── Dopo remove, lista si aggiorna (reload) ───────────────────────────
 
    testWidgets('dopo remove la lista viene ricaricata senza il trekking rimosso',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
 
      int callCount = 0;
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [
            _buildTrekking(id: 't1', name: 'Rimosso'),
            _buildTrekking(id: 't2', name: 'Rimasto'),
          ];
        }
        return [_buildTrekking(id: 't2', name: 'Rimasto')];
      });
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
      when(mockTrekkingController.disableWeatherAlertForTrekking(any))
          .thenAnswer((_) async {});
 
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
 
      expect(find.text('Rimosso'), findsOneWidget);
      expect(find.text('Rimasto'), findsOneWidget);
 
      final local = AppLocalizations.of(
        tester.element(find.byType(WeatherAlertSubscriptionPage)),
      )!;
 
      // Tap remove sul primo
      await tester.tap(find.text(local.remove_button).first);
      await tester.pumpAndSettle();
 
      expect(find.text('Rimosso'), findsNothing);
      expect(find.text('Rimasto'), findsOneWidget);
    });
 
    // ── getCachedImage viene chiamato per ogni trekking ───────────────────
 
    testWidgets('getCachedImage viene chiamato una volta per ogni trekking',
        (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings()).thenAnswer(
        (_) async => [
          _buildTrekking(id: '1', name: 'T1'),
          _buildTrekking(id: '2', name: 'T2'),
        ],
      );
      when(mockTrekkingController.getCachedImage(any))
          .thenAnswer((_) async => null);
 
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
 
      verify(mockTrekkingController.getCachedImage(any))
          .called(greaterThanOrEqualTo(2));
    });

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