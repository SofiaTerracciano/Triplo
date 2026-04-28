import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/end_trekking.dart';

@GenerateMocks([TrekkingController])
import 'end_trekking_test.mocks.dart';

final Uint8List _kTransparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_kTransparentPng).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

Trekking _makeTrekking({
  String id = 'trek-1',
  String difficultyLevel = 'easy',
  String endingPointPhoto = 'ending.jpg',
}) {
  return Trekking(
    documentId: id,
    name: 'Monte Rosa',
    mapPhoto: '',
    difficultyLevel: difficultyLevel,
    distance: 5.0,
    estimatedTime: 90,
    elevationGain: 300,
    upGain: true,
    downGain: false,
    startingPoint: const LatLng(45.0, 9.0),
    endingPoint: const LatLng(45.1, 9.1),
    points: [const LatLng(45.0, 9.0), const LatLng(45.1, 9.1)],
    startingPointName: 'Partenza',
    endingPointName: 'Arrivo',
    info: [],
    endingPointPhoto: endingPointPhoto,
    description: [],
    picNicArea: false,
    familyFirendly: false,
  );
}

MockTrekkingController _defaultController({Trekking? trekking}) {
  final m = MockTrekkingController();
  when(m.getTrekkingById(any)).thenReturn(trekking ?? _makeTrekking());
  when(m.getDownloadUrl(any))
      .thenAnswer((_) async => 'https://example.com/photo.jpg');
  return m;
}

Widget buildEndWidget({
  required MockTrekkingController controller,
  String trekkingId = 'trek-1',
  Duration elapsedTime = const Duration(minutes: 45, seconds: 30),
}) {
  return ChangeNotifierProvider<TrekkingController>.value(
    value: controller,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: EndTrekkingPage(
        trekkingid: trekkingId,
        elapsedTime: elapsedTime,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() => HttpOverrides.global = _FakeHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  // -------------------------------------------------------------------------
  group('EndTrekkingPage – layout generale', () {
    testWidgets('scaffold ha sfondo nero', (tester) async {
      await tester.pumpWidget(buildEndWidget(controller: _defaultController()));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('mostra icona check_rounded', (tester) async {
      await tester.pumpWidget(buildEndWidget(controller: _defaultController()));
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('mostra il titolo "trekking completato"', (tester) async {
      await tester.pumpWidget(buildEndWidget(controller: _defaultController()));
      await tester.pump();

      final local = AppLocalizations.of(
        tester.element(find.byType(EndTrekkingPage)),
      )!;
      expect(
        find.text(local.trekking_completed_label.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('mostra il bottone per tornare alla home', (tester) async {
      await tester.pumpWidget(buildEndWidget(controller: _defaultController()));
      await tester.pump();

      final local = AppLocalizations.of(
        tester.element(find.byType(EndTrekkingPage)),
      )!;
      expect(find.text(local.home_page_title.toUpperCase()), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('EndTrekkingPage – formattazione tempo', () {
    testWidgets('mostra MM:SS quando ore = 0', (tester) async {
      await tester.pumpWidget(buildEndWidget(
        controller: _defaultController(),
        elapsedTime: const Duration(minutes: 45, seconds: 9),
      ));
      await tester.pump();

      expect(find.text('45:09'), findsOneWidget);
    });

    testWidgets('mostra H:MM:SS quando ore > 0', (tester) async {
      await tester.pumpWidget(buildEndWidget(
        controller: _defaultController(),
        elapsedTime: const Duration(hours: 2, minutes: 5, seconds: 3),
      ));
      await tester.pump();

      expect(find.text('2:05:03'), findsOneWidget);
    });

    testWidgets('mostra 00:00 per durata zero', (tester) async {
      await tester.pumpWidget(buildEndWidget(
        controller: _defaultController(),
        elapsedTime: Duration.zero,
      ));
      await tester.pump();

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('i secondi sono sempre a due cifre (padding)', (tester) async {
      await tester.pumpWidget(buildEndWidget(
        controller: _defaultController(),
        elapsedTime: const Duration(minutes: 3, seconds: 7),
      ));
      await tester.pump();

      expect(find.text('03:07'), findsOneWidget);
    });

    testWidgets('i minuti sono sempre a due cifre (padding)', (tester) async {
      await tester.pumpWidget(buildEndWidget(
        controller: _defaultController(),
        elapsedTime: const Duration(hours: 1, minutes: 4, seconds: 5),
      ));
      await tester.pump();

      expect(find.text('1:04:05'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('EndTrekkingPage – navigazione', () {
    testWidgets('tap sul bottone home esegue popUntil alla prima route',
        (tester) async {
      final ctrl = _defaultController();

      // Costruiamo uno stack di 3 route: home → intermedia → EndTrekkingPage
      await tester.pumpWidget(
        ChangeNotifierProvider<TrekkingController>.value(
          value: ctrl,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(builder: (ctx) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => Builder(builder: (ctx2) {
                        return Scaffold(
                          body: TextButton(
                            onPressed: () => Navigator.push(
                              ctx2,
                              MaterialPageRoute(
                                builder: (_) => const EndTrekkingPage(
                                  trekkingid: 'trek-1',
                                  elapsedTime: Duration(minutes: 30),
                                ),
                              ),
                            ),
                            child: const Text('Vai a End'),
                          ),
                        );
                      }),
                    ),
                  ),
                  child: const Text('Vai a intermedia'),
                ),
              );
            }),
          ),
        ),
      );
      await tester.pump();

      // Naviga alla pagina intermedia
      await tester.tap(find.text('Vai a intermedia'));
      await tester.pumpAndSettle();

      // Naviga a EndTrekkingPage
      await tester.tap(find.text('Vai a End'));
      await tester.pumpAndSettle();

      expect(find.byType(EndTrekkingPage), findsOneWidget);

      // Tap bottone home
      final local = AppLocalizations.of(
        tester.element(find.byType(EndTrekkingPage)),
      )!;
      await tester.tap(find.text(local.home_page_title.toUpperCase()));
      await tester.pumpAndSettle();

      // Tutte le route intermedie sono state rimosse
      expect(find.byType(EndTrekkingPage), findsNothing);
      expect(find.text('Vai a intermedia'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('EndTrekkingPage – interazioni con il controller', () {
    testWidgets('chiama getTrekkingById con il trekkingid corretto',
        (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(
        buildEndWidget(controller: ctrl, trekkingId: 'trek-xyz'),
      );
      await tester.pump();

      verify(ctrl.getTrekkingById('trek-xyz')).called(greaterThanOrEqualTo(1));
    });

    testWidgets('chiama getDownloadUrl per la foto di sfondo', (tester) async {
      final ctrl = _defaultController(
        trekking: _makeTrekking(endingPointPhoto: 'my_bg.jpg'),
      );
      await tester.pumpWidget(buildEndWidget(controller: ctrl));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(ctrl.getDownloadUrl('my_bg.jpg')).called(greaterThanOrEqualTo(1));
    });
  });
}