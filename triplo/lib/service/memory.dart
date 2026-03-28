import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MemoryService {
  // Configurazione del CacheManager per il disco
  static final CacheManager _diskCache = CacheManager(
    Config(
      'triploImageCache',
      stalePeriod: const Duration(days: 12),
      maxNrOfCacheObjects: 200,
    ),
  );

  // Cache in memoria (RAM)
  final Map<String, File> _memoryCache = {};

  // Cache memory

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

  // RAM memory

  /// Recupera dalla memoria. Se il file fisico è stato eliminato, pulisce la mappa.
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


  //bisogna rimettere il salvataggio in memoria della lingua con shared preferences
  //lnaguage controller gestisce la logica, memory service il salvataggio in memoria
  //è stato rimesso in language controller ma language controller non dovrebbe parlare con shared preferences


}