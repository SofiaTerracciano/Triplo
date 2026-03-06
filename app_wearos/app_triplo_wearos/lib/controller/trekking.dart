import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trekking.dart';
import 'package:flutter/material.dart';

// Controller for managing trekking data
class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Trekking> _trekkings;
  bool _loaded = false;

  TrekkingController({required List<Trekking> trekkings})
    : _trekkings = trekkings;

  // Getter for all trekkings
  List<Trekking> get allTrekkings => _trekkings;

  //Load trekkings from Firestore
  Future<void> loadTrekking() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db
        .collection('trekking') 
        .get();

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
    return await Future.wait(paths.map((path) async {
      Reference ref = FirebaseStorage.instance.refFromURL(path);
      return await ref.getDownloadURL();
    }));
  }

  // Fetch image URL from Firebase Storage given complete firestore url
  // It returns a only one download URL that can be used to display the image
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

  /* Search trekkings by name using normalized search in Firestore
  Future<List<Trekking>> searchTrekking(String query) async {
    final q = query.trim().toLowerCase();
    final snap = await _db
        .collection("trekking_index")
        .where("Normalized", isGreaterThanOrEqualTo: q)
        .where("Normalized", isLessThanOrEqualTo: "$q\uf8ff")
        .get();

    final List<Trekking> results = [];

    for (var d in snap.docs) {
      final trekkingId = d["Trekking_id"] as String;
      print(trekkingId);
      final trekking = getTrekkingById(trekkingId);
      if (trekking != null) results.add(trekking);
    }
    
    print(results);
    return results;
  }*/
}