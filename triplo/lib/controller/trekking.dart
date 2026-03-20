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

// Controller for managing trekking data
class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Trekking> _trekkings;
  bool _loaded = false;

  GeoService geo;
  MemoryService memory;
  NotificationService notification;

  TrekkingController({
    required this.geo,
    required this.memory,
    required this.notification,
    required List<Trekking> trekkings,
  }) : _trekkings = trekkings;

  // Getter for all trekkings
  List<Trekking> get allTrekkings => _trekkings;

  //Load trekkings from Firestore
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

  // Callback when a trekking is selected
  void Function(Trekking trekking)? onTrekkingSelected;

  // Getter trekking per documentId --> it return the trekking instance given the ID
  Trekking? getTrekkingById(String documentId) {
    try {
      return _trekkings.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  //Getter trekkingID by name --> if you have the name you can get the ID
  String? getTrekkingId(String name) {
    try {
      return _trekkings.firstWhere((t) => t.name == name).documentId;
    } catch (_) {
      return null;
    }
  }

  // Fetch image URLs from Firebase Storage given a list of complete firestore url
  // It returns a list of download URLs that can be used to display images
  Future<List<String>> getDownloadUrls(List<String> paths) async {
    return await Future.wait(
      paths.map((path) async {
        Reference ref = FirebaseStorage.instance.refFromURL(path);
        return await ref.getDownloadURL();
      }),
    );
  }

  // Fetch image URL from Firebase Storage given complete firestore url
  // It returns a only one download URL that can be used to display the image
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

  // Search trekkings by name using normalized search in Firestore
  Future<List<Trekking>> searchTrekking(String query) async {
    final q = query.trim().toLowerCase();
    final snap = await _db
        .collection("trekking_index")
        .where("Normalized", isGreaterThanOrEqualTo: q)
        .where("Normalized", isLessThanOrEqualTo: "$q\uf8ff")
        .get();

    final List<Trekking> results = [];

    // Funzione che serve a cercare su firestore nel caso non sia accora avventa la laod dei trekking
    // altrimenti cerca nella lista dei trekking già scaricati 
    for (var d in snap.docs) {
      final trekkingId = d["Trekking_id"] as String;
      
      // 1. Prova a cercarlo nella lista locale (veloce)
      var trekking = getTrekkingById(trekkingId);
      
      // 2. Se non c'è in locale, caricalo da Firestore (sicuro)
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

  Future<Trekking?> fetchTrekkingById(String id) async {
    final snap = await _db.collection("trekking").doc(id).get();
    if (!snap.exists) return null;
    return Trekking.fromMap(snap.data()!, docId: id);
  }

  Future<List<Trekking>> getSavedTrekkings(String uid) async {
    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final ids = List<String>.from(userSnap.data()?["Saved_trekkings"] ?? []);
    final trekkings = await Future.wait(ids.map(fetchTrekkingById));
    return trekkings.whereType<Trekking>().toList();
  }

  Future<void> addTrekkingToSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayUnion([trekkingId]),
    });

    notifyListeners();
  }

  Future<void> removeTrekkingFromSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayRemove([trekkingId]),
    });

    notifyListeners();
  }

  Future<bool> isTrekkingSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Saved_trekkings"] ?? []);
    return ids.contains(trekkingId);
  }

  Future<File?> getCachedImage(String imagePath) async {
    debugPrint("getCachedImage -> $imagePath");

    try {
      // 1. Cerca in RAM (questo è rimasto uguale)
      final inMemory = await memory.getImageFromMemory(imagePath);
      if (inMemory != null) {
        debugPrint("Image found in RAM cache");
        return inMemory;
      }

      String cacheableUrl = imagePath;

      if (imagePath.startsWith("gs://")) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        cacheableUrl = await ref.getDownloadURL();
      }

      // 2. ERRORE QUI: getImageFromCache -> DIVENTA -> getImageFromDisk
      final cached = await memory.getImageFromDisk(cacheableUrl); 
      if (cached != null) {
        debugPrint("Image found in disk cache");
        memory.saveImageToMemory(imagePath, cached);
        return cached;
      }

      debugPrint("Image not in cache, downloading");
      
      // 3. ERRORE QUI: cacheImage -> DIVENTA -> cacheImageOnDisk
      final file = await memory.cacheImageOnDisk(cacheableUrl); 
      memory.saveImageToMemory(imagePath, file);
      return file;
      
    } catch (e) {
      debugPrint("getCachedImage error: $e");
      return null;
    }
  }

  // Metodo per gestire l'arrivo
  Future<void> checkArrival(String trekkingId, double distanceInMeters, AppLocalizations local) async {
    // Se la distanza è inferiore a 1000 metri (o quella che preferisci)
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

  Future<List<File>> getCachedImages(List<String> imagePaths) async {
    final files = await Future.wait(
      imagePaths.map((path) async => await getCachedImage(path)),
    );

    return files.whereType<File>().toList();
  }
}
