
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:triplo/model/challenges.dart';
// Controller for managing challenges data from Firestore
class ChallengesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Challenges> _challenges;
  bool _loaded = false;


  ChallengesController():
        _challenges = []
  ;

  // Getter for all trekkings
  List<Challenges> get allChallenges => _challenges;

  // Load trekkings from Firestore
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



}