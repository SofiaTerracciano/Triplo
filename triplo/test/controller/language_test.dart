import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:triplo/controller/language.dart';
import 'package:triplo/service/memory.dart';
import 'language_test.mocks.dart';
import 'trekking_test.mocks.dart' hide MockMemoryService;

@GenerateMocks([MemoryService])

void main() {
  late MockMemoryService mockMemory;

  setUp(() {
    mockMemory = MockMemoryService();
  });

  // -------------------------------------------------------------------------
  // Constructor / initial state
  // -------------------------------------------------------------------------

  group('Language – initial state', () {
    test('default locale is English', () {
      final ctrl = Language(memoryService: mockMemory);
      expect(ctrl.locale, const Locale('en'));
    });

    test('exposes the injected MemoryService', () {
      final ctrl = Language(memoryService: mockMemory);
      expect(ctrl.memoryService, mockMemory);
    });
  });

  // -------------------------------------------------------------------------
  // loadSavedLocale
  // -------------------------------------------------------------------------

  group('loadSavedLocale()', () {
    test('updates locale and notifies listeners when a valid code is saved', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => 'it');

      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('it'));
      expect(notified, isTrue);
    });

    test('does nothing when saved code is null', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => null);

      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('en'));
      expect(notified, isFalse);
    });

    test('does nothing when saved code is empty string', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => '');

      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('en'));
      expect(notified, isFalse);
    });

    test('does nothing when saved locale equals current locale', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => 'en');

      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadSavedLocale();

      expect(ctrl.locale, const Locale('en'));
      expect(notified, isFalse);
    });

    test('never calls saveLocaleCode', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => 'fr');

      final ctrl = Language(memoryService: mockMemory);
      await ctrl.loadSavedLocale();

      verifyNever(mockMemory.saveLocaleCode(any));
    });
  });

  // -------------------------------------------------------------------------
  // setLocale
  // -------------------------------------------------------------------------

  group('setLocale()', () {
    test('updates locale, notifies listeners and persists the code', () async {
      when(mockMemory.saveLocaleCode(any)).thenAnswer((_) async {});

      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.setLocale(const Locale('de'));

      expect(ctrl.locale, const Locale('de'));
      expect(notified, isTrue);
      verify(mockMemory.saveLocaleCode('de')).called(1);
    });

    test('does nothing when new locale equals current locale', () async {
      final ctrl = Language(memoryService: mockMemory);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.setLocale(const Locale('en')); // same as default

      expect(ctrl.locale, const Locale('en'));
      expect(notified, isFalse);
      verifyNever(mockMemory.saveLocaleCode(any));
    });

    test('persists the correct languageCode', () async {
      when(mockMemory.saveLocaleCode(any)).thenAnswer((_) async {});

      final ctrl = Language(memoryService: mockMemory);
      await ctrl.setLocale(const Locale('es'));

      final captured =
          verify(mockMemory.saveLocaleCode(captureAny)).captured;
      expect(captured.single, 'es');
    });

    test('can switch locale multiple times', () async {
      when(mockMemory.saveLocaleCode(any)).thenAnswer((_) async {});

      final ctrl = Language(memoryService: mockMemory);

      await ctrl.setLocale(const Locale('fr'));
      expect(ctrl.locale, const Locale('fr'));

      await ctrl.setLocale(const Locale('ja'));
      expect(ctrl.locale, const Locale('ja'));

      verify(mockMemory.saveLocaleCode(any)).called(2);
    });

    test('notifyListeners is called before saveLocaleCode resolves', () async {
      final order = <String>[];

      when(mockMemory.saveLocaleCode(any)).thenAnswer((_) async {
        order.add('saved');
      });

      final ctrl = Language(memoryService: mockMemory);
      ctrl.addListener(() => order.add('notified'));

      await ctrl.setLocale(const Locale('ko'));

      expect(order, ['notified', 'saved']);
    });
  });

  // -------------------------------------------------------------------------
  // loadSavedLocale + setLocale interaction
  // -------------------------------------------------------------------------

  group('loadSavedLocale + setLocale interaction', () {
    test('setLocale after load correctly changes from loaded locale', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => 'it');
      when(mockMemory.saveLocaleCode(any)).thenAnswer((_) async {});

      final ctrl = Language(memoryService: mockMemory);
      await ctrl.loadSavedLocale();
      expect(ctrl.locale, const Locale('it'));

      await ctrl.setLocale(const Locale('fr'));
      expect(ctrl.locale, const Locale('fr'));
      verify(mockMemory.saveLocaleCode('fr')).called(1);
    });

    test('setLocale with same locale as loaded is a no-op', () async {
      when(mockMemory.getSavedLocaleCode()).thenAnswer((_) async => 'it');

      final ctrl = Language(memoryService: mockMemory);
      await ctrl.loadSavedLocale();

      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      await ctrl.setLocale(const Locale('it'));

      expect(notifyCount, 0);
      verifyNever(mockMemory.saveLocaleCode(any));
    });
  });
}
