import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  // --- 1. CONFIGURAZIONE CACHE DISCO ---
  // Definito come static final così esiste una sola istanza in tutta l'app
  static final CacheManager _diskCache = CacheManager(
    Config(
      'triploImageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  // --- 2. secondary storage (SharedPreferences and flutter secure storage) ---
  static const _kLocaleKey = "user_locale";
  //static const _kFirstRunKey = "is_first_run";
  static const String _kShownWeatherAlertsKey = 'shown_weather_alert_keys';
  static const String _kWatchIdKey = 'watch_id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Future<void> saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, code);
  }

  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocaleKey);
  }



  Future<void> saveWatchId(String watchId) async {
    await _secureStorage.write(key: _kWatchIdKey, value: watchId);
  }

  Future<String?> getWatchId() async {
    return _secureStorage.read(key: _kWatchIdKey);
  }

  //Future<bool> isFirstRun() async {
  //  final prefs = await SharedPreferences.getInstance();
  //  return prefs.getBool(_kFirstRunKey) ?? true;
  //}

  //Future<void> setFirstRunDone() async {
  //  final prefs = await SharedPreferences.getInstance();
  //  await prefs.setBool(_kFirstRunKey, false);
  //}

  // --- 3. MEMORIA VOLATILE (RAM Cache) ---
  final Map<String, dynamic> _internalRamCache = {};

  void saveImageToMemory(String key, File file) {
    _internalRamCache[key] = file;
    debugPrint("Memory: salvata immagine $key in RAM"); //coverage:ignore-line
  }

  Future<File?> getImageFromMemory(String key) async {
    final data = _internalRamCache[key];
    if (data is File) {
      if (await data.exists()) return data;
      _internalRamCache.remove(key);
    }
    return null;
  }

  void clearAllRam() {
    _internalRamCache.clear();
    debugPrint("Memory: RAM pulita"); //coverage:ignore-line
  }

  // --- 4. GESTIONE DISCO (Metodi usati dal Controller) ---

  /// Recupera un'immagine dalla cache su disco
  Future<File?> getImageFromDisk(String url) async {
    try {
      final fileInfo = await _diskCache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      debugPrint("Errore recupero disco: $e"); //coverage:ignore-line
      return null;
    }
  }

  /// Scarica e salva un'immagine nella cache su disco
  Future<File> cacheImageOnDisk(String url) async {
    try {
      return await _diskCache.getSingleFile(url);
    } catch (e) {
      debugPrint("Errore salvataggio disco: $e"); //coverage:ignore-line
      rethrow;  
    }
  }

  Future<Set<String>> getShownWeatherAlertKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kShownWeatherAlertsKey) ?? <String>[];
      return list.toSet();
    } catch (e) {
      debugPrint("Errore recupero alert mostrati: $e");
      return <String>{};
    }
  }

  Future<void> saveShownWeatherAlertKeys(Set<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kShownWeatherAlertsKey, keys.toList());
    } catch (e) {
      debugPrint("Errore salvataggio alert mostrati: $e");
    }
  }

  Future<bool> hasShownWeatherAlertKey(String key) async {
    final keys = await getShownWeatherAlertKeys();
    return keys.contains(key);
  }

  Future<void> addShownWeatherAlertKey(String key) async {
    final keys = await getShownWeatherAlertKeys();
    keys.add(key);
    await saveShownWeatherAlertKeys(keys);
  }
}