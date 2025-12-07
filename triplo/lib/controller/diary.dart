import 'package:triplo/model/diary.dart';
import 'package:triplo/model/user.dart';

import '../model/diary.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uuid/uuid.dart';

class DiaryController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Diary> _diaries = [];
  bool _loaded = false;
  Users? _currentUser;
  Users? get currentUser => _currentUser;

  DiaryController();

  // Getter for all diaries
  List<Diary> get allDiaries => _diaries;

  // Load public diaries from Firestore
  Future<void> loadPublicDiary(String userId) async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch diary documents from Firestore
    final snap = await _db
        .collection('diary')
        .where('userId', isEqualTo: userId)
        .where('Is_public', isEqualTo: true)
        .get();

    // Map documents to Diary objects and store in the list --> this function create a
    //list of instance of diary (model)
    /*_diaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();*/

    final publicDiaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();

    _diaries.addAll(publicDiaries);

    notifyListeners();
  }

  // Load private diaries from Firestore
  Future<void> loadPrivateDiary(String userId) async {
    // Fetch diary documents from Firestore
    final snap = await _db
        .collection('diary')
        .where('userId', isEqualTo: userId)
        .where('Is_public', isEqualTo: false)
        .get();

    // Map documents to Diary objects and store in the list --> this function create a
    //list of instance of diary (model)
    /*_diaries = snap.docs
        .map(
          (doc) => Diary.fromMap(doc.data(), diaryId: doc.id),
        )
        .toList();*/

    final privateDiaries = snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();

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

  Future<void> addDiary(
    String title,
    bool isPublic,
    String date,
    double duration,
    List<String> friends,
    List<String> photos,
    List<String> challenges,
    String refreshmentPoint,
    String mood,
    String notes,
    bool modify,
    String diaryId,
  ) async {
    final uid = _auth.currentUser!.uid;
    Diary page;
    if (!modify) {
      var newId = Uuid().v4();

      final doc = await _db.collection("diary").doc(newId).get();
      if (doc.exists) {
        newId = Uuid().v4();
      }

      final page = Diary(
        diaryId: newId,
        userId: uid,
        trekkigName: title,
        date: date,
        duration: duration,
        friends: friends,
        photos: photos,
        challenges: challenges,
        refreshmentPoint: refreshmentPoint,
        mood: mood,
        notes: notes,
        isPublic: isPublic,
      );
      _diaries.add(page);
      if (page.isPublic) {
        // Update DB
        await _db.collection("users").doc(uid).update({
          "Public_Diary": FieldValue.arrayUnion([page.diaryId]),
        });
        // Update local list
        _currentUser!.publicDiaryPages.add(page);
      } else {
        // Update DB
        await _db.collection("users").doc(uid).update({
          "Private_Diary": FieldValue.arrayUnion([page.diaryId]),
        });
        // Update local list
        _currentUser?.privateDiaryPages.add(page);
      }
      await _db.collection("diary").doc(page.diaryId).set(page.toMap());
    } else {
      page = getDiaryById(diaryId)!;
      page = updateDiary(
        page,
        isPublic,
        date,
        duration,
        friends,
        photos,
        challenges,
        refreshmentPoint,
        mood,
        notes,
      );
      await _db.collection("diary").doc(page.diaryId).set(page.toMap());
    }
    // Aggiorna la lista locale se il trekking esiste
    notifyListeners();
  }

  Diary updateDiary(
    Diary page,
    bool isPublic,
    String date,
    double duration,
    List<String> friends,
    List<String> photos,
    List<String> challenges,
    String refreshmentPoint,
    String mood,
    String notes,
  ) {
    page.date = date;
    page.duration = duration;
    page.friends = friends;
    page.photos = photos;
    page.challenges = challenges;
    page.refreshmentPoint = refreshmentPoint;
    page.mood = mood;
    page.notes = notes;
    page.isPublic = isPublic;

    return page;
  }

  Future<void> removeDiary(String diaryId) async {
    final page = getDiaryById(diaryId)!;
    final uid = _auth.currentUser!.uid;

    await _db.collection("diary").doc(diaryId).delete();
    _diaries.removeWhere((diary) => diary.diaryId == diaryId);

    if (page.isPublic) {
      // Remove from DB
      await _db.collection("users").doc(uid).update({
        "Public_Diary": FieldValue.arrayRemove([page.diaryId]),
      });
      // Remove from local list
      _currentUser?.publicDiaryPages.remove(page);
    } else {
      // Remove from DB
      await _db.collection("users").doc(uid).update({
        "Private_Diary": FieldValue.arrayRemove([page.diaryId]),
      });
      // Remove from local list
      _currentUser?.privateDiaryPages.remove(page);
    }

    notifyListeners();
  }
}
