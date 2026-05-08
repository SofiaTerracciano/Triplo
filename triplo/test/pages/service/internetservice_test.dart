import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/service/internetservice.dart';

import 'internetservice_test.mocks.dart' show MockServiceController;

@GenerateMocks([ServiceController])

InternetService makeService(
  MockServiceController mock, {
  Duration checkEvery = const Duration(milliseconds: 50),
  Duration offlineThreshold = const Duration(milliseconds: 80),
  Duration resumeGracePeriod = const Duration(milliseconds: 80),
}) {
  return InternetService(
    servicecontroller: mock,
    checkEvery: checkEvery,
    offlineThreshold: offlineThreshold,
    resumeGracePeriod: resumeGracePeriod,
  );
}

void main() {
  late MockServiceController mockApi;

  setUp(() {
    mockApi = MockServiceController();
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('stato iniziale', () {
    test('isOnline è true prima di start()', () {
      final service = makeService(mockApi);
      expect(service.isOnline, isTrue);
      service.dispose();
    });
  });
  
  group('start()', () {
    testWidgets('chiama hasInternet() immediatamente', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      service.start();
      await tester.pump();

      verify(mockApi.hasInternet()).called(greaterThanOrEqualTo(1));
      service.dispose();
    });

    testWidgets('chiamare start() due volte non duplica il polling', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      service.start();
      service.start();
      await tester.pump();

      verify(mockApi.hasInternet()).called(1);
      service.dispose();
    });

    testWidgets('imposta isOnline=true se hasInternet() ritorna true', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      service.start();
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.isOnline, isTrue);
      service.dispose();
    });
  });

  group('rilevamento offline', () {
    testWidgets('dopo offlineThreshold imposta isOnline=false', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => false);
      final service = makeService(mockApi);

      bool notified = false;
      service.addListener(() => notified = true);
      service.start();

      await tester.pump(const Duration(milliseconds: 200));

      expect(service.isOnline, isFalse);
      expect(notified, isTrue);
      service.dispose();
    });

    testWidgets('non va offline se connessione torna prima di offlineThreshold',
        (tester) async {
      var callCount = 0;
      when(mockApi.hasInternet()).thenAnswer((_) async {
        callCount++;
        return callCount >= 2;
      });

      final service = makeService(mockApi);
      service.start();
      await tester.pump(const Duration(milliseconds: 200));

      expect(service.isOnline, isTrue);
      service.dispose();
    });

    testWidgets('notifica i listener quando passa da online a offline', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => false);
      final service = makeService(mockApi);

      int notifyCount = 0;
      service.addListener(() => notifyCount++);
      service.start();
      await tester.pump(const Duration(milliseconds: 200));

      expect(notifyCount, greaterThanOrEqualTo(1));
      service.dispose();
    });
  });

  group('ritorno online', () {
    testWidgets('imposta isOnline=true quando hasInternet() torna true', (tester) async {
      var callCount = 0;
      when(mockApi.hasInternet()).thenAnswer((_) async {
        callCount++;
        return callCount > 3; 
      });

      final service = makeService(mockApi);
      service.start();
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.isOnline, isTrue);
      service.dispose();
    });

    testWidgets('notifica i listener quando torna online', (tester) async {
      var callCount = 0;
      when(mockApi.hasInternet()).thenAnswer((_) async {
        callCount++;
        return callCount > 3;
      });

      final service = makeService(mockApi);
      int notifyCount = 0;
      service.addListener(() => notifyCount++);
      service.start();
      await tester.pump(const Duration(milliseconds: 300));

      expect(notifyCount, greaterThanOrEqualTo(1));
      service.dispose();
    });

    testWidgets('_setOnline non notifica se il valore non cambia', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      int notifyCount = 0;
      service.addListener(() => notifyCount++);
      service.start();
      await tester.pump(const Duration(milliseconds: 200));

      expect(notifyCount, 0);
      service.dispose();
    });
  });

  group('forceRecheck()', () {
    testWidgets('chiama hasInternet() immediatamente', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);
      service.start();
      await tester.pump();

      clearInteractions(mockApi);
      service.forceRecheck();
      await tester.pump();

      verify(mockApi.hasInternet()).called(greaterThanOrEqualTo(1));
      service.dispose();
    });

    testWidgets('può essere chiamato prima di start() senza errori', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      expect(() => service.forceRecheck(), returnsNormally);
      service.dispose();
    });
  });

  group('didChangeAppLifecycleState - resumed', () {
    testWidgets('dopo resumeGracePeriod esegue un tick', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);
      service.start();
      await tester.pump();

      clearInteractions(mockApi);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await tester.pump(const Duration(milliseconds: 40));
      verifyNever(mockApi.hasInternet());

      await tester.pump(const Duration(milliseconds: 100));
      verify(mockApi.hasInternet()).called(greaterThanOrEqualTo(1));

      service.dispose();
    });

    testWidgets('resumed non fa nulla se start() non è stato chiamato', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(mockApi.hasInternet());
      service.dispose();
    });
  });

  group('didChangeAppLifecycleState - background', () {
    for (final state in [
      AppLifecycleState.paused,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
    ]) {
      testWidgets('$state blocca i tick successivi', (tester) async {
        when(mockApi.hasInternet()).thenAnswer((_) async => true);
        final service = makeService(mockApi);
        service.start();
        await tester.pump();

        service.didChangeAppLifecycleState(state);
        clearInteractions(mockApi);

        await tester.pump(const Duration(milliseconds: 200));
        verifyNever(mockApi.hasInternet());

        service.dispose();
      });
    }

    testWidgets('paused dopo resumed cancella il resumeTimer', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);
      service.start();
      await tester.pump();

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      clearInteractions(mockApi);
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(mockApi.hasInternet());
      service.dispose();
    });
  });

  group('dispose()', () {
    testWidgets('cancella tutti i timer senza errori', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);
      service.start();
      await tester.pump();

      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('dispose() prima di start() non lancia eccezioni', (tester) async {
      final service = makeService(mockApi);
      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('dopo dispose() il polling si ferma', (tester) async {
      when(mockApi.hasInternet()).thenAnswer((_) async => true);
      final service = makeService(mockApi);
      service.start();
      await tester.pump();

      service.dispose();
      clearInteractions(mockApi);

      await tester.pump(const Duration(milliseconds: 200));
      verifyNever(mockApi.hasInternet());
    });
  });
}