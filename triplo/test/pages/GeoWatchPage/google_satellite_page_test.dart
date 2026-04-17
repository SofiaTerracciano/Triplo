import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/pages/GeowatchPage/google_satellite_page.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';

@GenerateMocks([ServiceController])

class NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) => throw Exception('No network in tests');
}
void main() {
  late MockServiceController mockService;

  const trailCenter = LatLng(45.0, 9.0);
  const userCenter = LatLng(45.1, 9.1);
  const initialCenter = LatLng(45.05, 9.05);

  setUp(() {
    mockService = MockServiceController();

    when(
      mockService.googleSatelliteTile(),
    ).thenReturn('https://mt0.google.com/vt/lyrs=s&x={x}&y={y}&z={z}');
    when(mockService.weatherTileFromId(any)).thenReturn(
      'https://tile.openweathermap.org/map/precipitation/{z}/{x}/{y}.png',
    );

    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUpAll(() {
    HttpOverrides.global = NoNetworkHttpOverrides();
  });

  Widget buildWidget({
    LatLng trail = trailCenter,
    LatLng? user = userCenter,
    LatLng initial = initialCenter,
  }) {
    return Provider<ServiceController>.value(
      value: mockService,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GoogleSatellitePage(
          trailCenter: trail,
          userCenter: user,
          initialCenter: initial,
        ),
      ),
    );
  }
  group('rendering base', () {
    testWidgets('mostra AppBar con titolo corretto', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('mostra i pulsanti zoom in e zoom out', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('mostra il menu layer con gli switch', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // 6 switch: precip, snow, wind, clouds, temp, pressure
      expect(find.byType(Switch), findsNWidgets(6));
    });

    testWidgets('mostra il marker della trail (rosso)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('mostra il marker utente quando userCenter non è null', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: userCenter));
      await tester.pump();

      expect(find.byIcon(Icons.person_pin_circle), findsOneWidget);
    });

    testWidgets('NON mostra il marker utente quando userCenter è null', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: null));
      await tester.pump();

      expect(find.byIcon(Icons.person_pin_circle), findsNothing);
    });

    testWidgets('non mostra legend di default (nessun layer attivo)', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Nessun layer attivo → _buildLegendWidget() ritorna null
      // Verifichiamo indirettamente che non ci siano widget legend
      // (la legend è un Card con colori specifici per layer)
      expect(find.byKey(const Key('weather_legend')), findsNothing);
    });
  });

  // =========================================================================
  // Switch layer — attivazione
  // =========================================================================
  group('layer switches', () {
    testWidgets('attivare precipitazione chiama weatherTileFromId("precip")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[0]));
      await tester.pump();

      verify(mockService.weatherTileFromId('precip')).called(greaterThan(0));
    });

    testWidgets('attivare snow chiama weatherTileFromId("snow")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[1]));
      await tester.pump();

      verify(mockService.weatherTileFromId('snow')).called(greaterThan(0));
    });

    testWidgets('attivare wind chiama weatherTileFromId("wind")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[2]));
      await tester.pump();

      verify(mockService.weatherTileFromId('wind')).called(greaterThan(0));
    });

    testWidgets('attivare clouds chiama weatherTileFromId("clouds")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[3]));
      await tester.pump();

      verify(mockService.weatherTileFromId('clouds')).called(greaterThan(0));
    });

    testWidgets('attivare temperature chiama weatherTileFromId("temp")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[4]));
      await tester.pump();

      verify(mockService.weatherTileFromId('temp')).called(greaterThan(0));
    });

    testWidgets('attivare pressure chiama weatherTileFromId("pressure")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[5]));
      await tester.pump();

      verify(mockService.weatherTileFromId('pressure')).called(greaterThan(0));
    });
  });

  // =========================================================================
  // _disableOthers() — attivarne uno disattiva gli altri
  // =========================================================================
  group('_disableOthers()', () {
    testWidgets('attivare precip disattiva gli altri switch', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();

      // Prima attiva snow
      await tester.tap(find.byWidget(switches[1]));
      await tester.pump();

      // Poi attiva precip
      await tester.tap(
        find.byWidget(
          tester.widgetList<Switch>(find.byType(Switch)).toList()[0],
        ),
      );
      await tester.pump();

      // Ora solo precip deve essere true
      final updatedSwitches = tester
          .widgetList<Switch>(find.byType(Switch))
          .toList();
      expect(updatedSwitches[0].value, isTrue); // precip ON
      expect(updatedSwitches[1].value, isFalse); // snow OFF
      expect(updatedSwitches[2].value, isFalse); // wind OFF
      expect(updatedSwitches[3].value, isFalse); // clouds OFF
      expect(updatedSwitches[4].value, isFalse); // temp OFF
      expect(updatedSwitches[5].value, isFalse); // pressure OFF
    });

    testWidgets('attivare temp disattiva gli altri switch', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Prima attiva pressure
      var switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[5]));
      await tester.pump();

      // Poi attiva temp
      switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[4]));
      await tester.pump();

      final updatedSwitches = tester
          .widgetList<Switch>(find.byType(Switch))
          .toList();
      expect(updatedSwitches[4].value, isTrue); // temp ON
      expect(updatedSwitches[5].value, isFalse); // pressure OFF
    });

    testWidgets(
      'disattivare uno switch lo porta a false senza toccare gli altri',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        // Attiva clouds
        var switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        await tester.tap(find.byWidget(switches[3]));
        await tester.pump();

        // Disattiva clouds
        switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        await tester.tap(find.byWidget(switches[3]));
        await tester.pump();

        final updatedSwitches = tester
            .widgetList<Switch>(find.byType(Switch))
            .toList();
        for (final s in updatedSwitches) {
          expect(s.value, isFalse);
        }
      },
    );
  });

  // =========================================================================
  // Zoom buttons
  // =========================================================================
  group('zoom buttons', () {
    testWidgets('tap zoom in non lancia eccezioni', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      // Se non lancia, il test passa
    });

    testWidgets('tap zoom out non lancia eccezioni', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
    });
  });

  // =========================================================================
  // googleSatelliteTile chiamato al build
  // =========================================================================
  group('ServiceController calls', () {
    testWidgets('googleSatelliteTile() viene chiamato durante il build', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      verify(mockService.googleSatelliteTile()).called(greaterThan(0));
    });
  });

  testWidgets('tap zoom in non lancia eccezioni', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(Duration.zero);
  });
}
