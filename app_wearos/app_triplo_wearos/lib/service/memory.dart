import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

  // --- 2. MEMORIA PERSISTENTE (SharedPreferences) ---
  static const _kLocaleKey = "user_locale";
  static const _kFirstRunKey = "is_first_run";

  Future<void> saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, code);
  }

  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocaleKey);
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstRunKey) ?? true;
  }

  Future<void> setFirstRunDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstRunKey, false);
  }

  // --- 3. MEMORIA VOLATILE (RAM Cache) ---
  final Map<String, dynamic> _internalRamCache = {};

  void saveImageToMemory(String key, File file) {
    _internalRamCache[key] = file;
    debugPrint("Memory: salvata immagine $key in RAM");
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
    debugPrint("Memory: RAM pulita");
  }

  // --- 4. GESTIONE DISCO (Metodi usati dal Controller) ---

  /// Recupera un'immagine dalla cache su disco
  Future<File?> getImageFromDisk(String url) async {
    try {
      final fileInfo = await _diskCache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      debugPrint("Errore recupero disco: $e");
      return null;
    }
  }

  /// Scarica e salva un'immagine nella cache su disco
  Future<File> cacheImageOnDisk(String url) async {
    try {
      return await _diskCache.getSingleFile(url);
    } catch (e) {
      debugPrint("Errore salvataggio disco: $e");
      rethrow; 
    }
  }
}