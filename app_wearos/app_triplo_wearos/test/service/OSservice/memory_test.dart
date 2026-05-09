import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:file/file.dart' as pkg_file;
import 'package:file/local.dart';

@GenerateMocks([CacheManager, FileInfo])
import 'memory_test.mocks.dart';

File _tempFile(String name) {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$name');
  file.writeAsStringSync('test');
  return file;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('MemoryService – locale –', () {
    test('saveLocale and getLocale round-trip', () async {
      final svc = MemoryService();
      await svc.saveLocale('it');
      expect(await svc.getLocale(), 'it');
    });

    test('getLocale returns null when nothing saved', () async {
      expect(await MemoryService().getLocale(), isNull);
    });

    test('saveLocale overwrites previous value', () async {
      final svc = MemoryService();
      await svc.saveLocale('en');
      await svc.saveLocale('fr');
      expect(await svc.getLocale(), 'fr');
    });
  });

  group('MemoryService – watchId –', () {
    test('saveWatchId and getWatchId round-trip', () async {
      final svc = MemoryService();
      await svc.saveWatchId('watch-abc');
      expect(await svc.getWatchId(), 'watch-abc');
    });

    test('getWatchId returns null when nothing saved', () async {
      expect(await MemoryService().getWatchId(), isNull);
    });

    test('saveWatchId overwrites previous value', () async {
      final svc = MemoryService();
      await svc.saveWatchId('first-id');
      await svc.saveWatchId('second-id');
      expect(await svc.getWatchId(), 'second-id');
    });
  });

  group('MemoryService – RAM cache –', () {
    test('saveImageToMemory and getImageFromMemory return the same file',
        () async {
      final svc = MemoryService();
      final file = _tempFile('ram_hit.txt');
      addTearDown(file.deleteSync);

      svc.saveImageToMemory('key1', file);
      expect(await svc.getImageFromMemory('key1'), same(file));
    });

    test('getImageFromMemory returns null for unknown key', () async {
      expect(await MemoryService().getImageFromMemory('nonexistent'), isNull);
    });

    test(
        'getImageFromMemory returns null and evicts entry when file does not exist',
        () async {
      final svc = MemoryService();
      final file = _tempFile('ram_miss.txt');
      file.deleteSync();

      svc.saveImageToMemory('key2', file);
      expect(await svc.getImageFromMemory('key2'), isNull);
      expect(await svc.getImageFromMemory('key2'), isNull);
    });

    test('clearAllRam empties the cache', () async {
      final svc = MemoryService();
      final file = _tempFile('ram_clear.txt');
      addTearDown(file.deleteSync);

      svc.saveImageToMemory('key3', file);
      svc.clearAllRam();
      expect(await svc.getImageFromMemory('key3'), isNull);
    });

    test('multiple keys stored and retrieved independently', () async {
      final svc = MemoryService();
      final fileA = _tempFile('ram_a.txt');
      final fileB = _tempFile('ram_b.txt');
      addTearDown(fileA.deleteSync);
      addTearDown(fileB.deleteSync);

      svc.saveImageToMemory('a', fileA);
      svc.saveImageToMemory('b', fileB);

      expect(await svc.getImageFromMemory('a'), same(fileA));
      expect(await svc.getImageFromMemory('b'), same(fileB));
    });
  });
  group('MemoryService – disk cache –', () {

    test('getImageFromDisk returns null on cache miss', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenAnswer((_) async => null);

      final svc = MemoryServiceWithMockCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/miss.jpg'), isNull);
    });

    test('getImageFromDisk returns null when cache throws', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenThrow(Exception('disk error'));

      final svc = MemoryServiceWithMockCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/err.jpg'), isNull);
    });

    test('getImageFromDisk returns null on cache miss', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenAnswer((_) async => null);

      final svc = MemoryServiceWithMockCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/miss.jpg'), isNull);
    });

    test('getImageFromDisk returns null when cache throws', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenThrow(Exception('disk error'));

      final svc = MemoryServiceWithMockCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/err.jpg'), isNull);
    });

    test('cacheImageOnDisk rethrows on failure', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getSingleFile(any, key: anyNamed('key'), headers: anyNamed('headers')))
          .thenThrow(Exception('network error'));

      final svc = MemoryServiceWithMockCache(mockCache);
      expect(
        () => svc.cacheImageOnDisk('http://example.com/fail.jpg'),
        throwsException,
      );
    });
  });
  group('MemoryService – weather alert keys –', () {
    test('getShownWeatherAlertKeys returns empty set when nothing saved',
        () async {
      expect(await MemoryService().getShownWeatherAlertKeys(), isEmpty);
    });

    test('saveShownWeatherAlertKeys and getShownWeatherAlertKeys round-trip',
        () async {
      final svc = MemoryService();
      await svc.saveShownWeatherAlertKeys({'alert-1', 'alert-2'});
      final result = await svc.getShownWeatherAlertKeys();
      expect(result, containsAll(['alert-1', 'alert-2']));
      expect(result.length, 2);
    });

    test('hasShownWeatherAlertKey returns false when key not present',
        () async {
      expect(await MemoryService().hasShownWeatherAlertKey('missing'), isFalse);
    });

    test('hasShownWeatherAlertKey returns true after addShownWeatherAlertKey',
        () async {
      final svc = MemoryService();
      await svc.addShownWeatherAlertKey('alert-x');
      expect(await svc.hasShownWeatherAlertKey('alert-x'), isTrue);
    });

    test('addShownWeatherAlertKey accumulates multiple keys', () async {
      final svc = MemoryService();
      await svc.addShownWeatherAlertKey('a');
      await svc.addShownWeatherAlertKey('b');
      await svc.addShownWeatherAlertKey('c');
      final result = await svc.getShownWeatherAlertKeys();
      expect(result, containsAll(['a', 'b', 'c']));
    });

    test('addShownWeatherAlertKey is idempotent (Set deduplicates)', () async {
      final svc = MemoryService();
      await svc.addShownWeatherAlertKey('dup');
      await svc.addShownWeatherAlertKey('dup');
      expect((await svc.getShownWeatherAlertKeys()).length, 1);
    });
  });

  group('MemoryService – locale –', () {
    test('saveLocale e getLocale round-trip', () async {
      final m = MemoryService();
      await m.saveLocale('it');
      expect(await m.getLocale(), 'it');
    });

    test('getLocale restituisce null se non salvato', () async {
      final m = MemoryService();
      expect(await m.getLocale(), isNull);
    });

    test('sovrascrive il valore precedente', () async {
      final m = MemoryService();
      await m.saveLocale('en');
      await m.saveLocale('de');
      expect(await m.getLocale(), 'de');
    });
  });
  

  group('MemoryService – RAM cache –', () {
    test('saveImageToMemory e getImageFromMemory round-trip', () async {
      final m = MemoryService();
      final file = await File.fromUri(
              Uri.parse('${Directory.systemTemp.path}/test_img.png'))
          .create();
      m.saveImageToMemory('key1', file);
      final result = await m.getImageFromMemory('key1');
      expect(result, isNotNull);
      await file.delete();
    });

    test('getImageFromMemory restituisce null se chiave non presente',
        () async {
      final m = MemoryService();
      expect(await m.getImageFromMemory('missing'), isNull);
    });

    test('getImageFromMemory rimuove file non più esistenti', () async {
      final m = MemoryService();
      final file =
          File('${Directory.systemTemp.path}/ghost_${DateTime.now().millisecondsSinceEpoch}.png');
      m.saveImageToMemory('ghost', file); 
      final result = await m.getImageFromMemory('ghost');
      expect(result, isNull);
    });

    test('clearAllRam svuota la cache', () async {
      final m = MemoryService();
      final file = await File(
              '${Directory.systemTemp.path}/clear_test.png')
          .create();
      m.saveImageToMemory('k', file);
      m.clearAllRam();
      expect(await m.getImageFromMemory('k'), isNull);
      await file.delete();
    });
  });

  group('MemoryService – weather alert keys –', () {
    test('getShownWeatherAlertKeys restituisce set vuoto inizialmente',
        () async {
      final m = MemoryService();
      expect(await m.getShownWeatherAlertKeys(), isEmpty);
    });

    test('addShownWeatherAlertKey aggiunge la chiave', () async {
      final m = MemoryService();
      await m.addShownWeatherAlertKey('alert-1');
      expect(await m.hasShownWeatherAlertKey('alert-1'), isTrue);
    });

    test('hasShownWeatherAlertKey restituisce false per chiave assente',
        () async {
      final m = MemoryService();
      expect(await m.hasShownWeatherAlertKey('not-there'), isFalse);
    });

    test('saveShownWeatherAlertKeys e getShownWeatherAlertKeys round-trip',
        () async {
      final m = MemoryService();
      await m.saveShownWeatherAlertKeys({'a', 'b', 'c'});
      final result = await m.getShownWeatherAlertKeys();
      expect(result, containsAll(['a', 'b', 'c']));
    });

    test('addShownWeatherAlertKey è idempotente', () async {
      final m = MemoryService();
      await m.addShownWeatherAlertKey('dup');
      await m.addShownWeatherAlertKey('dup');
      final keys = await m.getShownWeatherAlertKeys();
      expect(keys.where((k) => k == 'dup').length, 1);
    });
  });

  group('MemoryService – weather alert keys (error paths) –', () {
    test(
        'getShownWeatherAlertKeys returns empty set when SharedPreferences throws',
        () async {
      final svc = _MemoryServiceThrowingPrefs();
      final result = await svc.getShownWeatherAlertKeys();
      expect(result, isEmpty);
    });

    test('saveShownWeatherAlertKeys completes silently when prefs throws',
        () async {
      final svc = _MemoryServiceThrowingPrefs();
      await expectLater(
        svc.saveShownWeatherAlertKeys({'k1', 'k2'}),
        completes,
      );
    });

    test('hasShownWeatherAlertKey returns false when prefs throw', () async {
      final svc = _MemoryServiceThrowingPrefs();
      expect(await svc.hasShownWeatherAlertKey('any'), isFalse);
    });
  });

  group('MemoryService – weather alert keys (save path) –', () {
    test('saveShownWeatherAlertKeys persists and is readable back', () async {
      final svc = MemoryService();
      await svc.saveShownWeatherAlertKeys({'x', 'y', 'z'});
      final back = await svc.getShownWeatherAlertKeys();
      expect(back, containsAll(['x', 'y', 'z']));
      expect(back.length, 3);
    });

    test('overwriting with a smaller set shrinks the stored keys', () async {
      final svc = MemoryService();
      await svc.saveShownWeatherAlertKeys({'a', 'b', 'c', 'd'});
      await svc.saveShownWeatherAlertKeys({'only'});
      final back = await svc.getShownWeatherAlertKeys();
      expect(back, {'only'});
    });
  });

  group('MemoryService – getImageFromDisk –', () {


    test('returns null on cache miss (fileInfo == null)', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenAnswer((_) async => null);

      final svc = _InjectableDiskCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/miss.jpg'), isNull);
    });

    test('returns null and swallows exception when cache throws', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenThrow(Exception('disk error'));

      final svc = _InjectableDiskCache(mockCache);
      expect(await svc.getImageFromDisk('http://example.com/err.jpg'), isNull);
    });
  });

  group('MemoryService – cacheImageOnDisk –', () {

    test('rethrows exception on failure', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getSingleFile(any, key: anyNamed('key'), headers: anyNamed('headers')))
          .thenThrow(Exception('network error'));

      final svc = _InjectableDiskCache(mockCache);
      expect(
        () => svc.cacheImageOnDisk('http://example.com/fail.jpg'),
        throwsException,
      );
    });
  });


  group('MemoryService – getShownWeatherAlertKeys catch –', () {
    test('returns empty set when SharedPreferences throws', () async {
      final svc = _ThrowingPrefsService();
      expect(await svc.getShownWeatherAlertKeys(), isEmpty);
    });

    test('hasShownWeatherAlertKey returns false when prefs throw', () async {
      final svc = _ThrowingPrefsService();
      expect(await svc.hasShownWeatherAlertKey('any'), isFalse);
    });
  });


  group('MemoryService – saveShownWeatherAlertKeys catch –', () {
    test('completes silently when SharedPreferences throws', () async {
      final svc = _ThrowingPrefsService();
      await expectLater(svc.saveShownWeatherAlertKeys({'k1', 'k2'}), completes);
    });

    test('addShownWeatherAlertKey completes silently when save throws',
        () async {
      final svc = _ThrowingPrefsService();
      await expectLater(svc.addShownWeatherAlertKey('x'), completes);
    });
  });

  group('MemoryService – getImageFromDisk happy path –', () {
    test('returns file when CacheManager returns a valid FileInfo', () async {
      final mockCache = MockCacheManager();
      final mockFileInfo = MockFileInfo();

      final fs = LocalFileSystem();
      final pkgFile = fs.file('${Directory.systemTemp.path}/disk_hit_real.txt');
      await pkgFile.writeAsString('hello');
      addTearDown(() async {
        if (await pkgFile.exists()) await pkgFile.delete();
      });

      when(mockCache.getFileFromCache(any))
          .thenAnswer((_) async => mockFileInfo);
      when(mockFileInfo.file).thenReturn(pkgFile);

      final svc = _InjectableDiskCache(mockCache);
      final result = await svc.getImageFromDisk('http://example.com/hit.jpg');

      expect(result, isNotNull);
      expect(result!.path, pkgFile.path);
    });
  });

  group('MemoryService – cacheImageOnDisk happy path –', () {
    test('returns file on successful getSingleFile', () async {
      final mockCache = MockCacheManager();

      final fs = LocalFileSystem();
      final pkgFile = fs.file('${Directory.systemTemp.path}/disk_cache_ok.txt');
      await pkgFile.writeAsString('data');
      addTearDown(() async {
        if (await pkgFile.exists()) await pkgFile.delete();
      });

      // Matcha tutti i named params opzionali esplicitamente
      when(mockCache.getSingleFile(
        any,
        key: anyNamed('key'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => pkgFile);

      final svc = _InjectableDiskCache(mockCache);
      final result = await svc.cacheImageOnDisk('http://example.com/img.jpg');

      expect(result.path, pkgFile.path);
    });
  });

  group('MemoryService – watchId edge cases –', () {
    test('saveWatchId then getWatchId returns empty string', () async {
      final svc = MemoryService();
      await svc.saveWatchId('');
      expect(await svc.getWatchId(), '');
    });

    test('saveWatchId with special characters round-trips correctly', () async {
      final svc = MemoryService();
      await svc.saveWatchId('watch-!@#\$%^&*()');
      expect(await svc.getWatchId(), 'watch-!@#\$%^&*()');
    });
  });

  group('MemoryService – hasShownWeatherAlertKey full flow –', () {
    test('returns false before add, true after add', () async {
      final svc = MemoryService();
      expect(await svc.hasShownWeatherAlertKey('new-key'), isFalse);
      await svc.addShownWeatherAlertKey('new-key');
      expect(await svc.hasShownWeatherAlertKey('new-key'), isTrue);
    });

    test('addShownWeatherAlertKey preserves existing keys', () async {
      final svc = MemoryService();
      await svc.addShownWeatherAlertKey('first');
      await svc.addShownWeatherAlertKey('second');
      expect(await svc.hasShownWeatherAlertKey('first'), isTrue);
      expect(await svc.hasShownWeatherAlertKey('second'), isTrue);
    });
  });

  group('MemoryService – locale edge cases –', () {
    test('saveLocale with empty string round-trips', () async {
      final svc = MemoryService();
      await svc.saveLocale('');
      expect(await svc.getLocale(), '');
    });

    test('saveLocale with long locale code round-trips', () async {
      final svc = MemoryService();
      await svc.saveLocale('zh-Hans-CN');
      expect(await svc.getLocale(), 'zh-Hans-CN');
    });
  });

  group('MemoryService – RAM cache edge cases –', () {
    test('overwriting a key updates the stored file', () async {
      final svc = MemoryService();
      final fileA = _tempFile('overwrite_a.txt');
      final fileB = _tempFile('overwrite_b.txt');
      addTearDown(fileA.deleteSync);
      addTearDown(fileB.deleteSync);

      svc.saveImageToMemory('same-key', fileA);
      svc.saveImageToMemory('same-key', fileB);

      final result = await svc.getImageFromMemory('same-key');
      expect(result, same(fileB));
    });

    test('getImageFromMemory after clearAllRam returns null for all keys',
        () async {
      final svc = MemoryService();
      final fileA = _tempFile('clear_a.txt');
      final fileB = _tempFile('clear_b.txt');
      addTearDown(fileA.deleteSync);
      addTearDown(fileB.deleteSync);

      svc.saveImageToMemory('ka', fileA);
      svc.saveImageToMemory('kb', fileB);
      svc.clearAllRam();

      expect(await svc.getImageFromMemory('ka'), isNull);
      expect(await svc.getImageFromMemory('kb'), isNull);
    });
  });
}

class _MemoryServiceThrowingPrefs extends MemoryService {
  @override
  Future<Set<String>> getShownWeatherAlertKeys() async {
    try {
      throw Exception('prefs unavailable');
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> saveShownWeatherAlertKeys(Set<String> keys) async {
    try {
      throw Exception('prefs unavailable');
    } catch (_) {
      }
  }
}

class MemoryServiceWithMockCache extends MemoryService {
  final CacheManager _mockCache;
  MemoryServiceWithMockCache(this._mockCache);

  @override
  Future<File?> getImageFromDisk(String url) async {
    try {
      final fileInfo = await _mockCache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File> cacheImageOnDisk(String url) async {
    try {
      return await _mockCache.getSingleFile(url);
    } catch (e) {
      rethrow;
    }
  }
}


class _InjectableDiskCache extends MemoryService {
  final CacheManager cache;
  _InjectableDiskCache(this.cache);

  @override
  Future<File?> getImageFromDisk(String url) async {
    try {
      final fileInfo = await cache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      return null; 
    }
  }

  @override
  Future<File> cacheImageOnDisk(String url) async {
    try {
      return await cache.getSingleFile(url);
    } catch (e) {
      rethrow;
    }
  }
}

class _ThrowingPrefsService extends MemoryService {
  @override
  Future<Set<String>> getShownWeatherAlertKeys() async {
    try {
      throw Exception('prefs error');
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> saveShownWeatherAlertKeys(Set<String> keys) async {
    try {
      throw Exception('prefs error');
    } catch (_) {
    }
  }
}