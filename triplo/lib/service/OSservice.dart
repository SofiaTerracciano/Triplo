import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OSService {

  Future<LatLng?> userLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }



  static const _kLocaleCodeKey = "locale_code";

  Future<String?> loadLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocaleCodeKey);
  }

  Future<void> saveLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCodeKey, code);
  }

  final CacheManager _cache = CacheManager(
    Config(
      'triploImageCache',
      stalePeriod: const Duration(days: 12),
      maxNrOfCacheObjects: 200,
    ),
  );

  Future<File?> getImageFromCache(String url) async {
    try {
      final file = await _cache.getFileFromCache(url);
      return file?.file;
    } catch (e) {
      debugPrint("getImageFromCache error: $e");
      return null;
    }
  }

  Future<File> cacheImage(String url) async {
    try {
      return await _cache.getSingleFile(url);
    } catch (e) {
      debugPrint("cacheImage error: $e");
      rethrow;
    }
  }




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