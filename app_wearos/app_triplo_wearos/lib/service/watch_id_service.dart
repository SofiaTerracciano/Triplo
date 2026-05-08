import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'OSservice/memory.dart';

class WatchIdService {
  //static final MemoryService _memoryService = MemoryService();
  static const _uuid = Uuid();

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;
  static MemoryService memoryService = MemoryService();

  static Future<void> _anonymousAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  static Future<String> getOrCreateWatchId() async {
    await _anonymousAuth();
    final local = await memoryService.getWatchId();
    if (local != null && local.isNotEmpty) {
      debugPrint("WatchIdService: usando watchId locale=$local"); //coverage:ignore-line

      unawaited(_ensureWatchDoc(local));
      return local;
    }

    try {
      final watchId = await _createWatchDocOnFirestore()
          .timeout(const Duration(seconds: 4));
      await memoryService.saveWatchId(watchId);
      return watchId;
    } catch (e) {
      debugPrint("WatchIdService: Firestore non disponibile ($e). Uso UUID locale."); //coverage:ignore-line
      final fallback = _uuid.v4();
      await memoryService.saveWatchId(fallback);

      unawaited(_ensureWatchDoc(fallback));
      return fallback;
    }
  }

  static Future<String> _createWatchDocOnFirestore() async {
    final db = firestore;
    debugPrint("WatchIdService: creo doc su /watch ..."); //coverage:ignore-line
    final ref = await db.collection('watch').add({
      'platform': 'wearos',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
    debugPrint("WatchIdService: creato watchId=${ref.id}"); //coverage:ignore-line
    return ref.id;
  }

  static Future<void> _ensureWatchDoc(String watchId) async {
    try {
      final db = firestore;
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
      debugPrint("WatchIdService ensureWatchDoc failed: $e"); //coverage:ignore-line
    }
  }

  @visibleForTesting
  static Future<void> ensureWatchDocForTest(
    FirebaseFirestore db,
    String watchId,
  ) async {
    firestore = db;
    await _ensureWatchDoc(watchId);
  }
}