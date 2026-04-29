import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
@GenerateMocks([MemoryService])
import 'language_test.mocks.dart';
import 'trekking_test.mocks.dart' hide MockMemoryService;

void main() {
  late MockMemoryService mockMemory;

  Language makeCtrl() => Language(memoryService: mockMemory);
  
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  group('Language – stato iniziale –', () {
    test('locale di default è en', () {
      final lang = Language(memoryService: MockMemoryService());
      expect(lang.locale, const Locale('en'));
    });
  });

  group('Language – setLocale –', () {
    test('cambia locale e notifica i listener', () async {
      final memory = MockMemoryService();
      when(memory.saveLocale(any)).thenAnswer((_) async {});
      final lang = Language(memoryService: memory);
      int notifications = 0;
      lang.addListener(() => notifications++);

      await lang.setLocale(const Locale('it'));

      expect(lang.locale, const Locale('it'));
      expect(notifications, 1);
      verify(memory.saveLocale('it')).called(1);
    });

    test('non notifica se la locale è la stessa', () async {
      final memory = MockMemoryService();
      final lang = Language(memoryService: memory);
      int notifications = 0;
      lang.addListener(() => notifications++);

      await lang.setLocale(const Locale('en')); // già en

      expect(notifications, 0);
      verifyNever(memory.saveLocale(any));
    });

    test('supporta tutte e 5 le lingue configurate', () async {
      final memory = MockMemoryService();
      when(memory.saveLocale(any)).thenAnswer((_) async {});
      final lang = Language(memoryService: memory);

      for (final code in ['en', 'it', 'es', 'de', 'fr']) {
        await lang.setLocale(Locale(code));
        expect(lang.locale.languageCode, code);
        // reset per prossima iterazione
        await lang.setLocale(const Locale('en'));
      }
    });
  });

  group('Language – loadSavedLocale –', () {
    test('carica la locale salvata e notifica', () async {
      final memory = MockMemoryService();
      when(memory.getLocale()).thenAnswer((_) async => 'fr');
      final lang = Language(memoryService: memory);
      int notifications = 0;
      lang.addListener(() => notifications++);

      await lang.loadSavedLocale();

      expect(lang.locale, const Locale('fr'));
      expect(notifications, 1);
    });

    test('non cambia locale se getLocale restituisce null', () async {
      final memory = MockMemoryService();
      when(memory.getLocale()).thenAnswer((_) async => null);
      final lang = Language(memoryService: memory);
      int notifications = 0;
      lang.addListener(() => notifications++);

      await lang.loadSavedLocale();

      expect(lang.locale, const Locale('en'));
      expect(notifications, 0);
    });

    test('non notifica se la locale salvata è già quella corrente', () async {
      final memory = MockMemoryService();
      when(memory.getLocale()).thenAnswer((_) async => 'en');
      final lang = Language(memoryService: memory);
      int notifications = 0;
      lang.addListener(() => notifications++);

      await lang.loadSavedLocale();

      expect(notifications, 0);
    });

    test('non cambia locale se getLocale restituisce stringa vuota', () async {
      final memory = MockMemoryService();
      when(memory.getLocale()).thenAnswer((_) async => '');
      final lang = Language(memoryService: memory);

      await lang.loadSavedLocale();

      expect(lang.locale, const Locale('en'));
    });
  });
}
