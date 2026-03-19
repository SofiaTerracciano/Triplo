import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/model/user.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Controller for managing diary data from and to Firestore
class DiaryController extends ChangeNotifier {
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Diary> _diaries = [];
  bool _loaded = false;
  Users? _currentUser;

  Users? get currentUser => _currentUser;

  set currentUser(Users user) {
    _currentUser = user;
  }

  DiaryController();

  // Getter for all diaries
  List<Diary> get allDiaries => _diaries;

  // Load public diaries from Firestore
  Future<void> loadPublicDiary(String userId) async {
    if (_loaded) return; // To avoid reloading


    // Fetch diary documents from Firestore
    final snap = await _db
        .collection('diary')
        .where('UserId', isEqualTo: userId)
        .where('Is_public', isEqualTo: true)
        .get();

    // Map documents to Diary objects and store in the list --> this function create a
    //list of instance of diary (model)
    final publicDiaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();

    // Add public diaries to the list
    _diaries.addAll(publicDiaries);

    notifyListeners();
  }

  // Load private diaries from Firestore
  Future<void> loadPrivateDiary(String userId) async {
    // Fetch diary documents from Firestore
    final snap = await _db
        .collection('diary')
        .where('UserId', isEqualTo: userId)
        .where('Is_public', isEqualTo: false)
        .get();

    // Map documents to Diary objects and store in the list --> this function create a
    //list of instance of diary (model)
    final privateDiaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();

    // Add private diaries to the list
    _diaries.addAll(privateDiaries);

    notifyListeners();
  }

  // Getter diaries per documentId
Diary? getDiaryById(String documentId) {
    try {
      return _diaries.firstWhere((t) => t.diaryId == documentId);
    } catch (_) {
      return null;
    }
  }

  // Fetch diaries by user ID --> it returns a list of diaries for a specific user
  Future<List<Diary>?> fetchDiaryById(String userId) async {
    final doc = await _db
        .collection('diary')
        .where('UserId', isEqualTo: userId)
        .get();

    if (doc.docs.isNotEmpty) {
      return doc.docs
          .map(
            (docSnapshot) =>
                Diary.fromMap(docSnapshot.data(), diaryId: docSnapshot.id),
          )
          .toList();
    } else {
      return null;
    }
  }
}
