import 'dart:ui';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/service/internetservice.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';

@GenerateMocks([ServiceController])
import 'internet_service_test.mocks.dart';

InternetService _makeSvc(MockServiceController sc) => InternetService(
      servicecontroller: sc,
      checkEvery: const Duration(hours: 99), 
      offlineThreshold: const Duration(milliseconds: 50),
      resumeGracePeriod: const Duration(milliseconds: 50),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InternetService – stato iniziale –', () {
    test('isOnline è true di default', () {
      final sc = MockServiceController();
      expect(_makeSvc(sc).isOnline, isTrue);
    });
  });

  group('InternetService – start –', () {
    test('start() non lancia eccezioni', () {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      expect(() => svc.start(), returnsNormally);
      svc.dispose();
    });

    test('start() chiamato due volte non duplica il timer', () async {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      svc.start(); 
      await Future.delayed(const Duration(milliseconds: 100));
      verify(sc.hasInternet()).called(1);
      svc.dispose();
    });
  });

  group('InternetService – transizioni online/offline –', () {
    test('rimane online dopo tick positivo', () async {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(svc.isOnline, isTrue);
      svc.dispose();
    });

    test('forceRecheck torna online se hasInternet è true', () async {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      await svc.forceRecheck();
      expect(svc.isOnline, isTrue);
      svc.dispose();
    });

    test('forceRecheck va offline dopo 3 tentativi falliti', () {
      fakeAsync((async) {
        final sc = MockServiceController();
        when(sc.hasInternet()).thenAnswer((_) async => false);
        final svc = _makeSvc(sc);
        svc.start();

        // Avvia forceRecheck senza await — è async interno
        svc.forceRecheck();

        // Avanza il tempo virtuale oltre i 3 tentativi × 2 secondi
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(svc.isOnline, isFalse);
        svc.dispose();
      });
    });

    test('notifyListeners chiamato quando stato cambia', () {
      fakeAsync((async) {
        final sc = MockServiceController();
        when(sc.hasInternet()).thenAnswer((_) async => false);
        final svc = _makeSvc(sc);
        int callCount = 0;
        svc.addListener(() => callCount++);
        svc.start();

        svc.forceRecheck();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(callCount, greaterThan(0));
        svc.dispose();
      });
    });
  });

  group('InternetService – lifecycle –', () {
    test('didChangeAppLifecycleState resumed non lancia', () {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      expect(
        () => svc.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
      svc.dispose();
    });

    test('didChangeAppLifecycleState paused non lancia', () {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      expect(
        () => svc.didChangeAppLifecycleState(AppLifecycleState.paused),
        returnsNormally,
      );
      svc.dispose();
    });

    test('dispose non lancia eccezioni', () {
      final sc = MockServiceController();
      when(sc.hasInternet()).thenAnswer((_) async => true);
      final svc = _makeSvc(sc);
      svc.start();
      expect(() => svc.dispose(), returnsNormally);
    });
  });
}