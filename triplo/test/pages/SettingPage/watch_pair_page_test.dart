import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/pages/SettingsPage/watch_pair_page.dart';
import 'setting_page_test.mocks.dart';

BarcodeCapture _makeCapture(String? rawValue) {
  final barcode = Barcode(rawValue: rawValue);
  return BarcodeCapture(barcodes: [barcode]);
}

BarcodeCapture _makeEmptyCapture() {
  return BarcodeCapture(barcodes: []);
}

@GenerateMocks([UserController])

void main() {
  group('WatchPairScannerPage – widget', () {
    late MockUserController mockUserController;

    setUp(() {
      mockUserController = MockUserController();
      when(mockUserController.addListener(any)).thenReturn(null);
      when(mockUserController.removeListener(any)).thenReturn(null);
    });

    Widget buildPage() => ChangeNotifierProvider<UserController>.value(
          value: mockUserController,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WatchPairScannerPage(),
          ),
        );

    testWidgets('mostra AppBar con titolo scan_qr_label', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WatchPairScannerPage)),
      )!;
      expect(find.text(local.scan_qr_label), findsOneWidget);
    });

    testWidgets('mostra MobileScanner nel body', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('non mostra errore inizialmente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(Material).evaluate().where((e) {
        final w = e.widget as Material;
        return w.color != null &&
            w.color!.red > 200 &&
            w.color!.green < 100;
      }), isEmpty);
    });

    testWidgets('contiene uno Stack nel body', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(Stack), findsWidgets);
    });
    testWidgets('QR valido mostra AlertDialog con watchId', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('watch-123'), findsOneWidget);
    });

    testWidgets('dialog conferma ha bottone Annulla e Conferma', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      expect(find.text(local.cancel_button_label), findsOneWidget);
      expect(find.text(local.confirm_label), findsOneWidget);
    });

    testWidgets('dialog mostra titolo connect_watch_label', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      expect(find.text(local.connect_watch_label), findsOneWidget);
    });

    testWidgets('tap Conferma chiama approveWatchPair', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );
      when(mockUserController.approveWatchPair(
        watchId: anyNamed('watchId'),
        token: anyNamed('token'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      await tester.tap(find.text(local.confirm_label));
      await tester.pumpAndSettle();

      verify(mockUserController.approveWatchPair(
        watchId: 'watch-123',
        token: 'token-abc',
      )).called(1);
    });

    testWidgets('tap Conferma chiude il dialog', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );
      when(mockUserController.approveWatchPair(
        watchId: anyNamed('watchId'),
        token: anyNamed('token'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      await tester.tap(find.text(local.confirm_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tap Annulla non chiama approveWatchPair', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      await tester.tap(find.text(local.cancel_button_label));
      await tester.pumpAndSettle();

      verifyNever(mockUserController.approveWatchPair(
        watchId: anyNamed('watchId'),
        token: anyNamed('token'),
      ));
    });

    testWidgets('tap Annulla chiude il dialog', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      await tester.tap(find.text(local.cancel_button_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('QR non valido mostra banner di errore', (tester) async {
      when(mockUserController.extractWatchPair(any))
          .thenThrow(Exception('formato non valido'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('invalid-qr'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WatchPairScannerPage)),
      )!;
      expect(find.textContaining(local.not_valid_qr_label), findsOneWidget);
    });

    testWidgets('QR non valido non mostra AlertDialog', (tester) async {
      when(mockUserController.extractWatchPair(any))
          .thenThrow(Exception('formato non valido'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('invalid-qr'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('errore in approveWatchPair mostra banner errore approvazione',
        (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );
      when(mockUserController.approveWatchPair(
        watchId: anyNamed('watchId'),
        token: anyNamed('token'),
      )).thenThrow(Exception('server error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(WatchPairScannerPage)),
      )!;
      await tester.tap(find.text(local.confirm_label));
      await tester.pumpAndSettle();

      expect(find.textContaining('Errore approvazione'), findsOneWidget);
    });

    testWidgets('capture senza barcodes non mostra dialog né errore',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeEmptyCapture());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockUserController.extractWatchPair(any));
    });

    testWidgets('rawValue null non mostra dialog né errore', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture(null));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockUserController.extractWatchPair(any));
    });

    testWidgets('rawValue vuoto non mostra dialog né errore', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('   '));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockUserController.extractWatchPair(any));
    });

    testWidgets('secondo scan ignorato mentre dialog è aperto', (tester) async {
      when(mockUserController.extractWatchPair(any)).thenReturn(
        (watchId: 'watch-123', token: 'token-abc'),
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      scanner.onDetect!(_makeCapture('valid-qr-payload'));
      await tester.pumpAndSettle();

      verify(mockUserController.extractWatchPair(any)).called(1);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}