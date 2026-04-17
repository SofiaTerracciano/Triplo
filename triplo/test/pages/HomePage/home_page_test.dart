import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:triplo/pages/SearchPage/search-page.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';


void main() {
  late MockServiceController mockService;
  late MockTrekkingController mockTrekking;


  setUp(() {
    mockService = MockServiceController();
    mockTrekking = MockTrekkingController();

    when(mockService.openTopoMapTile())
    .thenReturn('https://example.com/{z}/{x}/{y}.png'); 
    when(mockService.openTopoMapSubdomains()).thenReturn(['a', 'b', 'c']);
    when(mockService.openTopoMapSubdomains()).thenReturn(['a']);
    when(mockTrekking.allTrekkings).thenReturn([]);
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        Provider<ServiceController>.value(value: mockService),
        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MyHomePage(),
      ),
    );
  }

  testWidgets('pagina si carica', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('zoom in e zoom out funzionano', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNWidgets(2));
  });

  testWidgets('apre drawer', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();

    expect(find.byType(Drawer), findsOneWidget);
  });

  testWidgets('naviga a SearchPage', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.byType(SearchPage), findsOneWidget);
  });

  test('difficultyToColor copre tutti i rami', () {
    expect(difficultyToColor('easy'), Colors.lightBlue);
    expect(difficultyToColor('intermediate'), Colors.red);
    expect(difficultyToColor('hard'), const Color.fromARGB(255, 135, 1, 162));
    expect(difficultyToColor('unknown'), Colors.blueGrey);
  });


  testWidgets('mostra marker con trekking', (tester) async {
    final fake = Trekking(
      documentId: '1',
      name: 'Test',
      mapPhoto: '',
      difficultyLevel: 'easy',
      distance: 1,
      estimatedTime: 1,
      elevationGain: 1,
      upGain: true,
      downGain: false,
      startingPoint: LatLng(46.23, 10.83),
      endingPoint: LatLng(46.23, 10.83),
      points: [LatLng(46.23, 10.83)],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );

    when(mockTrekking.allTrekkings).thenReturn([fake]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.place), findsWidgets);
  });

  testWidgets('tap marker apre TrekkingPage', (tester) async {
    final fake = Trekking(
      documentId: '1',
      name: 'Test',
      mapPhoto: '',
      difficultyLevel: 'easy',
      distance: 1,
      estimatedTime: 1,
      elevationGain: 1,
      upGain: true,
      downGain: false,
      startingPoint: LatLng(46.23, 10.83),
      endingPoint: LatLng(46.23, 10.83),
      points: [LatLng(46.23, 10.83)],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );

    when(mockTrekking.allTrekkings).thenReturn([fake]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.place).first);
    await tester.pump();

    expect(find.byType(TrekkingPage), findsOneWidget);
  });

  // ---------------- POLYLINE ----------------

  testWidgets('mostra polylines se zoom alto', (tester) async {
    final fake = Trekking(
      documentId: '1',
      name: 'Test',
      mapPhoto: '',
      difficultyLevel: 'easy',
      distance: 1,
      estimatedTime: 1,
      elevationGain: 1,
      upGain: true,
      downGain: false,
      startingPoint: LatLng(46.23, 10.83),
      endingPoint: LatLng(46.23, 10.83),
      points: [LatLng(46.23, 10.83)],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );

    when(mockTrekking.allTrekkings).thenReturn([fake]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(FlutterMap), findsOneWidget);
  });

  // ---------------- RECENTER ----------------

  testWidgets('mostra bottone recenter', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;

    state.setState(() {
      state.showRecenter = true;
    });

    await tester.pump();

    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets('tap recenter funziona', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(seconds: 1));

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;

    state.setState(() {
      state.showRecenter = true;
    });

    await tester.pump();

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();

    expect(find.byIcon(Icons.my_location), findsNothing);
  });
}

// ---------------- FAKE MODEL ----------------

class FakeTrekking {
  final String documentId;
  final LatLng starting_point;
  final List<LatLng> points;
  final String difficulty_level;

  FakeTrekking({
    required this.documentId,
    required this.starting_point,
    required this.points,
    required this.difficulty_level,
  });
}

final trekking = Trekking(
  documentId: '1',
  name: 'Test Trek',
  mapPhoto: 'photo.png',
  difficultyLevel: 'easy',
  distance: 10,
  estimatedTime: 2,
  elevationGain: 500,
  upGain: true,
  downGain: false,
  startingPoint: LatLng(46.23, 10.83),
  endingPoint: LatLng(46.24, 10.84),
  points: [
    LatLng(46.23, 10.83),
    LatLng(46.24, 10.84),
  ],
  startingPointName: 'Start',
  endingPointName: 'End',
  info: ['info'],
  endingPointPhoto: 'end.png',
  description: ['desc'],
  picNicArea: true,
  familyFirendly: true,
);