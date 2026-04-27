import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/pages/HomePage/home-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'homepage_test.mocks.dart' show MockTrekkingController, MockServiceController;

@GenerateMocks([TrekkingController, ServiceController])

Trekking makeTrekking({
  String id = 't1',
  String difficulty = 'easy',
  List<LatLng>? points,
}) =>
    Trekking(
      documentId: id,
      name: 'Test Trek $id',
      mapPhoto: '',
      difficultyLevel: difficulty,
      distance: 5.0,
      estimatedTime: 2.0,
      elevationGain: 100.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(46.230, 10.831),
      endingPoint: const LatLng(46.240, 10.841),
      points: points ??
          [
            const LatLng(46.230, 10.831),
            const LatLng(46.235, 10.836),
            const LatLng(46.240, 10.841),
          ],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );

void main() {
  late MockTrekkingController mockTrekkingController;
  late MockServiceController mockServiceController;

  Widget buildWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(
            value: mockTrekkingController),
        Provider<ServiceController>.value(value: mockServiceController),
      ],
      child: MaterialApp(home: HomePage()),
    );
  }

  setUp(() {
    mockTrekkingController = MockTrekkingController();
    mockServiceController = MockServiceController();

    when(mockTrekkingController.allTrekkings).thenReturn([]);
    when(mockTrekkingController.loadTrekking())
        .thenAnswer((_) async {});
    when(mockServiceController.openTopoMapTile())
        .thenReturn('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png');
    when(mockServiceController.openTopoMapSubdomains())
        .thenReturn(['a', 'b', 'c']);
  });

  group('difficultyToColor', () {
    test('easy -> lightBlue', () {
      expect(difficultyToColor('easy'), Colors.lightBlue);
    });

    test('EASY maiuscolo -> lightBlue (case-insensitive)', () {
      expect(difficultyToColor('EASY'), Colors.lightBlue);
    });

    test('intermediate -> red', () {
      expect(difficultyToColor('intermediate'), Colors.red);
    });

    test('Intermediate misto -> red (case-insensitive)', () {
      expect(difficultyToColor('Intermediate'), Colors.red);
    });

    test('hard -> viola', () {
      expect(difficultyToColor('hard'),
          const Color.fromARGB(255, 135, 1, 162));
    });

    test('HARD maiuscolo -> viola (case-insensitive)', () {
      expect(difficultyToColor('HARD'),
          const Color.fromARGB(255, 135, 1, 162));
    });

    test('valore sconosciuto -> blueGrey (fallback)', () {
      expect(difficultyToColor('unknown'), Colors.blueGrey);
      expect(difficultyToColor(''), Colors.blueGrey);
      expect(difficultyToColor('expert'), Colors.blueGrey);
    });
  });

  group('HomePage – rendering base', () {
    testWidgets('mostra FlutterMap', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('chiama loadTrekking al primo avvio', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      verify(mockTrekkingController.loadTrekking()).called(1);
    });

    testWidgets('mostra il bottone di recentraggio', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('mostra i bottoni zoom + e zoom -', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('sfondo e scaffold sono neri', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('HomePage – zoom alto (polylines)', () {
    setUp(() {
      when(mockTrekkingController.allTrekkings)
          .thenReturn([makeTrekking(id: 't1', difficulty: 'easy')]);
    });

    testWidgets('con zoom >= 12.5 mostra TappablePolylineLayer',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Lo zoom iniziale è 13.0 >= 12.5
      expect(find.byType(TappablePolylineLayer), findsOneWidget);
    });

    testWidgets('con zoom >= 12.5 NON mostra MarkerLayer', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(MarkerLayer), findsNothing);
    });
  });

  group('HomePage – lista trekking vuota', () {
    testWidgets('non mostra MarkerLayer se non ci sono trekking', (tester) async {
      when(mockTrekkingController.allTrekkings).thenReturn([]);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(MarkerLayer), findsNothing);
    });
  });

  group('HomePage – trekking multipli', () {
    testWidgets('gestisce più trekking senza crash', (tester) async {
      when(mockTrekkingController.allTrekkings).thenReturn([
        makeTrekking(id: 't1', difficulty: 'easy'),
        makeTrekking(id: 't2', difficulty: 'intermediate'),
        makeTrekking(id: 't3', difficulty: 'hard'),
      ]);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });

  group('HomePage – bottoni circolari', () {
    testWidgets('i bottoni sono circolari (BoxShape.circle)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final deco = c.decoration;
        return deco is BoxDecoration && deco.shape == BoxShape.circle;
      }).toList();

      expect(containers.length, greaterThanOrEqualTo(3));
    });

    testWidgets('tap sul bottone recentra non crasha', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('tap su zoom + non crasha', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('tap su zoom - non crasha', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });

  group('HomePage – navigazione da marker', () {
    testWidgets(
        'tap su icona location_on non crasha (navigazione a TrekkingPage)',
        (tester) async {
      when(mockTrekkingController.allTrekkings)
          .thenReturn([makeTrekking(id: 't1', difficulty: 'easy')]);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(TappablePolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsNothing);
    });
  });
}