import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/SettingsPage/paired_watches_page.dart';

// Genera il mock SOLO per questo file, indipendente da home_page_test.dart
@GenerateMocks([UserController])
import 'paired_watches_page_test.mocks.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _watch({
  String watchId = 'watch-1',
  String status = 'approved',
  String platform = 'wearos',
  bool remoteLogout = false,
}) =>
    {
      'watchId': watchId,
      'status': status,
      'platform': platform,
      'remoteLogoutAt': remoteLogout ? 'someTimestamp' : null,
    };

// ─── Setup ────────────────────────────────────────────────────────────────────

void main() {
  late MockUserController mockCtrl;

  setUp(() {
    mockCtrl = MockUserController();
    // UserController estende ChangeNotifier: il mock deve rispondere
    // a addListener/removeListener senza fare nulla.
    when(mockCtrl.addListener(any)).thenReturn(null);
    when(mockCtrl.removeListener(any)).thenReturn(null);
    when(mockCtrl.hasListeners).thenReturn(false);
  });

  Widget buildPage() => ChangeNotifierProvider<UserController>.value(
        value: mockCtrl,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: PairedWatchesPage(),
        ),
      );

  // ── AppBar ────────────────────────────────────────────────────────────────

  group('AppBar', () {
    testWidgets('mostra titolo "Connected watches"', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Connected watches'), findsOneWidget);
    });

    testWidgets('mostra icona refresh', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tap refresh richiama getConnectedWatches di nuovo',
        (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      verify(mockCtrl.getConnectedWatches()).called(greaterThanOrEqualTo(2));
    });
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  group('Loading state', () {
    testWidgets('mostra CircularProgressIndicator durante il caricamento',
        (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('CircularProgressIndicator scompare dopo il caricamento',
        (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ── Error state ───────────────────────────────────────────────────────────

  group('Error state', () {
    testWidgets('mostra messaggio di errore se Future lancia eccezione',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => throw Exception('network error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Error loading connected watches'),
        findsOneWidget,
      );
    });

    testWidgets("messaggio errore contiene il testo dell'eccezione",
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => throw Exception('timeout'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('timeout'), findsOneWidget);
    });

    testWidgets('errore non mostra ListView', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => throw Exception('error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('errore non mostra CircularProgressIndicator', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => throw Exception('error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  group('Empty state', () {
    testWidgets('mostra "No connected watches found."', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No connected watches found.'), findsOneWidget);
    });

    testWidgets('lista vuota non mostra ListView', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('lista vuota non mostra Card', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });
  });

  // ── Watch list ────────────────────────────────────────────────────────────

  group('Watch list', () {
    testWidgets('con orologi mostra ListView', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch()]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('mostra watchId nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(watchId: 'abc-123')]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('abc-123'), findsOneWidget);
    });

    testWidgets('mostra label "Watch ID" nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch()]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Watch ID'), findsOneWidget);
    });

    testWidgets('mostra status nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(status: 'approved')]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('approved'), findsOneWidget);
    });

    testWidgets('mostra label "Status" nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch()]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Status'), findsOneWidget);
    });

    testWidgets('mostra platform nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(platform: 'wearos')]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('wearos'), findsOneWidget);
    });

    testWidgets('mostra label "Platform" nella card', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch()]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Platform'), findsOneWidget);
    });

    testWidgets(
        'mostra "Remote logout: disabled" quando remoteLogoutAt è null',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('disabled'), findsOneWidget);
    });

    testWidgets(
        'mostra "Remote logout: enabled" quando remoteLogoutAt non è null',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('enabled'), findsOneWidget);
    });

    testWidgets('mostra tante Card quanti sono gli orologi', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            _watch(watchId: 'w1'),
            _watch(watchId: 'w2'),
            _watch(watchId: 'w3'),
          ]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('ogni card mostra entrambi i bottoni', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch()]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
        findsOneWidget,
      );
    });

    testWidgets('watchId null → mostra "Watch ID: -"', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            {
              'watchId': null,
              'status': 'waiting',
              'platform': 'wearos',
              'remoteLogoutAt': null,
            },
          ]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Watch ID: -'), findsOneWidget);
    });

    testWidgets('status null → mostra "Status: -"', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            {
              'watchId': 'w1',
              'status': null,
              'platform': 'wearos',
              'remoteLogoutAt': null,
            },
          ]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: -'), findsOneWidget);
    });

    testWidgets('platform null → mostra "Platform: -"', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            {
              'watchId': 'w1',
              'status': 'approved',
              'platform': null,
              'remoteLogoutAt': null,
            },
          ]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Platform: -'), findsOneWidget);
    });
  });

  // ── Enable remote logout ──────────────────────────────────────────────────

  group('Enable remote logout', () {
    testWidgets(
        'bottone abilitato quando remoteLogout è false',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets(
        'bottone disabilitato quando remoteLogout è true',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('tap chiama enableRemoteLogoutForWatch con id corretto',
        (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer(
          (_) async => [_watch(watchId: 'w1', remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch('w1'))
          .thenAnswer((_) async {});
      // stub per il reload dopo successo
      when(mockCtrl.getConnectedWatches()).thenAnswer(
          (_) async => [_watch(watchId: 'w1', remoteLogout: false)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.enableRemoteLogoutForWatch('w1')).called(1);
    });

    testWidgets('tap successo mostra SnackBar "Remote logout enabled."',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      expect(find.text('Remote logout enabled.'), findsOneWidget);
    });

    testWidgets('tap errore mostra SnackBar con testo di errore',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenThrow(Exception('server down'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error enabling remote logout'), findsOneWidget);
    });

    testWidgets('tap errore la SnackBar contiene il messaggio eccezione',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenThrow(Exception('timeout'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      expect(find.textContaining('timeout'), findsOneWidget);
    });

    testWidgets('tap successo ricarica la lista', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.getConnectedWatches()).called(greaterThanOrEqualTo(2));
    });

    testWidgets('tap errore NON ricarica la lista', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenThrow(Exception('fail'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      clearInteractions(mockCtrl);

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      verifyNever(mockCtrl.getConnectedWatches());
    });
  });

  // ── Disable remote logout ─────────────────────────────────────────────────

  group('Disable remote logout', () {
    testWidgets(
        'bottone abilitato quando remoteLogout è true',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets(
        'bottone disabilitato quando remoteLogout è false',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('tap chiama clearRemoteLogoutForWatch con id corretto',
        (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer(
          (_) async => [_watch(watchId: 'w1', remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch('w1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.clearRemoteLogoutForWatch('w1')).called(1);
    });

    testWidgets('tap successo mostra SnackBar "Remote logout cleared."',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      expect(find.text('Remote logout cleared.'), findsOneWidget);
    });

    testWidgets('tap errore mostra SnackBar con testo di errore',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenThrow(Exception('network failure'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Error disabling remote logout'), findsOneWidget);
    });

    testWidgets('tap errore la SnackBar contiene il messaggio eccezione',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenThrow(Exception('db error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      expect(find.textContaining('db error'), findsOneWidget);
    });

    testWidgets('tap successo ricarica la lista', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.getConnectedWatches()).called(greaterThanOrEqualTo(2));
    });

    testWidgets('tap errore NON ricarica la lista', (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenThrow(Exception('fail'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      clearInteractions(mockCtrl);

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      verifyNever(mockCtrl.getConnectedWatches());
    });
  });

  // ── Stato bottoni dopo operazione ─────────────────────────────────────────

  group('Stato bottoni dopo operazione', () {
    testWidgets('dopo enable successo i bottoni si invertono', (tester) async {
      int call = 0;
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async {
        call++;
        return [_watch(remoteLogout: call > 1)];
      });
      when(mockCtrl.enableRemoteLogoutForWatch(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      final enableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      final disableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(enableBtn.onPressed, isNull);
      expect(disableBtn.onPressed, isNotNull);
    });

    testWidgets('dopo disable successo i bottoni si invertono', (tester) async {
      int call = 0;
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async {
        call++;
        return [_watch(remoteLogout: call == 1)];
      });
      when(mockCtrl.clearRemoteLogoutForWatch(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      final enableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      final disableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(enableBtn.onPressed, isNotNull);
      expect(disableBtn.onPressed, isNull);
    });

    testWidgets('dopo enable errore i bottoni rimangono invariati',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: false)]);
      when(mockCtrl.enableRemoteLogoutForWatch(any))
          .thenThrow(Exception('fail'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      final enableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      final disableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(enableBtn.onPressed, isNotNull);
      expect(disableBtn.onPressed, isNull);
    });

    testWidgets('dopo disable errore i bottoni rimangono invariati',
        (tester) async {
      when(mockCtrl.getConnectedWatches())
          .thenAnswer((_) async => [_watch(remoteLogout: true)]);
      when(mockCtrl.clearRemoteLogoutForWatch(any))
          .thenThrow(Exception('fail'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      final enableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enable remote logout'),
      );
      final disableBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Disable remote logout'),
      );
      expect(enableBtn.onPressed, isNull);
      expect(disableBtn.onPressed, isNotNull);
    });
  });

  // ── Refresh button ────────────────────────────────────────────────────────

  group('Refresh button', () {
    testWidgets('tap refresh aggiorna la lista (vuota → con orologio)',
        (tester) async {
      int call = 0;
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async {
        call++;
        return call == 1 ? [] : [_watch(watchId: 'w1')];
      });

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No connected watches found.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets(
        'tap refresh mostra CircularProgressIndicator durante il fetch',
        (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      int call = 0;
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) {
        call++;
        if (call == 1) return Future.value([]);
        return completer.future;
      });

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  // ── Multiple watches ──────────────────────────────────────────────────────

  group('Multiple watches', () {
    testWidgets('ogni orologio mostra il proprio watchId', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            _watch(watchId: 'aaa'),
            _watch(watchId: 'bbb'),
          ]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('aaa'), findsOneWidget);
      expect(find.textContaining('bbb'), findsOneWidget);
    });

    testWidgets('tap enable passa il watchId corretto', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            _watch(watchId: 'target', remoteLogout: false),
          ]);
      when(mockCtrl.enableRemoteLogoutForWatch('target'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Enable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.enableRemoteLogoutForWatch('target')).called(1);
    });

    testWidgets('tap disable passa il watchId corretto', (tester) async {
      when(mockCtrl.getConnectedWatches()).thenAnswer((_) async => [
            _watch(watchId: 'target', remoteLogout: true),
          ]);
      when(mockCtrl.clearRemoteLogoutForWatch('target'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Disable remote logout'));
      await tester.pumpAndSettle();

      verify(mockCtrl.clearRemoteLogoutForWatch('target')).called(1);
    });
  });
}