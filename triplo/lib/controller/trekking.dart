import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trekking.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Trekking> _trekkings;
  bool _loaded = false;


  TrekkingController({required List<Trekking> trekkings})
    : _trekkings = trekkings;

  // Getter for all trekkings
  List<Trekking> get allTrekkings => _trekkings;

  // Load trekkings from Firestore
  Future<void> loadTrekking() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db
        .collection('trekkings') // andrà messo trekking
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

  // Getter trekking per documentId
  Trekking? getTrekkingById(String documentId) {
    try {
      return _trekkings.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  

  // Fetch image URLs from Firebase Storage given their paths
  Future<List<String>> getDownloadUrls(List<String> paths) async {
    return await Future.wait(paths.map((path) async {
      Reference ref = FirebaseStorage.instance.refFromURL(path);
      return await ref.getDownloadURL();
    }));
  }


}