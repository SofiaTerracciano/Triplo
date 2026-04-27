import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
@GenerateMocks([MemoryService])
import 'language_test.mocks.dart';
import 'trekking_test.mocks.dart' hide MockMemoryService;

void main() {
  late MockMemoryService mockMemory;

  Language makeCtrl() => Language(memoryService: mockMemory);

  setUp(() {
    mockMemory = MockMemoryService();
    when(mockMemory.saveLocale(any)).thenAnswer((_) async {});
    when(mockMemory.getLocale()).thenAnswer((_) async => null);
  });

  group('locale getter', () {
    test('locale di default è inglese', () {
      expect(makeCtrl().locale, const Locale('en'));
    });
  });

  group('setLocale', () {
    test('cambia la locale e notifica i listener', () async {
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.setLocale(const Locale('it'));

      expect(ctrl.locale, const Locale('it'));
      expect(count, 1);
    });

    test('chiama saveLocale con il languageCode corretto', () async {
      final ctrl = makeCtrl();

      await ctrl.setLocale(const Locale('fr'));

      verify(mockMemory.saveLocale('fr')).called(1);
    });

    test('non fa nulla se la locale è già quella corrente', () async {
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.setLocale(const Locale('en')); 

      expect(count, 0);
      verifyNever(mockMemory.saveLocale(any));
    });

    test('cambia locale più volte in sequenza', () async {
      final ctrl = makeCtrl();

      await ctrl.setLocale(const Locale('it'));
      await ctrl.setLocale(const Locale('de'));
      await ctrl.setLocale(const Locale('es'));

      expect(ctrl.locale, const Locale('es'));
      verify(mockMemory.saveLocale(any)).called(3);
    });

    test('non notifica se stessa locale viene impostata due volte', () async {
      final ctrl = makeCtrl();
      await ctrl.setLocale(const Locale('it'));

      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.setLocale(const Locale('it'));

      expect(count, 0);
    });
  });

  group('loadSavedLocale', () {
    test('carica la locale salvata e notifica', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => 'it');
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('it'));
      expect(count, 1);
    });

    test('non fa nulla se getLocale restituisce null', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => null);
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('en')); 
      expect(count, 0);
    });

    test('non fa nulla se getLocale restituisce stringa vuota', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => '');
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('en'));
      expect(count, 0);
    });

    test('non notifica se la locale salvata è uguale a quella corrente', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => 'en');
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);

      await ctrl.loadSavedLocale();

      expect(count, 0); 
    });

    test('carica locale dopo setLocale senza duplicare notifiche', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => 'de');
      final ctrl = makeCtrl();
      await ctrl.setLocale(const Locale('it'));

      int count = 0;
      ctrl.addListener(() => count++);
      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('de'));
      expect(count, 1);
    });

    test('chiama getLocale esattamente una volta', () async {
      when(mockMemory.getLocale()).thenAnswer((_) async => 'fr');
      final ctrl = makeCtrl();

      await ctrl.loadSavedLocale();

      verify(mockMemory.getLocale()).called(1);
    });
  });
}
