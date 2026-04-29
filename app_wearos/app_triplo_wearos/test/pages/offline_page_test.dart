// test/offline_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/pages/offline_page.dart';
import 'package:app_triplo_wearos/service/internetservice.dart';

@GenerateMocks([InternetService])
import 'offline_page_test.mocks.dart';

Widget _buildOfflinePage(MockInternetService internet) {
  return ChangeNotifierProvider<InternetService>.value(
    value: internet,
    child: const MaterialApp(home: OfflineWatchPage()),
  );
}

MockInternetService _mockInternet() {
  final m = MockInternetService();
  when(m.isOnline).thenReturn(false);
  when(m.addListener(any)).thenReturn(null);
  when(m.removeListener(any)).thenReturn(null);
  when(m.hasListeners).thenReturn(false);
  when(m.forceRecheck()).thenAnswer((_) async {});
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineWatchPage – struttura UI –', () {
    testWidgets('mostra icona wifi_off', (tester) async {
      await tester.pumpWidget(_buildOfflinePage(_mockInternet()));
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('mostra testo "Offline mode"', (tester) async {
      await tester.pumpWidget(_buildOfflinePage(_mockInternet()));
      expect(find.text('Offline mode'), findsOneWidget);
    });

    testWidgets('mostra messaggio di connessione non disponibile',
        (tester) async {
      await tester.pumpWidget(_buildOfflinePage(_mockInternet()));
      expect(
        find.text('Internet connection is not currently available.'),
        findsOneWidget,
      );
    });

    testWidgets('mostra il pulsante Retry', (tester) async {
      await tester.pumpWidget(_buildOfflinePage(_mockInternet()));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('lo scaffold ha sfondo nero', (tester) async {
      await tester.pumpWidget(_buildOfflinePage(_mockInternet()));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('OfflineWatchPage – interazione –', () {
    testWidgets('tap su Retry chiama forceRecheck', (tester) async {
      final internet = _mockInternet();
      await tester.pumpWidget(_buildOfflinePage(internet));

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(internet.forceRecheck()).called(1);
    });
  });
}