import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';


@GenerateMocks([AppLocalizations])
import 'notification_test.mocks.dart';

class _FakeCall {
  final int id;
  final String title;
  final String body;
  final String payload;
  final String channelId;
  final String channelName;

  _FakeCall({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.channelId,
    required this.channelName,
  });
}

class TestableNotificationService extends NotificationService {
  final List<_FakeCall> calls = [];

  @override
  Future<void> showTrekkingNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String channelId = 'notifications_channel',
    String channelName = 'Notifications',
  }) async {
    calls.add(_FakeCall(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: channelId,
      channelName: channelName,
    ));
  }
}

class _TestableTapService extends NotificationService {
  final List<_FakeCall> calls = [];

  @override
  Future<void> showTrekkingNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String channelId = 'notifications_channel',
    String channelName = 'Notifications',
  }) async {
    calls.add(_FakeCall(
      id: id, title: title, body: body,
      payload: payload, channelId: channelId, channelName: channelName,
    ));
  }
}

MockAppLocalizations _mockLocal() {
  final local = MockAppLocalizations();
  when(local.title_challenge_balance).thenReturn('Balance title');
  when(local.body_challenge_balance).thenReturn('Balance body');
  when(local.alert_challenge_balance).thenReturn('Balance alert');
  when(local.title_challenge_hi).thenReturn('Hi title');
  when(local.body_challenge_hi).thenReturn('Hi body');
  when(local.alert_challenge_hi).thenReturn('Hi alert');
  when(local.title_challenge_mini_orientiring).thenReturn('Orientiring title');
  when(local.body_challenge_mini_orientiring).thenReturn('Orientiring body');
  when(local.alert_challenge_mini_orientiring).thenReturn('Orientiring alert');
  when(local.title_challenge_photo).thenReturn('Photo title');
  when(local.body_challenge_photo).thenReturn('Photo body');
  when(local.alert_challenge_photo).thenReturn('Photo alert');
  when(local.title_challenge_silent_walking).thenReturn('Silent title');
  when(local.body_challenge_silent_walking).thenReturn('Silent body');
  when(local.alert_challenge_silent_walking).thenReturn('Silent alert');
  when(local.title_challenge_time).thenReturn('Time title');
  when(local.body_challenge_time).thenReturn('Time body');
  when(local.alert_challenge_time).thenReturn('Time alert');
  when(local.title_notification_arrival).thenReturn('Arrival title');
  when(local.body_notification_arrival).thenReturn('Arrival body');
  when(local.alert_notification_arrival).thenReturn('Arrival alert');
  return local;
}

void main() {
  group('notificationcontent –', () {
    late MockAppLocalizations local;

    setUp(() => local = _mockLocal());

    test('balance payload returns correct map', () {
      final r = notificationcontent('balance', local);
      expect(r['title'], 'Balance title');
      expect(r['body'], 'Balance body');
      expect(r['alert'], 'Balance alert');
    });

    test('hi payload returns correct map', () {
      final r = notificationcontent('hi', local);
      expect(r['title'], 'Hi title');
      expect(r['body'], 'Hi body');
      expect(r['alert'], 'Hi alert');
    });

    test('mini_orientiring payload returns correct map', () {
      final r = notificationcontent('mini_orientiring', local);
      expect(r['title'], 'Orientiring title');
      expect(r['body'], 'Orientiring body');
      expect(r['alert'], 'Orientiring alert');
    });

    test('photo payload returns correct map', () {
      final r = notificationcontent('photo', local);
      expect(r['title'], 'Photo title');
      expect(r['body'], 'Photo body');
      expect(r['alert'], 'Photo alert');
    });

    test('silent_walking payload returns correct map', () {
      final r = notificationcontent('silent_walking', local);
      expect(r['title'], 'Silent title');
      expect(r['body'], 'Silent body');
      expect(r['alert'], 'Silent alert');
    });

    test('time payload returns correct map', () {
      final r = notificationcontent('time', local);
      expect(r['title'], 'Time title');
      expect(r['body'], 'Time body');
      expect(r['alert'], 'Time alert');
    });

    test('end_trekking_arrival payload returns correct map', () {
      final r = notificationcontent('end_trekking_arrival', local);
      expect(r['title'], 'Arrival title');
      expect(r['body'], 'Arrival body');
      expect(r['alert'], 'Arrival alert');
    });

    test('weather_alert payload returns hardcoded strings', () {
      final r = notificationcontent('weather_alert', local);
      expect(r['title'], 'Weather alert');
      expect(r['body'], isNotEmpty);
      expect(r['alert'], isNotEmpty);
    });

    test('unknown payload returns empty title and body', () {
      final r = notificationcontent('unknown_payload', local);
      expect(r['title'], '');
      expect(r['body'], '');
      expect(r['alert'], isNull);
    });

    test('empty string payload returns empty title and body', () {
      final r = notificationcontent('', local);
      expect(r['title'], '');
      expect(r['body'], '');
    });
  });

  group('NotificationService – showTrekkingNotification –', () {
    late TestableNotificationService svc;

    setUp(() => svc = TestableNotificationService());

    test('records call with correct parameters', () async {
      await svc.showTrekkingNotification(
        id: 1,
        title: 'Test title',
        body: 'Test body',
        payload: 'balance',
      );

      expect(svc.calls, hasLength(1));
      expect(svc.calls.first.id, 1);
      expect(svc.calls.first.title, 'Test title');
      expect(svc.calls.first.body, 'Test body');
      expect(svc.calls.first.payload, 'balance');
      expect(svc.calls.first.channelId, 'notifications_channel');
      expect(svc.calls.first.channelName, 'Notifications');
    });

    test('uses custom channelId and channelName when provided', () async {
      await svc.showTrekkingNotification(
        id: 2,
        title: 'T',
        body: 'B',
        payload: 'hi',
        channelId: 'custom_channel',
        channelName: 'Custom',
      );

      expect(svc.calls.first.channelId, 'custom_channel');
      expect(svc.calls.first.channelName, 'Custom');
    });

    test('multiple calls are all recorded', () async {
      await svc.showTrekkingNotification(
          id: 1, title: 'A', body: 'B', payload: 'p1');
      await svc.showTrekkingNotification(
          id: 2, title: 'C', body: 'D', payload: 'p2');

      expect(svc.calls, hasLength(2));
      expect(svc.calls[0].id, 1);
      expect(svc.calls[1].id, 2);
    });
  });
  group('NotificationService – showWeatherNotification –', () {
    late TestableNotificationService svc;

    setUp(() => svc = TestableNotificationService());

    test('delegates to showTrekkingNotification with weather channel', () async {
      await svc.showWeatherNotification(
        id: 10,
        title: 'Storm warning',
        body: 'Heavy rain expected',
      );

      expect(svc.calls, hasLength(1));
      expect(svc.calls.first.id, 10);
      expect(svc.calls.first.title, 'Storm warning');
      expect(svc.calls.first.body, 'Heavy rain expected');
      expect(svc.calls.first.payload, 'weather_alert');
      expect(svc.calls.first.channelId, 'weather_alerts_channel');
      expect(svc.calls.first.channelName, 'Weather Alerts');
    });

    test('uses custom payload when provided', () async {
      await svc.showWeatherNotification(
        id: 11,
        title: 'Wind',
        body: 'Strong winds',
        payload: 'custom_weather',
      );

      expect(svc.calls.first.payload, 'custom_weather');
    });
  });
  group('NotificationService – setNavKey –', () {
    test('setNavKey stores the key without throwing', () {
      final svc = NotificationService();
      final key = GlobalKey<NavigatorState>();
      expect(() => svc.setNavKey(key), returnsNormally);
    });
  });

  // Aggiungere questo import in cima al file
  // ─── Sostituire il group 'NotificationService – init –' con questo ───────────

  group('NotificationService – init –', () {
    // Registra un handler fake per il MethodChannel usato dal plugin
    // così il plugin non cerca un'implementazione di piattaforma reale.
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall call) async {
          // 'initialize' deve restituire true per simulare successo
          if (call.method == 'initialize') return true;
          return null;
        },
      );
    });

    tearDown(() {
      // Pulisce l'handler dopo ogni test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    testWidgets('plugin getter returns the internal instance',
        (WidgetTester tester) async {
      final svc = NotificationService();
      expect(svc.plugin, isNotNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────

  group('NotificationService – _handleNotificationTap via widget –', () {
    // Questi test montano un albero Flutter reale così _navKey?.currentContext
    // non è null e il codice percorre il ramo "happy path".

    testWidgets('shows dialog with correct title and body for balance payload',
        (WidgetTester tester) async {
      final svc = NotificationService();
      final navKey = GlobalKey<NavigatorState>();
      svc.setNavKey(navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      // Simula il tap sulla notifica "balance"
      svc.handleNotificationTapForTest('balance');
      await tester.pumpAndSettle();

      // Il dialog deve essere visibile
      expect(find.byType(Dialog), findsOneWidget);

      // Il titolo localizzato deve comparire
      final context = navKey.currentContext!;
      final local = AppLocalizations.of(context)!;
      expect(find.text(local.title_challenge_balance), findsOneWidget);
    });

    testWidgets('dialog shows alert text when alert is non-empty',
        (WidgetTester tester) async {
      final svc = NotificationService();
      final navKey = GlobalKey<NavigatorState>();
      svc.setNavKey(navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      svc.handleNotificationTapForTest('hi');
      await tester.pumpAndSettle();

      final context = navKey.currentContext!;
      final local = AppLocalizations.of(context)!;
      // Quando alert è non-empty, deve mostrare alert (non body)
      expect(find.text(local.alert_challenge_hi), findsOneWidget);
      expect(find.text(local.body_challenge_hi), findsNothing);
    });

    testWidgets('OK button dismisses the dialog', (WidgetTester tester) async {
      final svc = NotificationService();
      final navKey = GlobalKey<NavigatorState>();
      svc.setNavKey(navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      svc.handleNotificationTapForTest('photo');
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('tapping outside dialog (barrierDismissible) closes it',
        (WidgetTester tester) async {
      final svc = NotificationService();
      final navKey = GlobalKey<NavigatorState>();
      svc.setNavKey(navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      svc.handleNotificationTapForTest('time');
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      // Tap fuori dalla dialog (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('does nothing when navKey has no context (navKey not attached)',
        (WidgetTester tester) async {
      final svc = NotificationService();
      final detachedKey = GlobalKey<NavigatorState>();
      svc.setNavKey(detachedKey);

      // Nessun MaterialApp montato → currentContext == null
      // Non deve lanciare eccezioni
      expect(
        () => svc.handleNotificationTapForTest('balance'),
        returnsNormally,
      );
    });

    test('does nothing when setNavKey was never called', () {
      final svc = NotificationService();
      // _navKey è null → early return senza crash
      expect(
        () => svc.handleNotificationTapForTest('balance'),
        returnsNormally,
      );
    });
  });
}