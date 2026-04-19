import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/servicecontroller.dart'
    show ServiceController, NavigationLocationState;
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:triplo/pages/SearchPage/search-page.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../TrekkingPage/trekking_page_test.mocks.dart';

class MockLanguage extends Mock implements Language {
  @override
  Locale get locale => const Locale('it');
}

class MockUserController extends Mock implements UserController {
  @override
  bool get isLoading => false;
}

class MockDiaryController extends Mock implements DiaryController {}

class MockChallengesController extends Mock implements ChallengesController {}

final _fakeTrekking = Trekking(
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
  points: [LatLng(46.23, 10.83), LatLng(46.24, 10.84)],
  startingPointName: 'Start',
  endingPointName: 'End',
  info: [],
  endingPointPhoto: '',
  description: [],
  picNicArea: false,
  familyFirendly: false,
);

void main() {
  late MockServiceController mockService;
  late MockTrekkingController mockTrekking;
  late MockLanguage mockLanguage;
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;
  late MockChallengesController mockChallengesController;

  setUp(() {
    mockService = MockServiceController();
    mockTrekking = MockTrekkingController();
    mockLanguage = MockLanguage();
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
    mockChallengesController = MockChallengesController();

    when(mockService.openTopoMapTile())
        .thenReturn('https://example.com/{z}/{x}/{y}.png');
    when(mockService.openTopoMapSubdomains()).thenReturn(['a']);
    when(mockTrekking.allTrekkings).thenReturn([]);

    when(mockTrekking.getTrekkingById('1')).thenReturn(_fakeTrekking);

    when(mockService.loadNavigationLocation()).thenAnswer(
      (_) async => const NavigationLocationState(
        altitude: null,
        position: null,
        error: null,
        isChecking: false,
      ),
    );
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        Provider<ServiceController>.value(value: mockService),
        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),
        ChangeNotifierProvider<Language>.value(value: mockLanguage),
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
        ChangeNotifierProvider<ChallengesController>.value(
            value: mockChallengesController),
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

  Trekking makeFakeTrekking({String difficulty = 'easy', String id = '1'}) =>
      Trekking(
        documentId: id,
        name: 'Test $id',
        mapPhoto: '',
        difficultyLevel: difficulty,
        distance: 1,
        estimatedTime: 1,
        elevationGain: 1,
        upGain: true,
        downGain: false,
        startingPoint: LatLng(46.23, 10.83),
        endingPoint: LatLng(46.23, 10.83),
        points: [LatLng(46.23, 10.83), LatLng(46.24, 10.84)],
        startingPointName: 'Start',
        endingPointName: 'End',
        info: [],
        endingPointPhoto: '',
        description: [],
        picNicArea: false,
        familyFirendly: false,
      );

  testWidgets('pagina si carica', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('zoom in e zoom out funzionano', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNWidgets(2));
  });

  testWidgets('apre drawer', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
  });

  testWidgets('drawer contiene tutte le voci di navigazione', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('tap Home nel drawer chiude il drawer', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(MyHomePage), findsOneWidget);
  });

  testWidgets('naviga a SearchPage', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('tap Settings naviga fuori dalla home', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(MyHomePage), findsNothing);
  });

  test('difficultyToColor copre tutti i rami', () {
    expect(difficultyToColor('easy'), Colors.lightBlue);
    expect(difficultyToColor('intermediate'), Colors.red);
    expect(difficultyToColor('hard'), const Color.fromARGB(255, 135, 1, 162));
    expect(difficultyToColor('unknown'), Colors.blueGrey);
  });

  test('difficultyToColor è case-insensitive', () {
    expect(difficultyToColor('EASY'), Colors.lightBlue);
    expect(difficultyToColor('Hard'), const Color.fromARGB(255, 135, 1, 162));
    expect(difficultyToColor('INTERMEDIATE'), Colors.red);
  });

  testWidgets('mostra marker con trekking a zoom basso', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([makeFakeTrekking()]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    expect(find.byIcon(Icons.place), findsWidgets);
  });

  testWidgets('marker easy ha colore lightBlue', (tester) async {
    when(mockTrekking.allTrekkings)
        .thenReturn([makeFakeTrekking(difficulty: 'easy')]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.place));
    expect(icon.color, Colors.lightBlue);
  });

  testWidgets('marker intermediate ha colore rosso', (tester) async {
    when(mockTrekking.allTrekkings)
        .thenReturn([makeFakeTrekking(difficulty: 'intermediate')]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.place));
    expect(icon.color, Colors.red);
  });

  testWidgets('marker hard ha colore viola', (tester) async {
    when(mockTrekking.allTrekkings)
        .thenReturn([makeFakeTrekking(difficulty: 'hard')]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.place));
    expect(icon.color, const Color.fromARGB(255, 135, 1, 162));
  });

  testWidgets('con lista vuota non mostra marker', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    expect(find.byIcon(Icons.place), findsNothing);
  });

  testWidgets('tap marker apre TrekkingPage', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([makeFakeTrekking()]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 10.0);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.place).first);
    await tester.pumpAndSettle();

    expect(find.byType(TrekkingPage), findsOneWidget);
  });

  testWidgets('mostra polylines a zoom >= 12', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([makeFakeTrekking()]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 13.0);
    await tester.pump();

    expect(find.byType(TappablePolylineLayer), findsOneWidget);
  });

  testWidgets('a zoom esattamente 12 mostra polylines non marker', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([makeFakeTrekking()]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 12.0);
    await tester.pump();

    expect(find.byType(TappablePolylineLayer), findsOneWidget);
    expect(find.byIcon(Icons.place), findsNothing);
  });

  testWidgets('a zoom < 12 mostra marker non polylines', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([makeFakeTrekking()]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 11.9);
    await tester.pump();

    expect(find.byType(TappablePolylineLayer), findsNothing);
    expect(find.byIcon(Icons.place), findsWidgets);
  });

  testWidgets('TappablePolylineLayer ha una polyline per ogni trekking',
      (tester) async {
    final t1 = makeFakeTrekking(difficulty: 'easy', id: '1');
    final t2 = makeFakeTrekking(difficulty: 'intermediate', id: '2');
    when(mockTrekking.allTrekkings).thenReturn([t1, t2]);
    when(mockTrekking.getTrekkingById('2')).thenReturn(t2);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 13.0);
    await tester.pump();

    final layer = tester.widget<TappablePolylineLayer>(
      find.byType(TappablePolylineLayer),
    );
    expect(layer.polylines.length, 2);
  });

  testWidgets('con lista vuota polylines è vuoto', (tester) async {
    when(mockTrekking.allTrekkings).thenReturn([]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.currentZoom = 13.0);
    await tester.pump();

    final layer = tester.widget<TappablePolylineLayer>(
      find.byType(TappablePolylineLayer),
    );
    expect(layer.polylines.isEmpty, isTrue);
  });

  testWidgets('bottone recenter non visibile inizialmente', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.my_location), findsNothing);
  });

  testWidgets('mostra bottone recenter quando showRecenter è true', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.showRecenter = true);
    await tester.pump();

    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets('tap recenter nasconde il bottone', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(ZoomAwareMap)) as dynamic;
    state.setState(() => state.showRecenter = true);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();

    expect(find.byIcon(Icons.my_location), findsNothing);
  });
}