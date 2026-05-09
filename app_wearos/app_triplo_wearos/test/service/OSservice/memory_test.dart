import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:file/local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@GenerateMocks([CacheManager, FileInfo])
import 'memory_test.mocks.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationCachePath() async => Directory.systemTemp.path;
}

File _tempFile(String name) {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$name');
  file.writeAsStringSync('test');
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
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

    test('saveWatchId with empty string round-trips', () async {
      final svc = MemoryService();
      await svc.saveWatchId('');
      expect(await svc.getWatchId(), '');
    });

    test('saveWatchId with special characters round-trips', () async {
      final svc = MemoryService();
      await svc.saveWatchId('watch-!@#\$%^&*()');
      expect(await svc.getWatchId(), 'watch-!@#\$%^&*()');
    });
  });

  // ── RAM cache ─────────────────────────────────────────────────────────────
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

    test('getImageFromMemory returns null and evicts when file does not exist',
        () async {
      final svc = MemoryService();
      final file = _tempFile('ram_miss.txt');
      file.deleteSync();

      svc.saveImageToMemory('key2', file);
      expect(await svc.getImageFromMemory('key2'), isNull);
      // seconda chiamata: chiave già rimossa
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

    test('overwriting a key updates the stored file', () async {
      final svc = MemoryService();
      final fileA = _tempFile('overwrite_a.txt');
      final fileB = _tempFile('overwrite_b.txt');
      addTearDown(fileA.deleteSync);
      addTearDown(fileB.deleteSync);

      svc.saveImageToMemory('same-key', fileA);
      svc.saveImageToMemory('same-key', fileB);
      expect(await svc.getImageFromMemory('same-key'), same(fileB));
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

  // ── disk cache (codice ORIGINALE coperto tramite DI) ──────────────────────
  group('MemoryService – getImageFromDisk –', () {
    test('returns file when cache hits', () async {
      final mockCache = MockCacheManager();
      final mockFileInfo = MockFileInfo();

      final fs = LocalFileSystem();
      final pkgFile =
          fs.file('${Directory.systemTemp.path}/disk_hit_real.txt');
      await pkgFile.writeAsString('hello');
      addTearDown(() async {
        if (await pkgFile.exists()) await pkgFile.delete();
      });

      when(mockCache.getFileFromCache(any))
          .thenAnswer((_) async => mockFileInfo);
      when(mockFileInfo.file).thenReturn(pkgFile);

      // Usa il codice ORIGINALE di MemoryService con cache iniettata
      final svc = MemoryService(diskCache: mockCache);
      final result =
          await svc.getImageFromDisk('http://example.com/hit.jpg');

      expect(result, isNotNull);
      expect(result!.path, pkgFile.path);
    });

    test('returns null on cache miss', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any)).thenAnswer((_) async => null);

      final svc = MemoryService(diskCache: mockCache);
      expect(
          await svc.getImageFromDisk('http://example.com/miss.jpg'), isNull);
    });

    test('returns null and swallows exception when cache throws', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getFileFromCache(any))
          .thenThrow(Exception('disk error'));

      final svc = MemoryService(diskCache: mockCache);
      expect(
          await svc.getImageFromDisk('http://example.com/err.jpg'), isNull);
    });
  });

  group('MemoryService – cacheImageOnDisk –', () {
    test('returns file on success', () async {
      final mockCache = MockCacheManager();

      final fs = LocalFileSystem();
      final pkgFile =
          fs.file('${Directory.systemTemp.path}/disk_cache_ok.txt');
      await pkgFile.writeAsString('data');
      addTearDown(() async {
        if (await pkgFile.exists()) await pkgFile.delete();
      });

      when(mockCache.getSingleFile(
        any,
        key: anyNamed('key'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => pkgFile);

      final svc = MemoryService(diskCache: mockCache);
      final result =
          await svc.cacheImageOnDisk('http://example.com/img.jpg');
      expect(result.path, pkgFile.path);
    });

    test('rethrows exception on failure', () async {
      final mockCache = MockCacheManager();
      when(mockCache.getSingleFile(
        any,
        key: anyNamed('key'),
        headers: anyNamed('headers'),
      )).thenThrow(Exception('network error'));

      final svc = MemoryService(diskCache: mockCache);
      expect(
        () => svc.cacheImageOnDisk('http://example.com/fail.jpg'),
        throwsException,
      );
    });
  });

  // ── weather alert keys ────────────────────────────────────────────────────
  group('MemoryService – weather alert keys –', () {
    test('getShownWeatherAlertKeys returns empty set when nothing saved',
        () async {
      expect(await MemoryService().getShownWeatherAlertKeys(), isEmpty);
    });

    test('round-trip saveShownWeatherAlertKeys / getShownWeatherAlertKeys',
        () async {
      final svc = MemoryService();
      await svc.saveShownWeatherAlertKeys({'alert-1', 'alert-2'});
      final result = await svc.getShownWeatherAlertKeys();
      expect(result, containsAll(['alert-1', 'alert-2']));
      expect(result.length, 2);
    });

    test('hasShownWeatherAlertKey returns false when key not present',
        () async {
      expect(
          await MemoryService().hasShownWeatherAlertKey('missing'), isFalse);
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

    test('addShownWeatherAlertKey is idempotent', () async {
      final svc = MemoryService();
      await svc.addShownWeatherAlertKey('dup');
      await svc.addShownWeatherAlertKey('dup');
      expect((await svc.getShownWeatherAlertKeys()).length, 1);
    });

    test('overwriting with smaller set shrinks stored keys', () async {
      final svc = MemoryService();
      await svc.saveShownWeatherAlertKeys({'a', 'b', 'c', 'd'});
      await svc.saveShownWeatherAlertKeys({'only'});
      expect(await svc.getShownWeatherAlertKeys(), {'only'});
    });

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

  // ── error paths (catch branches) ──────────────────────────────────────────
  group('MemoryService – weather alert keys error paths –', () {
    test('getShownWeatherAlertKeys returns empty set when prefs throws',
        () async {
      final svc = _ThrowingPrefsService();
      expect(await svc.getShownWeatherAlertKeys(), isEmpty);
    });

    test('saveShownWeatherAlertKeys completes silently when prefs throws',
        () async {
      final svc = _ThrowingPrefsService();
      await expectLater(
          svc.saveShownWeatherAlertKeys({'k1', 'k2'}), completes);
    });

    test('hasShownWeatherAlertKey returns false when prefs throw', () async {
      final svc = _ThrowingPrefsService();
      expect(await svc.hasShownWeatherAlertKey('any'), isFalse);
    });

    test('addShownWeatherAlertKey completes silently when save throws',
        () async {
      final svc = _ThrowingPrefsService();
      await expectLater(svc.addShownWeatherAlertKey('x'), completes);
    });
  });
}

// ── helper classes ────────────────────────────────────────────────────────────

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
    } catch (_) {}
  }
}