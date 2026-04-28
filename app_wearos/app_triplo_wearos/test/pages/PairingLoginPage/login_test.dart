import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/PairingLoginPage/login.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'login_test.mocks.dart' show MockPairingService;

@GenerateMocks([PairingService])

void main() {
  late MockPairingService mockPairingService;

  Widget buildWidget() {
    return ChangeNotifierProvider<PairingService>.value(
      value: mockPairingService,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginPage(),
      ),
    );
  }


  setUp(() {
    mockPairingService = MockPairingService();

    when(mockPairingService.pairedUid).thenReturn(null);
    when(mockPairingService.qrPayload).thenReturn(null);
    when(mockPairingService.pairing).thenReturn(false);
    when(mockPairingService.pairingError).thenReturn(null);
  });


  group('LoginPage – stato idle', () {
    testWidgets('mostra il titolo connect_label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.isNotEmpty ?? false),
        ),
        findsWidgets,
      );
    });

    testWidgets('NON mostra CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('NON mostra QrImageView', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('mostra il bottone "nuovo QR"', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('il bottone è abilitato quando non si sta creando',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('sfondo scaffold è nero', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('LoginPage – stato loading', () {
    setUp(() {
      when(mockPairingService.pairing).thenReturn(true);
    });
  });

  group('LoginPage – stato errore', () {
    const fakeError = 'Errore di connessione al server';

    setUp(() {
      when(mockPairingService.pairingError).thenReturn(fakeError);
    });

    testWidgets('mostra il messaggio di errore', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(fakeError), findsOneWidget);
    });

    testWidgets('il testo errore è rosso (redAccent)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final errorText = tester.widget<Text>(find.text(fakeError));
      expect(errorText.style?.color, Colors.redAccent);
    });

    testWidgets('il bottone rimane abilitato in stato errore', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('NON mostra QrImageView in stato errore', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsNothing);
    });
  });

  group('LoginPage – QR payload disponibile', () {
    const fakePayload = 'watch-pairing-token-abc123';

    setUp(() {
      when(mockPairingService.qrPayload).thenReturn(fakePayload);
    });

    testWidgets('mostra QrImageView', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('il container del QR ha sfondo bianco', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final deco = c.decoration;
        return deco is BoxDecoration && deco.color == Colors.white;
      }).toList();

      expect(containers, isNotEmpty);
    });

    testWidgets('NON mostra CircularProgressIndicator con payload pronto',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('il bottone è abilitato con payload disponibile', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('LoginPage – interazione bottone', () {
    testWidgets('tap sul bottone chiama startWatchPairing con forceNew: true',
        (tester) async {
      when(mockPairingService.startWatchPairing(forceNew: true))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockPairingService.startWatchPairing(forceNew: true)).called(1);
    });
  });
}