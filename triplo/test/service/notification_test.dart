import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/service/notification.dart';

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
}