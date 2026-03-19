import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/challenges.dart';

import '../service/notification.dart';
import '../service/memory.dart';
// Controller for managing challenges data from Firestore
class ChallengesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Challenges> _challenges;
  bool _loaded = false;


  NotificationService notification;
  MemoryService memory;


  ChallengesController({required this.notification, required this.memory}) : _challenges = [];

  // Getter for all trekkings
  List<Challenges> get allChallenges => _challenges;

  // Load challenges from Firestore
  Future<void> loadChallenges() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db
        .collection('challenges')
        .get();

    // Map documents to Trekking objects and store in the list --> this function create a
    //list of istance of trekkning (model)
    _challenges = snap.docs
        .map((doc) => Challenges.fromMap(doc.data(), docId: doc.id))
        .toList();

    notifyListeners();
  }

  // Callback when a trekking is selected
  void Function(Challenges challenges)? onTrekkingSelected;



  // Getter trekking per documentId
  Challenges? getChallengesById(String documentId) {
    try {
      return _challenges.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  // Fetch image URL from Firebase Storage given challenge complete firestore url
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

  Future<File?> getCachedImage(String imagePath) async {
    debugPrint("getCachedImage challenge -> $imagePath");

    try {
      // 1. RAM Cache (Corretto)
      final inMemory = await memory.getImageFromMemory(imagePath);
      if (inMemory != null) {
        debugPrint("Challenge image found in RAM cache");
        return inMemory;
      }

      String cacheableUrl = imagePath;

      if (imagePath.startsWith("gs://")) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        cacheableUrl = await ref.getDownloadURL();
      }

      final cached = await memory.getImageFromDisk(cacheableUrl);
      if (cached != null) {
        debugPrint("Challenge image found in disk cache");
        memory.saveImageToMemory(imagePath, cached);
        return cached;
      }

      debugPrint("Challenge image not in cache, downloading");
      final file = await memory.cacheImageOnDisk(cacheableUrl); 
      memory.saveImageToMemory(imagePath, file);
      return file;

    } catch (e) {
      debugPrint("getCachedImage challenge error: $e");
      return null;
    }
  }

  void notifyNewChallenge(String challengeType, AppLocalizations local) {
    final content = getChallengeContent(challengeType, local);
    
    notification.showTrekkingNotification(
      id: DateTime.now().millisecond,
      title: content['title']!,
      body: content['body']!,
      payload: challengeType,
    );
  }

}