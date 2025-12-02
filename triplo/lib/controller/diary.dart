import '../model/diary.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class DiaryController extends ChangeNotifier {
  List<Diary> _diaries;
  bool _loaded = false;

  DiaryController({required List<Diary> diaries}) 
  : _diaries = diaries;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Getter for all diaries
  List<Diary> get allTrekkings => _diaries;

  // Load diaries from Firestore
  Future<void> loadDiary() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;
    
    // Fetch diary documents from Firestore
    final snap = await _db
        .collection('diary') // andrà messo trekking
        .get();

    // Map documents to Diary objects and store in the list --> this function create a 
    //list of instance of diary (model)
    _diaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();

    notifyListeners();
  }

  // Callback when a trekking is selected
  void Function(Diary trekking)? onTrekkingSelected;

  // Getter trekking per documentId
  Diary? getDiaryById(String documentId) {
    try {
      return _diaries.firstWhere((t) => t.diaryId == documentId);
    } catch (_) {
      return null;
    }
  }
}