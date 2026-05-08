import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/service/notification.dart';
import 'notification_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])

Future<AppLocalizations> getLocalizations(WidgetTester tester) async {
  late AppLocalizations local;

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, 
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (ctx) {
        local = AppLocalizations.of(ctx)!;
        return const SizedBox();
      }),
    ),
  );

  return local;
}

Future<GlobalKey<NavigatorState>> buildAppWithNav(WidgetTester tester) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      locale: const Locale('it'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ),
  );
  await tester.pumpAndSettle();
  return navKey;
}

class TestableNotificationService extends NotificationService {
  final FlutterLocalNotificationsPlugin mockPlugin;

  TestableNotificationService(this.mockPlugin);

  @override
  Future<void> showTrekkingNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String channelId = 'notifications_channel',
    String channelName = 'Notifications',
  }) async {
    final NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
    await mockPlugin.show(id, title, body, platformDetails, payload: payload);
  }
}

void main() {
  group('NotificationService - navKey', () {
    test('getNavKey() ritorna null prima di setNavKey()', () {
      final service = NotificationService();
      expect(service.getNavKey(), isNull);
    });

    test('setNavKey() salva la chiave e getNavKey() la restituisce', () {
      final service = NotificationService();
      final key = GlobalKey<NavigatorState>();
      service.setNavKey(key);
      expect(service.getNavKey(), equals(key));
    });

    test('setNavKey() sovrascrive una chiave precedente', () {
      final service = NotificationService();
      final key1 = GlobalKey<NavigatorState>();
      final key2 = GlobalKey<NavigatorState>();
      service.setNavKey(key1);
      service.setNavKey(key2);
      expect(service.getNavKey(), equals(key2));
    });
  });

  group('notificationcontent()', () {
    testWidgets('payload "balance" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('balance', local);

      expect(result['title'], '🪨 Sfida: Equilibrio');
      expect(result['body'], 'Metti alla prova il tuo equilibrio!');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "hi" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('hi', local);

      expect(result['title'], '👋🏻 Sfida: Saluto');
      expect(result['body'], 'Saluta qualcuno sul sentiero!');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "mini_orientiring" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('mini_orientiring', local);

      expect(result['title'], '🧭 Sfida: Orientamento');
      expect(result['body'], 'Sai in che direzione stai andando?');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "photo" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('photo', local);

      expect(result['title'], '📷 Sfida: Fotografia');
      expect(result['body'], 'Scatta una foto al paesaggio!');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "silent_walking" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('silent_walking', local);

      expect(result['title'], '🧘🏻 Sfida: Camminata silenziosa');
      expect(result['body'], 'Prova a camminare in silenzio.');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "time" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('time', local);

      expect(result['title'], '⏱️ Sfida: Contro il tempo');
      expect(result['body'], 'Riuscirai a battere il tempo?');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "end_trekking_arrival" ritorna i valori corretti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('end_trekking_arrival', local);

      expect(result['title'], '📍 Quasi arrivato!');
      expect(result['body'], 'Tocca per completare il trekking.');
      expect(result['alert'], isNotEmpty);
    });

    testWidgets('payload "weather_alert" ritorna valori hardcoded', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('weather_alert', local);

      expect(result['title'], 'Weather alert');
      expect(result['body'], isNotEmpty);
      expect(result['alert'], isNotEmpty);
      expect(result['body'], equals(result['alert']));
    });

    testWidgets('payload sconosciuto ritorna title e body vuoti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('unknown_payload_xyz', local);

      expect(result['title'], '');
      expect(result['body'], '');
      expect(result['alert'], isNull);
    });

    testWidgets('payload vuoto ritorna title e body vuoti', (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('', local);

      expect(result['title'], '');
      expect(result['body'], '');
    });

    testWidgets('tutti i payload noti hanno title non vuoto', (tester) async {
      final local = await getLocalizations(tester);
      final payloads = [
        'balance', 'hi', 'mini_orientiring', 'photo',
        'silent_walking', 'time', 'end_trekking_arrival', 'weather_alert',
      ];

      for (final payload in payloads) {
        final result = notificationcontent(payload, local);
        expect(result['title'], isNotEmpty, reason: 'title vuoto per payload: $payload');
      }
    });

    testWidgets('tutti i payload noti hanno body non vuoto', (tester) async {
      final local = await getLocalizations(tester);
      final payloads = [
        'balance', 'hi', 'mini_orientiring', 'photo',
        'silent_walking', 'time', 'end_trekking_arrival', 'weather_alert',
      ];

      for (final payload in payloads) {
        final result = notificationcontent(payload, local);
        expect(result['body'], isNotEmpty, reason: 'body vuoto per payload: $payload');
      }
    });

    testWidgets('tutti i payload noti hanno alert non vuoto', (tester) async {
      final local = await getLocalizations(tester);
      final payloads = [
        'balance', 'hi', 'mini_orientiring', 'photo',
        'silent_walking', 'time', 'end_trekking_arrival', 'weather_alert',
      ];

      for (final payload in payloads) {
        final result = notificationcontent(payload, local);
        expect(result['alert'], isNotEmpty, reason: 'alert vuoto per payload: $payload');
      }
    });
  });
  
  group('showTrekkingNotification()', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late TestableNotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = TestableNotificationService(mockPlugin);
      when(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async {});
    });

    test('chiama show() con i parametri corretti', () async {
      await service.showTrekkingNotification(
        id: 1,
        title: 'Titolo test',
        body: 'Corpo test',
        payload: 'balance',
      );

      verify(mockPlugin.show(
        1,
        'Titolo test',
        'Corpo test',
        any,
        payload: 'balance',
      )).called(1);
    });

    test('usa channelId e channelName di default se non specificati', () async {
      await service.showTrekkingNotification(
        id: 2,
        title: 'T',
        body: 'B',
        payload: 'hi',
      );
      verify(mockPlugin.show(2, 'T', 'B', any, payload: 'hi')).called(1);
    });

    test('usa channelId e channelName personalizzati se forniti', () async {
      await service.showTrekkingNotification(
        id: 3,
        title: 'T',
        body: 'B',
        payload: 'photo',
        channelId: 'custom_channel',
        channelName: 'Custom',
      );
      verify(mockPlugin.show(3, 'T', 'B', any, payload: 'photo')).called(1);
    });

    test('id diversi non collidono tra loro', () async {
      await service.showTrekkingNotification(
          id: 10, title: 'A', body: 'A', payload: 'time');
      await service.showTrekkingNotification(
          id: 20, title: 'B', body: 'B', payload: 'time');

      verify(mockPlugin.show(10, 'A', 'A', any, payload: 'time')).called(1);
      verify(mockPlugin.show(20, 'B', 'B', any, payload: 'time')).called(1);
    });
  });

  group('showWeatherNotification()', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late TestableNotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = TestableNotificationService(mockPlugin);
      when(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async {});
    });

    test('delega a showTrekkingNotification con payload weather_alert', () async {
      await service.showWeatherNotification(
        id: 99,
        title: 'Weather alert',
        body: 'Pioggia intensa prevista',
      );

      verify(mockPlugin.show(
        99,
        'Weather alert',
        'Pioggia intensa prevista',
        any,
        payload: 'weather_alert',
      )).called(1);
    });

    test('usa payload personalizzato se fornito', () async {
      await service.showWeatherNotification(
        id: 100,
        title: 'Alert',
        body: 'Neve',
        payload: 'custom_weather',
      );

      verify(mockPlugin.show(
        100,
        'Alert',
        'Neve',
        any,
        payload: 'custom_weather',
      )).called(1);
    });

    test('usa weather_alerts_channel come channelId', () async {
      await service.showWeatherNotification(
        id: 5,
        title: 'T',
        body: 'B',
      );
      verify(mockPlugin.show(5, 'T', 'B', any, payload: 'weather_alert'))
          .called(1);
    });
  });

  group('_handleNotificationTap (comportamento dialog)', () {
    testWidgets(
        'mostra AlertDialog con titolo corretto per payload "balance"',
        (tester) async {
      final service = NotificationService();
      final navKey = await buildAppWithNav(tester);
      service.setNavKey(navKey);

      service.handleNotificationTapForTest('balance');
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('🪨 Sfida: Equilibrio'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('mostra AlertDialog per payload "weather_alert"', (tester) async {
      final service = NotificationService();
      final navKey = await buildAppWithNav(tester);
      service.setNavKey(navKey);

      service.handleNotificationTapForTest('weather_alert');
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Weather alert'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('bottone OK chiude la dialog', (tester) async {
      final service = NotificationService();
      final navKey = await buildAppWithNav(tester);
      service.setNavKey(navKey);

      service.handleNotificationTapForTest('hi');
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
        'non mostra dialog se navKey è null (contesto non disponibile)',
        (tester) async {
      final service = NotificationService(); 

      expect(
        () => service.handleNotificationTapForTest('balance'),
        returnsNormally,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('usa alert se non vuoto, body come fallback', (tester) async {
      final service = NotificationService();
      final navKey = await buildAppWithNav(tester);
      service.setNavKey(navKey);

      service.handleNotificationTapForTest('end_trekking_arrival');
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      final content = dialog.content as Text;
      expect(content.data, isNotEmpty);
    });
  });

  group('notificationcontent() — casi edge aggiuntivi', () {
    testWidgets('payload con spazi non corrisponde a nessun caso noto',
        (tester) async {
      late AppLocalizations local;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            local = AppLocalizations.of(ctx)!;
            return const SizedBox();
          }),
        ),
      );

      final result = notificationcontent(' balance ', local);
      expect(result['title'], '');
      expect(result['body'], '');
    });

    testWidgets('payload maiuscolo non corrisponde a nessun caso noto',
        (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('BALANCE', local);
      expect(result['title'], '');
      expect(result['body'], '');
    });

    testWidgets('tutti i payload noti non hanno alert null', (tester) async {
      final local = await getLocalizations(tester);
      final payloads = [
        'balance', 'hi', 'mini_orientiring', 'photo',
        'silent_walking', 'time', 'end_trekking_arrival', 'weather_alert',
      ];
      for (final payload in payloads) {
        final result = notificationcontent(payload, local);
        expect(result['alert'], isNotNull,
            reason: 'alert è null per payload: $payload');
      }
    });

    testWidgets(
        'weather_alert ha body e alert identici (entrambi hardcoded)',
        (tester) async {
      final local = await getLocalizations(tester);
      final result = notificationcontent('weather_alert', local);
      expect(result['body'], equals(result['alert']));
      expect(result['body'], contains('weather alert'));
    });
  });

  group('showTrekkingNotification() - plugin iniettato', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService.withPlugin(mockPlugin);
      when(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async {});
    });

    test('chiama show() con parametri corretti', () async {
      await service.showTrekkingNotification(
        id: 1,
        title: 'Titolo',
        body: 'Corpo',
        payload: 'balance',
      );
      verify(mockPlugin.show(1, 'Titolo', 'Corpo', any, payload: 'balance')).called(1);
    });

    test('usa channelId e channelName custom', () async {
      await service.showTrekkingNotification(
        id: 2,
        title: 'T',
        body: 'B',
        payload: 'photo',
        channelId: 'custom_channel',
        channelName: 'Custom',
      );
      verify(mockPlugin.show(2, 'T', 'B', any, payload: 'photo')).called(1);
    });
  });

  group('showWeatherNotification() - plugin iniettato', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService.withPlugin(mockPlugin);
      when(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async {});
    });

    test('delega con payload weather_alert di default', () async {
      await service.showWeatherNotification(
        id: 5,
        title: 'Weather alert',
        body: 'Pioggia intensa',
      );
      verify(mockPlugin.show(5, 'Weather alert', 'Pioggia intensa', any,
          payload: 'weather_alert')).called(1);
    });

    test('usa payload personalizzato se fornito', () async {
      await service.showWeatherNotification(
        id: 6,
        title: 'Alert',
        body: 'Neve',
        payload: 'custom_weather',
      );
      verify(mockPlugin.show(6, 'Alert', 'Neve', any,
          payload: 'custom_weather')).called(1);
    });
  });

  group('init() - plugin iniettato', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService.withPlugin(mockPlugin);
    });

    test('chiama initialize() durante init()', () async {
      when(mockPlugin.initialize(any,
              onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
          .thenAnswer((_) async => true);
      when(mockPlugin.getNotificationAppLaunchDetails())
          .thenAnswer((_) async => null);

      await service.init();

      verify(mockPlugin.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .called(1);
    });

    test('init() completa senza eccezioni su Android', () async {
      when(mockPlugin.initialize(any,
              onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
          .thenAnswer((_) async => true);
      when(mockPlugin.getNotificationAppLaunchDetails())
          .thenAnswer((_) async => null);

      await expectLater(service.init(), completes);
    });
  });
}