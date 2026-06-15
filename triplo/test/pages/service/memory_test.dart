import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/service/memory.dart';
import 'package:file/file.dart' as pkg_file;
import 'package:file/local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_test.mocks.dart';


@GenerateMocks([CacheManager, FileInfo])
void main() {

  TestWidgetsFlutterBinding.ensureInitialized();
  // Start with empty fake preferences
  SharedPreferences.setMockInitialValues({});

  // tests the RAM image cache
  group('Cache RAM', () {
    late MemoryService service;

    setUp(() {
      // We inject a fake cache manager so the real plugin is never used
      service = MemoryService.withCache(MockCacheManager());
    });

    group('saveImageToMemory() + getImageFromMemory()', () {
      test('salva e recupera un file esistente', () async {
        // Create a temporary file, store it in RAM, and read it back
        final file = await File(
          '${Directory.systemTemp.path}/test_img.jpg',
        ).create();
        service.saveImageToMemory('img1', file);

        final result = await service.getImageFromMemory('img1');
        expect(result?.path, equals(file.path));
        await file.delete();
      });

      test('restituisce null per chiave inesistente', () async {
        // If the key was never saved, the service should return null
        expect(await service.getImageFromMemory('no_key'), isNull);
      });

      test('restituisce null e rimuove chiave se file eliminato', () async {
        // The cache remembers the key, but the real file is gone
        final file = File('${Directory.systemTemp.path}/deleted.jpg');
        await file.create();
        service.saveImageToMemory('deleted', file);
        await file.delete();

        expect(await service.getImageFromMemory('deleted'), isNull);
        // La chiave è stata rimossa: seconda chiamata deve tornare null
        expect(await service.getImageFromMemory('deleted'), isNull);
      });

      test('sovrascrive file con stessa chiave', () async {
        // Saving twice with the same key should keep the latest file
        final f1 = await File('${Directory.systemTemp.path}/v1.jpg').create();
        final f2 = await File('${Directory.systemTemp.path}/v2.jpg').create();
        service.saveImageToMemory('key', f1);
        service.saveImageToMemory('key', f2);

        expect((await service.getImageFromMemory('key'))?.path, f2.path);
        await f1.delete();
        await f2.delete();
      });

      test('gestisce più chiavi indipendenti', () async {
        final fA = await File('${Directory.systemTemp.path}/a.jpg').create();
        final fB = await File('${Directory.systemTemp.path}/b.jpg').create();
        service.saveImageToMemory('a', fA);
        service.saveImageToMemory('b', fB);

        expect((await service.getImageFromMemory('a'))?.path, fA.path);
        expect((await service.getImageFromMemory('b'))?.path, fB.path);
        await fA.delete();
        await fB.delete();
      });
    });

    group('removeImageFromMemory()', () {
      test('rimuove chiave esistente', () async {
        // After removing the key, a lookup should return null.
        final file = await File(
          '${Directory.systemTemp.path}/rem.jpg',
        ).create();
        service.saveImageToMemory('rem', file);
        service.removeImageFromMemory('rem');

        expect(await service.getImageFromMemory('rem'), isNull);
        await file.delete();
      });

      test('non lancia eccezioni per chiave inesistente', () {
        // Removing a missing key should still be harmless.
        expect(() => service.removeImageFromMemory('ghost'), returnsNormally);
      });

      test('rimuove solo la chiave specificata', () async {
        final fA = await File('${Directory.systemTemp.path}/kA.jpg').create();
        final fB = await File('${Directory.systemTemp.path}/kB.jpg').create();
        service.saveImageToMemory('keep', fA);
        service.saveImageToMemory('remove', fB);
        service.removeImageFromMemory('remove');

        expect(await service.getImageFromMemory('keep'), isNotNull);
        expect(await service.getImageFromMemory('remove'), isNull);
        await fA.delete();
        await fB.delete();
      });
    });

    group('clearMemoryCache()', () {
      test('svuota tutte le chiavi', () async {
        // clearMemoryCache should wipe every saved RAM entry.
        final fA = await File('${Directory.systemTemp.path}/cA.jpg').create();
        final fB = await File('${Directory.systemTemp.path}/cB.jpg').create();
        service.saveImageToMemory('a', fA);
        service.saveImageToMemory('b', fB);
        service.clearMemoryCache();

        expect(await service.getImageFromMemory('a'), isNull);
        expect(await service.getImageFromMemory('b'), isNull);
        await fA.delete();
        await fB.delete();
      });

      test('non lancia eccezioni su cache già vuota', () {
        expect(() => service.clearMemoryCache(), returnsNormally);
      });

      test('dopo clear si può salvare di nuovo', () async {
        final file = await File(
          '${Directory.systemTemp.path}/reuse.jpg',
        ).create();
        service.saveImageToMemory('k', file);
        service.clearMemoryCache();
        service.saveImageToMemory('k', file);

        expect(await service.getImageFromMemory('k'), isNotNull);
        await file.delete();
      });
    });
  });

  group('addShownWeatherAlertKey()', () {
    late MockCacheManager mockCache;
    late MemoryService service;
    late File mockFile;

    setUp(() async {
      // checks how the service remembers already shown alerts
      mockCache = MockCacheManager();
      service = MemoryService.withCache(mockCache);
      mockFile = await File('${Directory.systemTemp.path}/mock_alert.jpg').create();
    });

    tearDown(() async {
      if (await mockFile.exists()) await mockFile.delete();
    });

    test('chiama putFile con chiave prefissata weather_alert_', () async {
      when(mockCache.putFile(
        any,
        any,
        key: anyNamed('key'),
        maxAge: anyNamed('maxAge'),
      )).thenAnswer((_) async {
          final fs = LocalFileSystem();
          return fs.file('${Directory.systemTemp.path}/mock_alert.jpg');
        });  

      await service.addShownWeatherAlertKey('trek_123');

      verify(mockCache.putFile(
        'weather_alert_trek_123',
        Uint8List(0),
        key: 'weather_alert_trek_123',
        maxAge: const Duration(days: 1),
      )).called(1);
    });

    test('non propaga eccezioni se putFile lancia', () async {
      // Cache write errors should not crash the app flow.
      when(mockCache.putFile(
        any,
        any,
        key: anyNamed('key'),
        maxAge: anyNamed('maxAge'),
      )).thenThrow(Exception('disk error'));

      await expectLater(
        service.addShownWeatherAlertKey('any_key'),
        completes,
      );
    });

    test('prefisso è sempre weather_alert_ indipendentemente dal valore', () async {
      when(mockCache.putFile(
        any,
        any,
        key: anyNamed('key'),
        maxAge: anyNamed('maxAge'),
      )).thenAnswer((_) async {
          final fs = LocalFileSystem();
          return fs.file('${Directory.systemTemp.path}/mock_alert.jpg');
        });

      await service.addShownWeatherAlertKey('abc');

      verify(mockCache.putFile(
        'weather_alert_abc',
        any,
        key: 'weather_alert_abc',
        maxAge: anyNamed('maxAge'),
      )).called(1);
    });
  });
  group('hasShownWeatherAlertKey()', () {
    late MockCacheManager mockCache;
    late MockFileInfo mockFileInfo;
    late MemoryService service;

    setUp(() {
      mockCache = MockCacheManager();
      mockFileInfo = MockFileInfo();
      service = MemoryService.withCache(mockCache);
    });

    test('restituisce true se fileInfo non è null', () async {
      when(mockCache.getFileFromCache(any))
          .thenAnswer((_) async => mockFileInfo);
      final result = await service.hasShownWeatherAlertKey('trek_123');
      expect(result, isTrue);
    });
    test('restituisce false se fileInfo è null', () async {
      when(mockCache.getFileFromCache(any)).thenAnswer((_) async => null);

      final result = await service.hasShownWeatherAlertKey('trek_123');
      expect(result, isFalse);
    });

    test('restituisce false e non propaga se getFileFromCache lancia', () async {
      when(mockCache.getFileFromCache(any))
          .thenThrow(Exception('cache error'));

      final result = await service.hasShownWeatherAlertKey('any');
      expect(result, isFalse);
    });

    test('usa chiave prefissata weather_alert_ nella ricerca', () async {
      when(mockCache.getFileFromCache('weather_alert_my_key'))
          .thenAnswer((_) async => mockFileInfo);

      final result = await service.hasShownWeatherAlertKey('my_key');
      expect(result, isTrue);
      verify(mockCache.getFileFromCache('weather_alert_my_key')).called(1);
    });
  });

  group('getSavedLocaleCode()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restituisce null se nessun locale salvato', () async {
      final service = MemoryService.withCache(MockCacheManager());
      final result = await service.getSavedLocaleCode();
      expect(result, isNull);
    });

    test('restituisce il locale salvato in precedenza', () async {
      SharedPreferences.setMockInitialValues({'locale_code': 'it'});
      final service = MemoryService.withCache(MockCacheManager());
      final result = await service.getSavedLocaleCode();
      expect(result, equals('it'));
    });
  });

  group('saveLocaleCode()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('salva il locale e lo recupera correttamente', () async {
      final service = MemoryService.withCache(MockCacheManager());
      await service.saveLocaleCode('en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_code'), equals('en'));
    });

    test('sovrascrive un locale precedente', () async {
      SharedPreferences.setMockInitialValues({'locale_code': 'it'});
      final service = MemoryService.withCache(MockCacheManager());
      await service.saveLocaleCode('fr');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_code'), equals('fr'));
    });
  });

  group('getShownWeatherAlertKeys()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restituisce set vuoto se nessun alert salvato', () async {
      final service = MemoryService.withCache(MockCacheManager());
      final result = await service.getShownWeatherAlertKeys();
      expect(result, isEmpty);
    });

    test('restituisce le chiavi salvate come Set', () async {
      SharedPreferences.setMockInitialValues({
        'shown_weather_alert_keys': ['key1', 'key2'],
      });
      final service = MemoryService.withCache(MockCacheManager());
      final result = await service.getShownWeatherAlertKeys();
      expect(result, containsAll(['key1', 'key2']));
      expect(result.length, equals(2));
    });
  });

  group('saveShownWeatherAlertKeys()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('salva le chiavi e le recupera correttamente', () async {
      final service = MemoryService.withCache(MockCacheManager());
      await service.saveShownWeatherAlertKeys({'alert_a', 'alert_b'});

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('shown_weather_alert_keys');
      expect(saved, containsAll(['alert_a', 'alert_b']));
    });
    test('sovrascrive le chiavi precedenti', () async {
      SharedPreferences.setMockInitialValues({
        'shown_weather_alert_keys': ['old_key'],
      });
      final service = MemoryService.withCache(MockCacheManager());
      await service.saveShownWeatherAlertKeys({'new_key'});

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('shown_weather_alert_keys');
      expect(saved, equals(['new_key']));
    });

    test('salva set vuoto senza errori', () async {
      final service = MemoryService.withCache(MockCacheManager());
      await expectLater(
        service.saveShownWeatherAlertKeys(<String>{}),
        completes,
      );
    });
  });
}
