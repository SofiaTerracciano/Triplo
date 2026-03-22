import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/service/geo.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/notification.dart';
import '../model/trekking.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

 /// Controller responsible for managing trekking data, handling 
 /// synchronization with Firestore, image caching, and user favorites.
class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Trekking> _trekkings;
  bool _loaded = false;

  // Services used for geolocation, local storage, and push notifications
  GeoService geo;
  MemoryService memory;
  NotificationService notification;

  TrekkingController({
    required this.geo,
    required this.memory,
    required this.notification,
    required List<Trekking> trekkings,
  }) : _trekkings = trekkings;

  /// Returns the local list of all loaded trekking instances.
  List<Trekking> get allTrekkings => _trekkings;

  /// Loads the full list of trekking documents from Firestore.
  /// Prevents redundant network calls by checking the [_loaded] flag.
  Future<void> loadTrekking() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db.collection('trekking').get();

    // Map documents to Trekking objects and store in the list --> this function create a
    //list of istance of trekkning (model)
    _trekkings = snap.docs
        .map((doc) => Trekking.fromMap(doc.data(), docId: doc.id))
        .toList();

    notifyListeners();
  }

  /// Optional callback triggered when a specific trekking is selected in the UI
  void Function(Trekking trekking)? onTrekkingSelected;

  /// Retrieves a trekking instance from the local list using its unique document ID.
  /// Returns null if no match is found.
  Trekking? getTrekkingById(String documentId) {
    try {
      return _trekkings.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  /// Finds the document ID associated with a trekking name.
  String? getTrekkingId(String name) {
    try {
      return _trekkings.firstWhere((t) => t.name == name).documentId;
    } catch (_) {
      return null;
    }
  }

  /// Converts a list of Firebase Storage paths (gs://) into usable download URLs.
  Future<List<String>> getDownloadUrls(List<String> paths) async {
    return await Future.wait(
      paths.map((path) async {
        Reference ref = FirebaseStorage.instance.refFromURL(path);
        return await ref.getDownloadURL();
      }),
    );
  }

  /// Converts a single Firebase Storage path (gs://) into a download URL.
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

  /// Performs a search on the 'trekking_index' collection using a normalized query.
  /// Checks the local cache first before fetching missing trekking data from Firestore.
  Future<List<Trekking>> searchTrekking(String query) async {
    final q = query.trim().toLowerCase();
    final snap = await _db
        .collection("trekking_index")
        .where("Normalized", isGreaterThanOrEqualTo: q)
        .where("Normalized", isLessThanOrEqualTo: "$q\uf8ff")
        .get();

    // Try local cache first for performance
    final List<Trekking> results = [];

    // If not in cache, fetch directly from the main trekking collection
    for (var d in snap.docs) {
      final trekkingId = d["Trekking_id"] as String;

      // Try to search in local list
      var trekking = getTrekkingById(trekkingId);

      // If there is not, search on Firestore
      if (trekking == null) {
        trekking = await fetchTrekkingById(trekkingId);
      }

      if (trekking != null) {
        results.add(trekking);
      }
    }

    return results;

    /*for (var d in snap.docs) {
      final trekkingId = d["Trekking_id"] as String;
      final trekking = await getTrekkingById(trekkingId);
      if (trekking != null) 
        results.add(trekking);
    }

    return results;*/
  }

  /// Fetches a specific trekking document from Firestore by its ID.
  Future<Trekking?> fetchTrekkingById(String id) async {
    final snap = await _db.collection("trekking").doc(id).get();
    if (!snap.exists) return null;
    return Trekking.fromMap(snap.data()!, docId: id);
  }

  /// Retrieves all trekking items saved as favorites by a specific user.
  Future<List<Trekking>> getSavedTrekkings(String uid) async {
    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final ids = List<String>.from(userSnap.data()?["Saved_trekkings"] ?? []);
    final trekkings = await Future.wait(ids.map(fetchTrekkingById));
    return trekkings.whereType<Trekking>().toList();
  }

  /// Adds a trekking ID to the current user's 'Saved_trekkings' array in Firestore.
  Future<void> addTrekkingToSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayUnion([trekkingId]),
    });

    notifyListeners();
  }

  /// Removes a trekking ID from the current user's 'Saved_trekkings' array in Firestore.
  Future<void> removeTrekkingFromSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayRemove([trekkingId]),
    });

    notifyListeners();
  }

  /// Checks if a specific trekking ID exists in the user's favorites list.
  Future<bool> isTrekkingSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Saved_trekkings"] ?? []);
    return ids.contains(trekkingId);
  }

  /// Manages a multi-layer image cache:
  /// 1. Checks RAM (MemoryService).
  /// 2. Checks Disk (Local file storage).
  ///3. Downloads from Storage/Network if not found locally.
  Future<File?> getCachedImage(String imagePath) async {
    debugPrint("getCachedImage -> $imagePath");

    try {
      // Search in RAM
      final inMemory = await memory.getImageFromMemory(imagePath);
      if (inMemory != null) {
        debugPrint("Image found in RAM cache");
        return inMemory;
      }

      String cacheableUrl = imagePath;

      // Handle Firebase gs:// protocol conversion
      if (imagePath.startsWith("gs://")) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        cacheableUrl = await ref.getDownloadURL();
      }

      // Search in local disk storage
      final cached = await memory.getImageFromDisk(cacheableUrl);
      if (cached != null) {
        debugPrint("Image found in disk cache");
        memory.saveImageToMemory(imagePath, cached);
        return cached;
      }

      // Download and save to disk/memory caches
      debugPrint("Image not in cache, downloading");
      final file = await memory.cacheImageOnDisk(cacheableUrl);
      memory.saveImageToMemory(imagePath, file);
      return file;
    } catch (e) {
      debugPrint("getCachedImage error: $e");
      return null;
    }
  }

  /// Monitors user's proximity to a trekking destination.
  /// Triggers a push notification when the user is within 1000 meters.
  Future<void> checkArrival(
    String trekkingId,
    double distanceInMeters,
    AppLocalizations local,
  ) async {
    if (distanceInMeters <= 1000) {
      final content = getChallengeContent('end_trekking_arrival', local);

      await notification.showTrekkingNotification(
        id: 999,
        title: content['title']!,
        body: content['body']!,
        payload: 'end_trekking_arrival',
        channelId: 'arrival_channel',
        channelName: 'Arrivo Trekking',
      );
    }
  }

  /// Batched version of getCachedImage to handle multiple image paths simultaneously.
  Future<List<File>> getCachedImages(List<String> imagePaths) async {
    final files = await Future.wait(
      imagePaths.map((path) async => await getCachedImage(path)),
    );

    return files.whereType<File>().toList();
  }

  /// Retrieves a specific trekking item. 
  /// It checks the local cache first; if missing, it fetches it from Firestore 
  /// and updates the local list for future use.
  Future<Trekking?> getTrekkingByIdAsync(String trekkingId) async {
    // Search on local list
    try {
      return _trekkings.firstWhere((t) => t.documentId == trekkingId);
    } catch (_) {
      // if there is not, search on Firestore
      try {
        final doc = await _db.collection('trekking').doc(trekkingId).get();
        if (doc.exists) {
          final trekking = Trekking.fromMap(doc.data()!, docId: doc.id);
          // Add to local list to minimize future Firestore reads
          _trekkings.add(trekking);
          notifyListeners();

          return trekking;
        }
      } catch (e) {
        debugPrint("Errore to find the trekking: $e");
      }
    }
    return null;
  }
}
