import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/challenges.dart';
import '../service/notification.dart';
import '../service/memory.dart';

/// Controller responsible for managing "Challenges" data.
/// It handles fetching challenges from Firestore, managing image caching
/// for challenge badges/icons, and triggering challenge-related notifications.
class ChallengesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Challenges> _challenges;
  bool _loaded = false;

  /// Service used to trigger local push notifications.
  NotificationService notification;

  /// Service used for multi-level image caching (RAM and Disk).
  MemoryService memory;

  ChallengesController({required this.notification, required this.memory})
    : _challenges = [];

  /// Returns the local list of all loaded challenge instances.
  List<Challenges> get allChallenges => _challenges;

  /// Loads all challenge documents from the 'challenges' collection in Firestore.
  /// Prevents multiple network requests by using the [_loaded] flag.
  Future<void> loadChallenges() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db.collection('challenges').get();

    // Map documents to Trekking objects and store in the list --> this function create a
    // list of istance of trekkning (model)
    _challenges = snap.docs
        .map((doc) => Challenges.fromMap(doc.data(), docId: doc.id))
        .toList();

    notifyListeners();
  }

  // Callback triggered when a specific challenge is selected in the UI.
  void Function(Challenges challenges)? onTrekkingSelected;

  /// Retrieves a specific challenge from the local cache using its [documentId].
  /// Returns null if the challenge is not found.
  Challenges? getChallengesById(String documentId) {
    try {
      return _challenges.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the public download URL for a challenge image given its Firebase Storage path.
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

  // Manages image caching for challenge icons/badges.
  /// 1. Checks the RAM cache via [MemoryService].
  /// 2. If missing, checks the local device disk.
  /// 3. If still missing, downloads the image from Firebase Storage and updates both caches.
  Future<File?> getCachedImage(String imagePath) async {
    debugPrint("getCachedImage challenge -> $imagePath");

    try {
      // Attempt to retrieve from RAM
      final inMemory = await memory.getImageFromMemory(imagePath);
      if (inMemory != null) {
        debugPrint("Challenge image found in RAM cache");
        return inMemory;
      }

      String cacheableUrl = imagePath;

      // Convert gs:// protocol to a downloadable HTTPS URL if necessary
      if (imagePath.startsWith("gs://")) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        cacheableUrl = await ref.getDownloadURL();
      }

      // Attempt to retrieve from local disk storage
      final cached = await memory.getImageFromDisk(cacheableUrl);
      if (cached != null) {
        debugPrint("Challenge image found in disk cache");
        memory.saveImageToMemory(imagePath, cached);
        return cached;
      }

      // Download from network and persist in local caches
      debugPrint("Challenge image not in cache, downloading");
      final file = await memory.cacheImageOnDisk(cacheableUrl);
      memory.saveImageToMemory(imagePath, file);
      return file;
    } catch (e) {
      debugPrint("getCachedImage challenge error: $e");
      return null;
    }
  }

  /// Triggers a local notification when a new challenge is unlocked or completed.
  /// [challengeType] represents the key used to fetch localized content.
  /// [local] is the [AppLocalizations] instance used to translate the message.
  /// Triggers a local notification when a new challenge is unlocked or completed.
  void notifyNewChallenge(String challengeType, AppLocalizations local) {
  final content = getChallengeContent(challengeType, local);

  notification.showTrekkingNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
    title: content['title'] ?? "Challenge",
    body: content['body'] ?? "",
    payload: challengeType,
  );
}

}
