import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/service/backgroundservice.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/notification.dart';
import 'backgroundservice_test.mocks.dart' show MockTrekkingController, MockServiceController, MockNotificationService, MockMemoryService;


@GenerateMocks([
  TrekkingController,
  ServiceController,
  NotificationService,
  MemoryService,
])

Trekking fakeTrekking({
  String documentId = 'trek-001',
  String name = 'Test Trek',
  LatLng? startingPoint,
  LatLng? endingPoint,
}) {
  final start = startingPoint ?? const LatLng(45.0, 9.0);
  final end = endingPoint ?? const LatLng(45.1, 9.1);
  return Trekking(
    documentId: documentId,
    name: name,
    mapPhoto: '',
    difficultyLevel: 'easy',
    distance: 5.0,
    estimatedTime: 2.0,
    elevationGain: 100.0,
    upGain: true,
    downGain: true,
    startingPoint: start,
    endingPoint: end,
    points: [start, end],
    startingPointName: 'Start',
    endingPointName: 'End',
    info: [],
    endingPointPhoto: '',
    description: [],
    picNicArea: false,
    familyFirendly: false,
  );
}

Map<String, dynamic> fakeAlert({
  String event = 'Thunderstorm',
  String headline = 'Storm warning',
  String start = '2024-01-01',
  String end = '2024-01-02',
}) =>
    {'event': event, 'headline': headline, 'start': start, 'end': end};

Widget buildProviderTree({
  required MockTrekkingController trekkingController,
  required MockServiceController api,
  required MockNotificationService notification,
  required MockMemoryService memory,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TrekkingController>.value(value: trekkingController),
      Provider<ServiceController>.value(value: api),
      Provider<NotificationService>.value(value: notification),
      Provider<MemoryService>.value(value: memory),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockTrekkingController mockTrekkingController;
  late MockServiceController mockApi;
  late MockNotificationService mockNotification;
  late MockMemoryService mockMemory;

  setUp(() {
    mockTrekkingController = MockTrekkingController();
    mockApi = MockServiceController();
    mockNotification = MockNotificationService();
    mockMemory = MockMemoryService();
  });

  Future<void> runLogic() => BackgroundServiceLogic.run(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

  void stubNotificationAndMemory({bool alreadyShown = false}) {
    when(mockMemory.hasShownWeatherAlertKey(any))
        .thenAnswer((_) async => alreadyShown);
    when(mockMemory.addShownWeatherAlertKey(any))
        .thenAnswer((_) async => {});
    when(mockNotification.showWeatherNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => {});
  }

  group('BackgroundServiceLogic', () {
    group('nessun trekking', () {
      test('non chiama le API se la lista è vuota', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => []);

        await runLogic();

        verifyNever(mockApi.weatherbitAlerts(any, any));
        verifyNever(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ));
      });
    });

    group('nessun alert meteo', () {
      test('non invia notifiche se API e mock non restituiscono alert', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking()]);
        when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => []);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);

        await runLogic();

        verifyNever(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ));
      });
    });

    group('coordinate GPS', () {
      test('chiama weatherbitAlerts con le coordinate di starting_point', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async =>
                [fakeTrekking(startingPoint: const LatLng(45.9, 7.8))]);
        when(mockApi.weatherbitAlerts(45.9, 7.8)).thenAnswer((_) async => []);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);

        await runLogic();

        verify(mockApi.weatherbitAlerts(45.9, 7.8)).called(1);
      });
    });

    group('titolo notifica', () {
      test('usa "event" come titolo', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking(name: 'Monte Rosa')]);
        when(mockApi.weatherbitAlerts(any, any))
            .thenAnswer((_) async => [fakeAlert(event: 'Thunderstorm')]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Thunderstorm',
          body: 'Alert for Monte Rosa',
        )).called(1);
      });

      test('usa "title" se "event" è assente', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking(name: 'Val Camonica')]);
        when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async =>
            [{'title': 'Heavy Rain', 'headline': '', 'start': '2024-01-01', 'end': '2024-01-02'}]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Heavy Rain',
          body: 'Alert for Val Camonica',
        )).called(1);
      });

      test('usa "Weather alert" come fallback se event e title sono assenti', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking()]);
        when(mockApi.weatherbitAlerts(any, any))
            .thenAnswer((_) async => [<String, dynamic>{}]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Weather alert',
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('deduplicazione', () {
      test('non invia notifica per alert già mostrato', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking()]);
        when(mockApi.weatherbitAlerts(any, any))
            .thenAnswer((_) async => [fakeAlert()]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory(alreadyShown: true);

        await runLogic();

        verifyNever(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ));
        verifyNever(mockMemory.addShownWeatherAlertKey(any));
      });

      test('invia solo gli alert non ancora mostrati', () async {
        final alertNew = fakeAlert(headline: 'New', start: '2024-02-01', end: '2024-02-02');
        final alertOld = fakeAlert(headline: 'Old', start: '2024-01-01', end: '2024-01-02');
        const newKey = 'trek-001|Thunderstorm|New|2024-02-01|2024-02-02';
        const oldKey = 'trek-001|Thunderstorm|Old|2024-01-01|2024-01-02';

        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking()]);
        when(mockApi.weatherbitAlerts(any, any))
            .thenAnswer((_) async => [alertNew, alertOld]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        when(mockMemory.hasShownWeatherAlertKey(newKey))
            .thenAnswer((_) async => false);
        when(mockMemory.hasShownWeatherAlertKey(oldKey))
            .thenAnswer((_) async => true);
        when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
        when(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => {});

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        )).called(1);
        verify(mockMemory.addShownWeatherAlertKey(newKey)).called(1);
        verifyNever(mockMemory.addShownWeatherAlertKey(oldKey));
      });
    });

    group('alert key', () {
      test('la chiave è costruita nel formato trekkingId|event|headline|start|end', () async {
        const expectedKey = 'trek-X|Ice|Ice warning|2024-03-01|2024-03-02';

        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async =>
                [fakeTrekking(documentId: 'trek-X')]);
        when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async =>
            [fakeAlert(event: 'Ice', headline: 'Ice warning', start: '2024-03-01', end: '2024-03-02')]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockMemory.hasShownWeatherAlertKey(expectedKey)).called(1);
        verify(mockMemory.addShownWeatherAlertKey(expectedKey)).called(1);
      });

      test("l'id notifica è l'hashCode della chiave", () async {
        const key = 'trek-Y|Fog|Dense fog|2024-04-01|2024-04-02';

        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async =>
                [fakeTrekking(documentId: 'trek-Y')]);
        when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async =>
            [fakeAlert(event: 'Fog', headline: 'Dense fog', start: '2024-04-01', end: '2024-04-02')]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: key.hashCode,
          title: anyNamed('title'),
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('mock alerts', () {
      test('combina alert reali e mock', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [fakeTrekking()]);
        when(mockApi.weatherbitAlerts(any, any))
            .thenAnswer((_) async => [fakeAlert(event: 'Wind', headline: 'h1')]);
        when(mockApi.mockAlerts())
            .thenAnswer((_) async => [fakeAlert(event: 'Snow', headline: 'h2')]);
        stubNotificationAndMemory();

        await runLogic();

        verify(mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        )).called(2);
      });
    });

    group('più trekkings', () {
      test('chiama le API per ogni trekking', () async {
        when(mockTrekkingController.getWeatherAlertTrekkings())
            .thenAnswer((_) async => [
                  fakeTrekking(documentId: 'A', startingPoint: const LatLng(45.0, 9.0)),
                  fakeTrekking(documentId: 'B', startingPoint: const LatLng(46.0, 10.0)),
                ]);
        when(mockApi.weatherbitAlerts(45.0, 9.0)).thenAnswer((_) async => []);
        when(mockApi.weatherbitAlerts(46.0, 10.0)).thenAnswer((_) async => []);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);

        await runLogic();

        verify(mockApi.weatherbitAlerts(45.0, 9.0)).called(1);
        verify(mockApi.weatherbitAlerts(46.0, 10.0)).called(1);
      });
    });
  });

  group('BackgroundService', () {
    testWidgets('start() registra il lifecycle observer e chiama _run()', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      service.start();
      await tester.pump();

      verify(mockTrekkingController.getWeatherAlertTrekkings()).called(greaterThanOrEqualTo(1));

      service.dispose();
    });

    testWidgets('dispose() cancella il timer senza errori', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      service.start();
      await tester.pump();

      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('dispose() prima di start() non lancia eccezioni', (tester) async {
      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('didChangeAppLifecycleState resumed chiama _run()', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      service.start();
      await tester.pump();

      clearInteractions(mockTrekkingController);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      verify(mockTrekkingController.getWeatherAlertTrekkings())
          .called(greaterThanOrEqualTo(1));

      service.dispose();
    });

    testWidgets('didChangeAppLifecycleState paused NON chiama _run()', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      service.start();
      await tester.pump();

      clearInteractions(mockTrekkingController);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();

      verifyNever(mockTrekkingController.getWeatherAlertTrekkings());

      service.dispose();
    });

    testWidgets('_run() non esegue se già in esecuzione (_running guard)', (tester) async {
      var callCount = 0;
      when(mockTrekkingController.getWeatherAlertTrekkings()).thenAnswer((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      service.start();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await tester.pump(const Duration(milliseconds: 200));

      expect(callCount, 1);

      service.dispose();
    });

    testWidgets('_run() gestisce eccezioni senza crashare', (tester) async {
      when(mockTrekkingController.getWeatherAlertTrekkings())
          .thenThrow(Exception('Firestore error'));

      late BackgroundService service;

      await tester.pumpWidget(buildProviderTree(
        trekkingController: mockTrekkingController,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: Builder(builder: (ctx) {
          service = BackgroundService(ctx);
          return const SizedBox();
        }),
      ));

      expect(() async {
        service.start();
        await tester.pump();
      }, returnsNormally);

      service.dispose();
    });
  });
}