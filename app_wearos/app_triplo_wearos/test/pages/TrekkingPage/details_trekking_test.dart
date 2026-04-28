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
import 'package:app_triplo_wearos/pages/trekkingPage/details_trekking.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/start_trekking.dart';

@GenerateMocks([TrekkingController])
import 'details_trekking_test.mocks.dart';

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
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  bool autoUncompress = true;
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  HttpHeaders get headers => _FakeHttpHeaders();
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
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
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
  String name = 'Monte Rosa',
  double estimatedTime = 45,
  double elevationGain = 300,
  String difficultyLevel = 'easy',
  bool upGain = true,
  bool downGain = false,
  List<String> challenges = const [],
  String endingPointPhoto = 'ending.jpg',
}) {
  return Trekking(
    documentId: id,
    name: name,
    mapPhoto: '',
    difficultyLevel: difficultyLevel,
    distance: 5.0,
    estimatedTime: estimatedTime,
    elevationGain: elevationGain,
    upGain: upGain,
    downGain: downGain,
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
    challenges: challenges,
  );
}

MockTrekkingController _defaultController({Trekking? trekking}) {
  final m = MockTrekkingController();
  final t = trekking ?? _makeTrekking();
  when(m.getTrekkingById(any)).thenReturn(t);
  when(m.getDownloadUrl(any))
      .thenAnswer((_) async => 'https://example.com/photo.jpg');
  return m;
}

Widget buildDetailsWidget({
  required MockTrekkingController controller,
  String trekkingId = 'trek-1',
}) {
  return ChangeNotifierProvider<TrekkingController>.value(
    value: controller,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: DetailsTrekking(trekkingid: trekkingId),
    ),
  );
}

// Scorre il PageView di N pagine verso il basso
Future<void> _scrollPages(WidgetTester tester, int count) async {
  for (int i = 0; i < count; i++) {
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() => HttpOverrides.global = _FakeHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  group('DetailsTrekking – layout generale', () {
    testWidgets('scaffold ha sfondo nero', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('contiene un PageView con scroll verticale', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      final pv = tester.widget<PageView>(find.byType(PageView));
      expect(pv.scrollDirection, Axis.vertical);
    });
  });

  group('DetailsTrekking – prima pagina (tempo stimato)', () {
    testWidgets('mostra i minuti quando estimatedTime < 60', (tester) async {
      final ctrl = _defaultController(trekking: _makeTrekking(estimatedTime: 45));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      expect(find.text('45m'), findsOneWidget);
    });

    testWidgets('mostra ore e minuti quando estimatedTime >= 60', (tester) async {
      final ctrl = _defaultController(trekking: _makeTrekking(estimatedTime: 90));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('mostra "2h 0m" per 120 minuti', (tester) async {
      final ctrl = _defaultController(trekking: _makeTrekking(estimatedTime: 120));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      expect(find.text('2h 0m'), findsOneWidget);
    });

    testWidgets('mostra icona access_time sulla prima pagina', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });

  group('DetailsTrekking – seconda pagina (dislivello)', () {
    testWidgets('mostra il dislivello arrotondato in metri', (tester) async {
      final ctrl = _defaultController(
          trekking: _makeTrekking(elevationGain: 450.6));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 1);

      expect(find.text('451 m'), findsOneWidget);
    });

    testWidgets('mostra solo freccia su quando upGain=true downGain=false',
        (tester) async {
      final ctrl = _defaultController(
          trekking: _makeTrekking(upGain: true, downGain: false));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 1);

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('mostra solo freccia giù quando upGain=false downGain=true',
        (tester) async {
      final ctrl = _defaultController(
          trekking: _makeTrekking(upGain: false, downGain: true));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 1);

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('mostra entrambe le frecce quando upGain e downGain sono true',
        (tester) async {
      final ctrl = _defaultController(
          trekking: _makeTrekking(upGain: true, downGain: true));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 1);

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });

  group('DetailsTrekking – pagina sfide', () {
    testWidgets('mostra "no challenge" quando challenges è vuota', (tester) async {
      final ctrl = _defaultController(trekking: _makeTrekking(challenges: []));
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 2);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      expect(find.text(local.no_challenge.toUpperCase()), findsOneWidget);
    });

    testWidgets('mostra titolo sfide quando challenges non è vuota',
        (tester) async {
      final ctrl = _defaultController(
        trekking: _makeTrekking(
          challenges: ['challenge1.jpg', 'challenge2.jpg'],
        ),
      );
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 2);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      expect(find.text(local.challeng_title.toUpperCase()), findsOneWidget);
    });
  });

  group('DetailsTrekking – ultima pagina (azioni)', () {

    testWidgets('mostra il bottone Start', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 3);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      expect(find.text(local.start_trekking_label), findsOneWidget);
    });

    testWidgets('mostra il bottone Back', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 3);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      expect(find.text(local.back_label), findsOneWidget);
    });

    testWidgets('tap Start naviga a StartTrekkingPage', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 3);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      await tester.tap(find.text(local.start_trekking_label));
      await tester.pumpAndSettle();

      expect(find.byType(StartTrekkingPage), findsOneWidget);
    });

    testWidgets('tap Back fa pop della route', (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(
        ChangeNotifierProvider<TrekkingController>.value(
          value: ctrl,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Builder(
                    builder: (ctx) => TextButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DetailsTrekking(trekkingid: 'trek-1'),
                        ),
                      ),
                      child: const Text('Vai ai dettagli'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Naviga a DetailsTrekking
      await tester.tap(find.text('Vai ai dettagli'));
      await tester.pumpAndSettle();

      await _scrollPages(tester, 3);

      final local = AppLocalizations.of(
        tester.element(find.byType(DetailsTrekking)),
      )!;
      await tester.tap(find.text(local.back_label));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsTrekking), findsNothing);
      expect(find.text('Vai ai dettagli'), findsOneWidget);
    });
  });

  group('DetailsTrekking – interazioni con il controller', () {
    testWidgets('chiama getTrekkingById con trekkingid passato al widget',
        (tester) async {
      final ctrl = _defaultController();
      await tester.pumpWidget(
        buildDetailsWidget(controller: ctrl, trekkingId: 'trek-xyz'),
      );
      await tester.pump();

      verify(ctrl.getTrekkingById('trek-xyz')).called(greaterThanOrEqualTo(1));
    });

    testWidgets('chiama getDownloadUrl per la foto di sfondo', (tester) async {
      final ctrl = _defaultController(
        trekking: _makeTrekking(endingPointPhoto: 'my_photo.jpg'),
      );
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      verify(ctrl.getDownloadUrl('my_photo.jpg'))
          .called(greaterThanOrEqualTo(1));
    });

    testWidgets('chiama getDownloadUrl per ogni immagine sfida', (tester) async {
      final ctrl = _defaultController(
        trekking: _makeTrekking(
          challenges: ['ch1.jpg', 'ch2.jpg'],
        ),
      );
      await tester.pumpWidget(buildDetailsWidget(controller: ctrl));
      await tester.pump();

      await _scrollPages(tester, 2);
      await tester.pump(const Duration(milliseconds: 300));

      verify(ctrl.getDownloadUrl('ch1.jpg')).called(greaterThanOrEqualTo(1));
      verify(ctrl.getDownloadUrl('ch2.jpg')).called(greaterThanOrEqualTo(1));
    });
  });
}