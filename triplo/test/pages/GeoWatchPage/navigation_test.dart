import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/service/internetservice.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ServiceController>(),
  MockSpec<InternetService>(),
])
void main() {
  late MockServiceController mockService;
  late MockInternetService mockInternet;

  final position = Position(
    latitude: 45.0,
    longitude: 9.0,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 120,
    altitudeAccuracy: 1,
    heading: 90,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );

  Widget buildWidget() {
    return MultiProvider(
      providers: [
        Provider<ServiceController>.value(value: mockService),
        ChangeNotifierProvider<InternetService>.value(value: mockInternet),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CompassAltitudePage(),
      ),
    );
  }

  setUp(() {
    mockService = MockServiceController();
    mockInternet = MockInternetService();

    when(mockInternet.isOnline).thenReturn(true);

    when(mockService.navigationPositionStream())
    .thenAnswer((_) => const Stream.empty());

    when(mockService.compassStream())
        .thenAnswer((_) => const Stream.empty());

    when(mockService.navigationPositionStream())
        .thenAnswer((_) => const Stream.empty());

    when(mockService.compassStream())
        .thenAnswer((_) => const Stream.empty());
  });

  testWidgets('mostra loading iniziale', (tester) async {
    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: null,
        position: null,
        error: null,
        isChecking: true,
      );
    });

    await tester.pumpWidget(buildWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra errore GPS disabilitato', (tester) async {
    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: null,
        position: null,
        error: "GPS_DISABLED",
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byIcon(Icons.location_off), findsOneWidget);
  });

  testWidgets('mostra altitudine e coordinate', (tester) async {
    final controller = StreamController<Position>();
    final compass = StreamController<double>();

    when(mockService.navigationPositionStream())
        .thenAnswer((_) => controller.stream);

    when(mockService.compassStream())
        .thenAnswer((_) => compass.stream);

    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 120,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    controller.add(position);
    compass.add(90);

    await tester.pumpAndSettle(); 

    expect(find.textContaining("120.0"), findsOneWidget);
    expect(find.textContaining("45.00000"), findsOneWidget);
  });

  testWidgets('mostra OFFLINE quando internet è false', (tester) async {
    when(mockInternet.isOnline).thenReturn(false);

    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 120,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); 

    expect(find.textContaining("Offline"), findsOneWidget);
  });

  testWidgets('mostra direzione corretta (E)', (tester) async {
    final controller = StreamController<Position>();
    final compass = StreamController<double>();

    when(mockService.navigationPositionStream())
        .thenAnswer((_) => controller.stream);

    when(mockService.compassStream())
        .thenAnswer((_) => compass.stream);

    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 120,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    controller.add(position);
    compass.add(90);

    await tester.pumpAndSettle(); 

    expect(find.textContaining("E"), findsOneWidget);
  });

  testWidgets('mostra tutte le direzioni corrette', (tester) async {
    final controller = StreamController<Position>();
    final compass = StreamController<double>();

    when(mockService.navigationPositionStream())
        .thenAnswer((_) => controller.stream);

    when(mockService.compassStream())
        .thenAnswer((_) => compass.stream);

    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 100,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    controller.add(position);

    final directions = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    for (final entry in directions.entries) {
      compass.add(entry.key.toDouble());
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining(entry.value), findsOneWidget);
    }
  });

  testWidgets('mostra errore PERMISSION_DENIED', (tester) async {
    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: null,
        position: null,
        error: "PERMISSION_DENIED",
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byIcon(Icons.location_off), findsOneWidget);
  });

  testWidgets('tap su open settings chiama metodo corretto', (tester) async {
    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: null,
        position: null,
        error: "GPS_DISABLED",
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(mockService.openGpsSettings()).called(1);
  });

  testWidgets('mostra loading bussola se stream vuoto', (tester) async {
    when(mockService.navigationPositionStream())
        .thenAnswer((_) => Stream.value(position));

    when(mockService.compassStream())
        .thenAnswer((_) => const Stream.empty());

    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 100,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('quando app torna in foreground ricarica', (tester) async {
    when(mockService.loadNavigationLocation()).thenAnswer((_) async {
      return NavigationLocationState(
        altitude: 100,
        position: position,
        error: null,
        isChecking: false,
      );
    });

    await tester.pumpWidget(buildWidget());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pump();

    verify(mockService.loadNavigationLocation()).called(greaterThan(1));
  });
}