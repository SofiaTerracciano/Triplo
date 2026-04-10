import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class WatchIdService {
  static const _storage = FlutterSecureStorage();
  static const _watchIdKey = 'watch_id';
  static const _uuid = Uuid();

  static Future<String> getOrCreateWatchId() async {

    final local = await _storage.read(key: _watchIdKey);
    if (local != null && local.isNotEmpty) {


      debugPrint("WatchIdService: usando watchId locale=$local");

      unawaited(_ensureWatchDoc(local));
      return local;
    }


    try {
      final watchId = await _createWatchDocOnFirestore()
          .timeout(const Duration(seconds: 4));
      await _storage.write(key: _watchIdKey, value: watchId);
      return watchId;
    } catch (e) {
      debugPrint("WatchIdService: Firestore non disponibile ($e). Uso UUID locale.");
      final fallback = _uuid.v4();
      await _storage.write(key: _watchIdKey, value: fallback);

      unawaited(_ensureWatchDoc(fallback));
      return fallback;
    }
  }

  static Future<String> _createWatchDocOnFirestore() async {
    final db = FirebaseFirestore.instance;
    debugPrint("WatchIdService: creo doc su /watch ...");
    final ref = await db.collection('watch').add({
      'platform': 'wearos',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
    debugPrint("WatchIdService: creato watchId=${ref.id}");
    return ref.id;
  }

  static Future<void> _ensureWatchDoc(String watchId) async {
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('watch').doc(watchId);

      final snap = await ref.get();
      if (!snap.exists) {

        await ref.set({
          'platform': 'wearos',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      } else {

        await ref.update({
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("WatchIdService ensureWatchDoc failed: $e");
    }
  }
}