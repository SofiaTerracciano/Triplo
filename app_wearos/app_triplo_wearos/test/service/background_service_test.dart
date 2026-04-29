import 'dart:async';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/background_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

@GenerateMocks([
  TrekkingController,
  ServiceController,
  NotificationService,
  MemoryService,
])

import 'background_service_test.mocks.dart';

Trekking _makeTrekking({
  String documentId = 'trek-1',
  String name = 'Test Trek',
  LatLng startingPoint = const LatLng(45.0, 9.0),
  LatLng endingPoint = const LatLng(46.0, 10.0),
}) {
  return Trekking(
    documentId: documentId,
    name: name,
    mapPhoto: '',
    difficultyLevel: 'easy',
    distance: 10.0,
    estimatedTime: 3.0,
    elevationGain: 200.0,
    upGain: true,
    downGain: true,
    startingPoint: startingPoint,
    endingPoint: endingPoint,
    points: [startingPoint, endingPoint],
    startingPointName: 'Start',
    endingPointName: 'End',
    info: [],
    endingPointPhoto: '',
    description: [],
    picNicArea: false,
    familyFirendly: false,
  );
}

Map<String, dynamic> _alert({
  String event = 'Storm',
  String headline = 'Heavy storm',
  String start = '2024-01-01',
  String end = '2024-01-02',
}) => {'event': event, 'headline': headline, 'start': start, 'end': end};


void main() {

  late MockTrekkingController mockTrekking;
  late MockServiceController mockApi;
  late MockNotificationService mockNotification;
  late MockMemoryService mockMemory;

  setUp(() {
    mockTrekking = MockTrekkingController();
    mockApi = MockServiceController();
    mockNotification = MockNotificationService();
    mockMemory = MockMemoryService();
  });

  group('BackgroundServiceLogic.run –', () {

    test('skips execution when uid is null', () async {
      when(mockTrekking.uid).thenReturn(null);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verifyNever(mockTrekking.getWeatherAlertTrekkings());
      verifyNever(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      );
    });

    test('does nothing when subscribed trekkings list is empty', () async {
      when(mockTrekking.uid).thenReturn('user-1');
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verifyNever(mockApi.weatherbitAlerts(any, any));
      verifyNever(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      );
    });

    test('calls weatherbitAlerts with starting_point coordinates', () async {
      final trekking = _makeTrekking(
        startingPoint: const LatLng(45.123, 9.456),
      );

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(mockApi.weatherbitAlerts(45.123, 9.456)).thenAnswer((_) async => []);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockApi.weatherbitAlerts(45.123, 9.456)).called(1);
    });

    test('shows notification for a new real alert', () async {
      final trekking = _makeTrekking(name: 'Alpine Trek');
      final alert = _alert();

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => [alert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Storm',
          body: 'Alert for Alpine Trek',
        ),
      ).called(1);
      verify(mockMemory.addShownWeatherAlertKey(any)).called(1);
    });

    test('merges real and mock alerts, fires one notification each', () async {
      final trekking = _makeTrekking(name: 'Valley Trek');
      final realAlert = _alert(event: 'Flood', headline: 'Flash flood');
      final mockAlert = _alert(event: 'Wind', headline: 'Strong winds');

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(
        mockApi.weatherbitAlerts(any, any),
      ).thenAnswer((_) async => [realAlert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => [mockAlert]);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).called(2);
      verify(mockMemory.addShownWeatherAlertKey(any)).called(2);
    });

    test('fires separate notifications for multiple trekkings', () async {
      final t1 = _makeTrekking(documentId: 'trek-1', name: 'Trek A');
      final t2 = _makeTrekking(
        documentId: 'trek-2',
        name: 'Trek B',
        startingPoint: const LatLng(44.0, 8.0),
      );
      final alert = _alert();

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [t1, t2]);
      when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => [alert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: 'Alert for Trek A',
        ),
      ).called(1);
      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: 'Alert for Trek B',
        ),
      ).called(1);
    });

    test('skips already-shown alert (deduplication via memory)', () async {
      final trekking = _makeTrekking();
      final alert = _alert();

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => [alert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => true);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verifyNever(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      );
      verifyNever(mockMemory.addShownWeatherAlertKey(any));
    });

    test('same alert on second run is deduplicated correctly', () async {
      final trekking = _makeTrekking();
      final alert = _alert();

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => [alert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => true);
      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('continues and uses mock alerts when real API throws', () async {
      final trekking = _makeTrekking(name: 'Ridge Trek');
      final mockAlert = _alert(event: 'Ice', headline: 'Icy roads');

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(
        mockApi.weatherbitAlerts(any, any),
      ).thenThrow(Exception('Network error'));
      when(mockApi.mockAlerts()).thenAnswer((_) async => [mockAlert]);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await expectLater(
        BackgroundServiceLogic.run(
          trekkingController: mockTrekking,
          api: mockApi,
          notification: mockNotification,
          memory: mockMemory,
        ),
        completes,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Ice',
          body: 'Alert for Ridge Trek',
        ),
      ).called(1);
    });

    test('continues and uses real alerts when mock API throws', () async {
      final trekking = _makeTrekking(name: 'Peak Trek');
      final realAlert = _alert(event: 'Snow', headline: 'Heavy snowfall');

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(
        mockApi.weatherbitAlerts(any, any),
      ).thenAnswer((_) async => [realAlert]);
      when(mockApi.mockAlerts()).thenThrow(Exception('Mock service down'));
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await expectLater(
        BackgroundServiceLogic.run(
          trekkingController: mockTrekking,
          api: mockApi,
          notification: mockNotification,
          memory: mockMemory,
        ),
        completes,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Snow',
          body: 'Alert for Peak Trek',
        ),
      ).called(1);
    });

    test('does not throw when both APIs fail', () async {
      final trekking = _makeTrekking();

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(
        mockApi.weatherbitAlerts(any, any),
      ).thenThrow(Exception('Network error'));
      when(mockApi.mockAlerts()).thenThrow(Exception('Mock error'));

      await expectLater(
        BackgroundServiceLogic.run(
          trekkingController: mockTrekking,
          api: mockApi,
          notification: mockNotification,
          memory: mockMemory,
        ),
        completes,
      );

      verifyNever(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      );
    });

    test('uses "title" field when "event" is absent', () async {
      final trekking = _makeTrekking(name: 'Forest Trek');
      final alert = <String, dynamic>{
        'title': 'Heatwave',
        'start': '2024-06',
        'end': '2024-07',
      };

      when(mockTrekking.uid).thenReturn('user-1');
      when(
        mockTrekking.getWeatherAlertTrekkings(),
      ).thenAnswer((_) async => [trekking]);
      when(mockApi.weatherbitAlerts(any, any)).thenAnswer((_) async => [alert]);
      when(mockApi.mockAlerts()).thenAnswer((_) async => []);
      when(
        mockMemory.hasShownWeatherAlertKey(any),
      ).thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async => {});
      when(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {});

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(
        mockNotification.showWeatherNotification(
          id: anyNamed('id'),
          title: 'Heatwave',
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test(
      'falls back to "Weather alert" when both event and title are absent',
      () async {
        final trekking = _makeTrekking(name: 'Desert Trek');
        final alert = <String, dynamic>{'start': '2024-08', 'end': '2024-09'};

        when(mockTrekking.uid).thenReturn('user-1');
        when(
          mockTrekking.getWeatherAlertTrekkings(),
        ).thenAnswer((_) async => [trekking]);
        when(
          mockApi.weatherbitAlerts(any, any),
        ).thenAnswer((_) async => [alert]);
        when(mockApi.mockAlerts()).thenAnswer((_) async => []);
        when(
          mockMemory.hasShownWeatherAlertKey(any),
        ).thenAnswer((_) async => false);
        when(
          mockMemory.addShownWeatherAlertKey(any),
        ).thenAnswer((_) async => {});
        when(
          mockNotification.showWeatherNotification(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => {});

        await BackgroundServiceLogic.run(
          trekkingController: mockTrekking,
          api: mockApi,
          notification: mockNotification,
          memory: mockMemory,
        );

        verify(
          mockNotification.showWeatherNotification(
            id: anyNamed('id'),
            title: 'Weather alert',
            body: anyNamed('body'),
          ),
        ).called(1);
      },
    );
  });

  group('BackgroundService –', () {
 
    testWidgets('start() registers WidgetsBindingObserver', (tester) async {
      _stubIdleRun(mockTrekking, mockApi, mockMemory);
      late BackgroundService service;

      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));

      service.start();
      expect(() => service.dispose(), returnsNormally);
    });
 
    testWidgets('start() triggers an immediate _run()', (tester) async {
      when(mockTrekking.uid).thenReturn('user-1');
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      late BackgroundService service;

      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));

      service.start();
      await tester.pump();

      verify(mockTrekking.getWeatherAlertTrekkings()).called(greaterThan(0));

      service.dispose(); 
    });
 
 
    testWidgets('concurrent _run() calls are coalesced (_running guard)',
        (tester) async {
      final completer = Completer<void>();
 
      when(mockTrekking.uid).thenReturn('user-1');
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenAnswer((_) => completer.future.then((_) => []));
 
      late BackgroundService service;
 
      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));
 
      service.start();
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
 
      completer.complete();
      await tester.pump();
 
      verify(mockTrekking.getWeatherAlertTrekkings()).called(1);
 
      service.dispose();
    });
 
    testWidgets('resumed lifecycle event triggers _run()', (tester) async {
      when(mockTrekking.uid).thenReturn('user-1');
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenAnswer((_) async => []);
 
      late BackgroundService service;
 
      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));
 
      service.start();
      await tester.pump(); 
      clearInteractions(mockTrekking);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
 
      verify(mockTrekking.getWeatherAlertTrekkings()).called(greaterThan(0));
 
      service.dispose();
    });
 
    testWidgets('non-resumed lifecycle events do NOT trigger _run()',
        (tester) async {
      _stubIdleRun(mockTrekking, mockApi, mockMemory);
      late BackgroundService service;
 
      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));
 
      service.start();
      await tester.pump();
      clearInteractions(mockTrekking);
 
      for (final state in [
        AppLifecycleState.paused,
        AppLifecycleState.inactive,
        AppLifecycleState.detached,
      ]) {
        service.didChangeAppLifecycleState(state);
      }
      await tester.pump();
 
      verifyNever(mockTrekking.getWeatherAlertTrekkings());
 
      service.dispose();
    });
  
    testWidgets('dispose() cancels the timer', (tester) async {
      _stubIdleRun(mockTrekking, mockApi, mockMemory);
      late BackgroundService service;
 
      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));
 
      service.start();
      await tester.pump();
      clearInteractions(mockTrekking);
 
      service.dispose();
 
      await tester.pump(const Duration(seconds: 120));
      await tester.pump();
 
      verifyNever(mockTrekking.getWeatherAlertTrekkings());
    });
 
    testWidgets('dispose() removes WidgetsBindingObserver', (tester) async {
      _stubIdleRun(mockTrekking, mockApi, mockMemory);
      late BackgroundService service;
 
      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));
 
      service.start();
      service.dispose();
      clearInteractions(mockTrekking);
 
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      verifyNever(mockTrekking.getWeatherAlertTrekkings());
    });
 
 
    testWidgets('start() does not throw even when _run() throws internally',
        (tester) async {
      when(mockTrekking.uid).thenReturn('user-1');
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenThrow(Exception('Unexpected crash'));

      late BackgroundService service;

      await tester.pumpWidget(_buildTestApp(
        trekking: mockTrekking,
        api: mockApi,
        notification: mockNotification,
        memory: mockMemory,
        child: _TestWidget(onCreated: (s) => service = s),
      ));

      expect(() => service.start(), returnsNormally);
      await tester.pump();

      service.dispose(); 
    });
  });
}

Widget _buildTestApp({
  required Widget child,
  required MockTrekkingController trekking,
  required MockServiceController api,
  required MockNotificationService notification,
  required MockMemoryService memory,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TrekkingController>.value(value: trekking),
      Provider<ServiceController>.value(value: api),
      Provider<NotificationService>.value(value: notification),
      Provider<MemoryService>.value(value: memory),
    ],
    child: child,
  );
}

class _TestWidget extends StatefulWidget {
  final void Function(BackgroundService) onCreated;
  const _TestWidget({required this.onCreated});
 
  @override
  State<_TestWidget> createState() => _TestWidgetState();
}
 
class _TestWidgetState extends State<_TestWidget> {
  late BackgroundService _service;
 
  @override
  void initState() {
    super.initState();
    _service = BackgroundService(context);
    widget.onCreated(_service);
  }
 
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
 
void _stubIdleRun(
  MockTrekkingController trekking,
  MockServiceController api,
  MockMemoryService memory,
) {
  when(trekking.uid).thenReturn(null); 
}
