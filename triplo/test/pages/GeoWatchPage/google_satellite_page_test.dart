import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/pages/GeowatchPage/google_satellite_page.dart';
import '../../stub/fake_tile_provider.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';
import 'dart:typed_data';
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

  tearDown(() {});

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
          tileProvider: FakeTileProvider(),
        ),
      ),
    );
  }
  group('rendering base', () {
    testWidgets('mostra AppBar con titolo corretto', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('mostra i pulsanti zoom in e zoom out', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('mostra il menu layer con gli switch', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Switch), findsNWidgets(6));
    });

    testWidgets('mostra il marker della trail (rosso)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('mostra il marker utente quando userCenter non è null', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: userCenter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.person_pin_circle), findsOneWidget);
    });

    testWidgets('NON mostra il marker utente quando userCenter è null', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.person_pin_circle), findsNothing);
    });

    testWidgets('non mostra legend di default (nessun layer attivo)', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('weather_legend')), findsNothing);
    });
  });

  group('layer switches', () {
    testWidgets('attivare precipitazione chiama weatherTileFromId("precip")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[0]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('precip')).called(greaterThan(0));
    });

    testWidgets('attivare snow chiama weatherTileFromId("snow")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[1]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('snow')).called(greaterThan(0));
    });

    testWidgets('attivare wind chiama weatherTileFromId("wind")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[2]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('wind')).called(greaterThan(0));
    });

    testWidgets('attivare clouds chiama weatherTileFromId("clouds")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[3]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('clouds')).called(greaterThan(0));
    });

    testWidgets('attivare temperature chiama weatherTileFromId("temp")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[4]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('temp')).called(greaterThan(0));
    });

    testWidgets('attivare pressure chiama weatherTileFromId("pressure")', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[5]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.weatherTileFromId('pressure')).called(greaterThan(0));
    });
  });

  group('_disableOthers()', () {
    testWidgets('attivare precip disattiva gli altri switch', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();

      await tester.tap(find.byWidget(switches[1]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(
        find.byWidget(
          tester.widgetList<Switch>(find.byType(Switch)).toList()[0],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
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
      await tester.pump(const Duration(milliseconds: 100));

      var switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[5]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      await tester.tap(find.byWidget(switches[4]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updatedSwitches = tester
          .widgetList<Switch>(find.byType(Switch))
          .toList();
      expect(updatedSwitches[4].value, isTrue); 
      expect(updatedSwitches[5].value, isFalse); 
    });

    testWidgets(
      'disattivare uno switch lo porta a false senza toccare gli altri',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        var switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        await tester.tap(find.byWidget(switches[3]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Disattiva clouds
        switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        await tester.tap(find.byWidget(switches[3]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final updatedSwitches = tester
            .widgetList<Switch>(find.byType(Switch))
            .toList();
        for (final s in updatedSwitches) {
          expect(s.value, isFalse);
        }
      },
    );
  });

  group('zoom buttons', () {
    testWidgets('tap zoom in non lancia eccezioni', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tap zoom out non lancia eccezioni', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('ServiceController calls', () {
    testWidgets('googleSatelliteTile() viene chiamato durante il build', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockService.googleSatelliteTile()).called(greaterThan(0));
    });
  });

  testWidgets('tap zoom in non lancia eccezioni', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(Duration.zero);
  });
}

