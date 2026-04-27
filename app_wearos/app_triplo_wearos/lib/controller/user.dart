import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../model/diary.dart';

import '../service/pairing_service.dart';
class UserController extends ChangeNotifier {
  late FirebaseFirestore _db;
  final PairingService _pairingService;

  Users? _currentUser;
  Users? get currentUser => _currentUser;

  String? get uid => _pairingService.pairedUid;

  UserController(this._pairingService, {FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<void> loadCurrentPairedUser() async {
    final uid = _pairingService.pairedUid;
    if (uid == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    await loadUserCore(uid);
  }

  Future<void> loadUserCore(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;

    _currentUser = Users.fromMap(data, uid: uid);

    notifyListeners();
  }

  Future<Users?> getUserById(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    return Users.fromMap(snap.data()!, uid: uid);
  }

  Future<List<Users>> getFollowers(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Followers"] ?? []);
    final users = await Future.wait(ids.map(getUserById));
    return users.whereType<Users>().toList();
  }

  Future<List<Users>> getFollowing(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Following"] ?? []);
    final users = await Future.wait(ids.map(getUserById));
    return users.whereType<Users>().toList();
  }

  Future<List<Users>> searchUsers(String query) async {
    final q = query.toLowerCase().trim();

    final snap = await _db
        .collection("users_index")
        .where("normalized", isGreaterThanOrEqualTo: q)
        .where("normalized", isLessThanOrEqualTo: "$q\uf8ff")
        .get();

    final List<Users> results = [];
    for (var d in snap.docs) {
      final user = await getUserById(d["uid"]);
      if (user != null) results.add(user);
    }
    return results;
  }

  Future<Diary?> getDiaryById(String id) async {
    final snap = await _db.collection("diary").doc(id).get();
    if (!snap.exists) return null;
    return Diary.fromMap(snap.data()!, diaryId: id);
  }

  Future<List<Diary>> getPublicDiaries(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Public_diary"] ?? []);
    final diaries = await Future.wait(ids.map(getDiaryById));
    return diaries.whereType<Diary>().toList();
  }

  Future<List<Diary>> getPrivateDiaries(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Private_diary"] ?? []);
    final diaries = await Future.wait(ids.map(getDiaryById));
    return diaries.whereType<Diary>().toList();
  }


  Future<List<String>> getFollowerUids(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final raw = snap.data()?["Followers"] ?? [];
    return List<String>.from(raw);
  }

  Future<List<String>> getFollowingUids(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final raw = snap.data()?["Following"] ?? [];
    return List<String>.from(raw);
  }
}