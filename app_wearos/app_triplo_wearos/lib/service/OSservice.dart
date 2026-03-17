import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OSService {
  
  // --- POSIZIONE GPS ---
  Future<LatLng?> userLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Su Wear OS il fix del GPS può essere lento, mettiamo un timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), 
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location (probabilmente permessi mancanti o timeout): $e");
      return null;
    }
  }

  // --- GESTIONE LINGUA / LOCALE ---
  static const _kLocaleCodeKey = "locale_code";

  Future<String?> loadLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocaleCodeKey);
  }

  Future<void> saveLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCodeKey, code);
  }

  // --- CACHE MANAGER (Configurazione per Wear OS) ---
  final CacheManager _cache = CacheManager(
    Config(
      'triploImageCache',
      stalePeriod: const Duration(days: 7), // Ridotto per risparmiare spazio
      maxNrOfCacheObjects: 50,             // Gli smartwatch hanno poca memoria
    ),
  );

  Future<File?> getImageFromCache(String url) async {
    try {
      final fileInfo = await _cache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      debugPrint("getImageFromCache error: $e");
      return null;
    }
  }

  Future<File?> cacheImage(String url) async {
    try {
      // getSingleFile scarica e restituisce il file
      return await _cache.getSingleFile(url);
    } catch (e) {
      debugPrint("cacheImage error: $e");
      return null; 
    }
  }

  // --- MEMORY CACHE ---
  final Map<String, File> _memoryImageCache = {};

  Future<File?> getImageFromMemory(String key) async {
    final file = _memoryImageCache[key];
    if (file == null) return null;

    if (await file.exists()) {
      return file;
    }

    _memoryImageCache.remove(key);
    return null;
  }

  void saveImageToMemory(String key, File file) {
    _memoryImageCache[key] = file;
  }

  void removeImageFromMemory(String key) {
    _memoryImageCache.remove(key);
  }

  void clearMemoryImageCache() {
    _memoryImageCache.clear();
  }
}