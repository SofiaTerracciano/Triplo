import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const String _kLocaleCodeKey = 'locale_code';
  static const String _kShownWeatherAlertsKey = 'shown_weather_alert_keys';
  // Configurazione del CacheManager per il disco
  static final CacheManager _diskCache = CacheManager(
    Config(
      'triploImageCache',
      stalePeriod: const Duration(days: 12),
      maxNrOfCacheObjects: 200,
    ),
  );

  static final CacheManager _weatherAlertCache = CacheManager(
    Config(
      'triploWeatherAlertCache',
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 500,
    ),
  );






  String _alertKeyToCacheKey(String key) => 'weather_alert_$key';


  // Cache in memoria (RAM)
  final Map<String, File> _memoryCache = {};

  // Cache memory

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

  // RAM memory



  /// Recupera dalla memoria RAM. Se il file fisico è stato eliminato, pulisce la mappa.
  Future<File?> getImageFromMemory(String key) async {
    final file = _memoryCache[key];
    if (file == null) return null;

    if (await file.exists()) {
      return file;
    }

    _memoryCache.remove(key);
    return null;
  }

  void saveImageToMemory(String key, File file) {
    _memoryCache[key] = file;
  }

  void removeImageFromMemory(String key) {
    _memoryCache.remove(key);
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }






  Future<String?> getSavedLocaleCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLocaleCodeKey);
    } catch (e) {
      debugPrint("Errore recupero lingua salvata: $e"); //coverage:ignore-line
      return null;
    }
  }

  Future<void> saveLocaleCode(String localeCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleCodeKey, localeCode);
    } catch (e) {
      debugPrint("Errore salvataggio lingua: $e"); //coverage:ignore-line
      rethrow; 
    }
  }


  Future<Set<String>> getShownWeatherAlertKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kShownWeatherAlertsKey) ?? <String>[];
      return list.toSet();
    } catch (e) {
      debugPrint("Errore recupero alert mostrati: $e"); //coverage:ignore-line
      return <String>{};
    }
  }

  Future<void> saveShownWeatherAlertKeys(Set<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kShownWeatherAlertsKey, keys.toList());
    } catch (e) {
      debugPrint("Errore salvataggio alert mostrati: $e"); //coverage:ignore-line
      rethrow;
    }
  }

  Future<void> addShownWeatherAlertKey(String key) async {
    try {
      final cacheKey = _alertKeyToCacheKey(key);
      await _weatherAlertCache.putFile(
        cacheKey,
        Uint8List(0), // file vuoto serve solo come flag
        key: cacheKey,
        maxAge: const Duration(days: 1),
      );
    } catch (e) {
      debugPrint("Errore salvataggio alert mostrato: $e"); //coverage:ignore-line
    }
  }

  Future<bool> hasShownWeatherAlertKey(String key) async {
    try {
      final cacheKey = _alertKeyToCacheKey(key);
      final fileInfo = await _weatherAlertCache.getFileFromCache(cacheKey);

      return fileInfo != null;
    } catch (e) {
      debugPrint("Errore controllo alert mostrato: $e"); //coverage:ignore-line
      return false;
    }
  }


}