import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/user.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

// Controller for managing diary data from and to Firestore
class DiaryController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
    _loaded = true;

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

  // Update diary page
  Diary updateDiary(
    Diary page,
    bool isPublic,
    String date,
    double duration,
    List<String> friends,
    List<String> photos,
    List<String> challenges,
    String refreshmentPoint,
    List<String> mood,
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

  // Getter diaries per documentId
  Diary? getDiaryById(String documentId) {
    try {
      return _diaries.firstWhere((t) => t.diaryId == documentId);
    } catch (_) {
      return null;
    }
  }

  // Add or modify diary page based on 'modify' flag
  Future<void> addDiary(
    String title,
    bool isPublic,
    String date,
    double duration,
    List<String> friends,
    List<String> photos,
    List<String> challenges,
    String refreshmentPoint,
    List<String> mood,
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

      // Update user's diary lists
      if (page.isPublic) {
        // Update DB
        await _db.collection("users").doc(uid).update({
          "Public_diary": FieldValue.arrayUnion([page.diaryId]),
        });
        // Update local list
        _currentUser!.publicDiaryPages.add(page);
      } else {
        // Update DB
        await _db.collection("users").doc(uid).update({
          "Private_diary": FieldValue.arrayUnion([page.diaryId]),
        });
        // Update local list
        _currentUser!.privateDiaryPages.add(page);
      }
      // Create diary document
      await _db.collection("diary").doc(page.diaryId).set(page.toMap());
    } else {
      final uid = _auth.currentUser!.uid;
      page = getDiaryById(diaryId)!;
      final oldIsPublic = page.isPublic;
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

      // Update diary document
      await _db
      .collection("diary")
      .doc(page.diaryId)
      .update(page.toMap());


      // If privacy changed, update user's diary lists
      if (oldIsPublic != isPublic) {
        await _db.collection("users").doc(uid).update({
          oldIsPublic ? "Public_diary" : "Private_diary":
              FieldValue.arrayRemove([page.diaryId]),
          isPublic ? "Public_diary" : "Private_diary": FieldValue.arrayUnion([
            page.diaryId,
          ]),
        });
      }

      notifyListeners();
    }
  }

  // Remove diary page
  Future<void> removeDiary(String diaryId) async {
    final page = getDiaryById(diaryId)!;
    final uid = _auth.currentUser!.uid;

    await _db.collection("diary").doc(diaryId).delete();
    _diaries.removeWhere((diary) => diary.diaryId == diaryId);

    // Update user's diary lists based on privacy
    if (page.isPublic) {
      // Remove from DB
      await _db.collection("users").doc(uid).update({
        "Public_diary": FieldValue.arrayRemove([page.diaryId]),
      });
      // Remove from local list
      _currentUser?.publicDiaryPages.remove(page);
    } else {
      // Remove from DB
      await _db.collection("users").doc(uid).update({
        "Private_diary": FieldValue.arrayRemove([page.diaryId]),
      });
      // Remove from local list
      _currentUser?.privateDiaryPages.remove(page);
    }

    notifyListeners();
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

  // Upload diary images to Firebase Storage and return their paths --> it returns a path child
  // not the complete url
  Future<List<String>> uploadDiaryImages(List<File> images) async {
    List<String> paths = [];

    for (File image in images) {
      String extension = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) continue;

      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.$extension';
      final path = 'Diary_photos/$fileName';
      final ref = FirebaseStorage.instance.ref().child(path);

      try {
        // Upload file
        await ref.putFile(image);
        // Aggiungi il path
        paths.add(path);
      } catch (e) {
        debugPrint('Errore caricando immagine: $e');
      }
    }

    return paths;
  }

  // Fetch image URL from Firebase Storage given only path
  Future<String?> getDownloadUrlChild(String? path) async {
    // If you don't have any photos return null
    if (path == null || path.isEmpty) return null;

    try {
      Reference ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  // Fetch image URL from Firebase Storage given complete firestore url
  Future<String?> getDownloadUrl(String? path) async {
    // If you don't have any return null
    if (path == null || path.isEmpty) return null;

    try {
      Reference ref = FirebaseStorage.instance.refFromURL(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  // Delete photo from diary both in Firestore and Firebase Storage
  Future<void> deletePhotoFromDb(String diaryId, String photoPath) async {
    try {
      // Remove from Firestore
      await _db.collection('diary').doc(diaryId).update({
        "Photos": FieldValue.arrayRemove([photoPath]),
      });

      // Delete from firebase Storage using path
      final ref = FirebaseStorage.instance.ref().child(photoPath);
      await ref.delete();

      // Update locale state
      final diary = getDiaryById(diaryId);
      diary?.photos.remove(photoPath);

      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting photo: $e");
    }
  }

  // Fetch random public diaries from users being followed --> it returns a list of diaries
  // used for the explore page
  Future<List<Diary>> getRandomPublicDiariesFromFollowing({
    required List<String> followingIds,
    required int limit,
  }) async {
    final snap = await _db
        .collection('diary')
        .where('UserId', whereIn: followingIds)
        .where('Is_public', isEqualTo: true)
        .get();

    final diaries = snap.docs.map((doc) {
      final data = doc.data();

      // Normaliz frineds --> make sure it's a list of strings
      List<String> friends = [];
      if (data["Friends"] is List) {
        friends = List<String>.from(data["Friends"]);
      }

      // Normaliz photos --> make sure it's a list of strings
      List<String> photos = [];
      if (data["Photos"] is List) {
        photos = List<String>.from(data["Photos"]);
      } else if (data["Photos"] is String) {
        photos = [data["Photos"]];
      }

      // Normaliz challenges --> make sure it's a list of strings
      List<String> challenges = [];
      if (data["Challenges"] is List) {
        challenges = List<String>.from(data["Challenges"]);
      } else if (data["Challenges"] is String) {
        challenges = [data["Challenges"]];
      }

      // Normaliz mood --> make sure it's a list of strings
      List<String> mood = [];
      if (data["Mood"] is List) {
        mood = List<String>.from(data["Mood"]);
      } else if (data["Mood"] is String) {
        mood = [data["Mood"]];
      }

      // Create Diary instance --> return the diary instance
      return Diary(
        diaryId: doc.id,
        userId: data["UserId"] ?? "",
        trekkigName: data["Trekking_name"] ?? "Unknown Trek",
        date: data["Date"] ?? "",
        duration: (data["Duration"] ?? 0).toDouble(),
        friends: friends,
        photos: photos,
        challenges: challenges,
        refreshmentPoint: data["Refreshment_point"] ?? "",
        mood: mood,
        notes: data["Notes"] ?? "",
        isPublic: data["Is_public"] ?? false,
      );
    }).toList();

    // Shuffle and limit results --> to have random diaries
    diaries.shuffle();
    // Return only up to the specified limit --> to limit the number of diaries shown (only 10)
    return diaries.take(limit).toList();
  }

  Future<List<Diary>> getPublicDiaries(String userId) async {
    final snap = await _db
        .collection('diary')
        .where('UserId', isEqualTo: userId)
        .where('Is_public', isEqualTo: true)
        .get();

    return snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();
  }

  Future<List<Diary>> getPrivateDiaries(String userId) async {
    final snap = await _db
        .collection('diary')
        .where('UserId', isEqualTo: userId)
        .where('Is_public', isEqualTo: false)
        .get();

    return snap.docs
        .map((doc) => Diary.fromMap(doc.data(), diaryId: doc.id))
        .toList();
  }

  // Scarica il trekking specifico da Firestore e lo aggiunge alla cache (lista locale _trekkings)
  // prima controlla se esiste già in locale (quindi se c'è già stato un load)  
  Future<Diary?> getDiaryByIdAsync(String diaryId) async {
    // 1. Cerca prima in locale
    final local = getDiaryById(diaryId);
    if (local != null) return local;

    // 2. Se non c'è, cercalo su Firestore
    try {
      final doc = await _db.collection('diary').doc(diaryId).get();
      if (doc.exists) {
        final diary = Diary.fromMap(doc.data()!, diaryId: doc.id);
        // Opzionale: aggiungilo alla lista locale per il futuro ??
        _diaries.add(diary); 
        return diary;
      }
    } catch (e) {
      debugPrint("Errore recupero diario singolo: $e");
    }
    return null;
  }
}
