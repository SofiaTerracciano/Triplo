import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/user.dart';
import '../model/diary.dart';
import '../model/trekking.dart';

class UserController extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Users? _currentUser;
  Users? get currentUser => _currentUser;

  /* --------------------------------------------------
   * AUTH
   * -------------------------------------------------- */

  Future<void> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection("users").doc(uid).set({
      "Username": email.split("@")[0],
      "Photo_profile": "",
      "Name": "",
      "Surname": "",
      "Birthdate": DateTime.now().toIso8601String(),
      "Email": email,
      "Followers": [],
      "Following": [],
      "Public_diary": [],
      "Private_diary": [],
      "Saved_trekkings": [],
      "Level": "Beginner",
      "Advanced": 0,
      "Intermediate": 0,
    });

    await loadUserCore(uid);
  }

  Future<void> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await loadUserCore(cred.user!.uid);
  }

  Future<void> loginWithGoogle(AuthCredential credential) async {
    final cred = await _auth.signInWithCredential(credential);
    await loadUserCore(cred.user!.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /* --------------------------------------------------
   * LOAD CORE USER (NO PRELOAD)
   * -------------------------------------------------- */

  Future<void> loadUserCore(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;

    _currentUser = Users(
      uid: uid,
      username: data["Username"] ?? "",
      name: data["Name"] ?? "",
      surname: data["Surname"] ?? "",
      email: data["Email"] ?? "",
      photoProfile: data["Photo_profile"] ?? "",
      birthdate:
      DateTime.tryParse(data["Birthdate"] ?? "") ?? DateTime(2000, 1, 1),

      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],

      level: data["Level"] ?? "Beginner",
      advanced: data["Advanced"] ?? 0,
      intermediate: data["Intermediate"] ?? 0,
    );

    notifyListeners();
  }

  /* --------------------------------------------------
   * PUBLIC USERS
   * -------------------------------------------------- */

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

  Future<List<String>> getFollowingIds(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    return List<String>.from(snap.data()?["Following"] ?? []);
  }

  /* --------------------------------------------------
   * SEARCH
   * -------------------------------------------------- */

  Future<List<Users>> searchUsers(String query) async {
    final snap = await _db
        .collection("users_index")
        .where("username", isGreaterThanOrEqualTo: query)
        .where("username", isLessThanOrEqualTo: "$query\uf8ff")
        .get();

    final List<Users> results = [];

    for (var d in snap.docs) {
      final user = await getUserById(d["uid"]);
      if (user != null) results.add(user);
    }

    return results;
  }

  /* --------------------------------------------------
   * DIARY
   * -------------------------------------------------- */

  Future<Diary?> getDiaryById(String id) async {
    final snap = await _db.collection("diary").doc(id).get();
    if (!snap.exists) return null;
    return Diary.fromMap(snap.data()!, diaryId: id);
  }






  // =======================
// DIARY LISTS
// =======================

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

// =======================
// SAVED TREKKINGS
// =======================

  Future<List<Trekking>> getSavedTrekkings(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Saved_trekkings"] ?? []);

    final trekkings = await Future.wait(ids.map(getTrekkingById));
    return trekkings.whereType<Trekking>().toList();
  }

  /* --------------------------------------------------
   * TREKKING
   * -------------------------------------------------- */

  Future<Trekking?> getTrekkingById(String id) async {
    final snap = await _db.collection("trekking").doc(id).get();
    if (!snap.exists) return null;
    return Trekking.fromMap(snap.data()!, docId: id);
  }

  Future<void> addTrekkingToSaved(String trekkingId) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayUnion([trekkingId])
    });
  }

  Future<void> removeTrekkingFromSaved(String trekkingId) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayRemove([trekkingId])
    });
  }

  /* --------------------------------------------------
   * PROFILE UPDATE
   * -------------------------------------------------- */

  Future<void> updateUsername(String username) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({"Username": username});
    _currentUser?.username = username;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({"Name": name});
    _currentUser?.name = name;
    notifyListeners();
  }

  Future<void> updateSurname(String surname) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({"Surname": surname});
    _currentUser?.surname = surname;
    notifyListeners();
  }

  Future<void> updateBirthdate(DateTime date) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({
      "Birthdate": date.toIso8601String()
    });
    _currentUser?.birthdate = date;
    notifyListeners();
  }

  Future<void> updateProfilePhoto(File image) async {
    final uid = _auth.currentUser!.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_photos")
        .child(uid)
        .child("$uid.jpg");

    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    await _db.collection("users").doc(uid).update({
      "Photo_profile": url
    });

    _currentUser?.photoProfile = url;
    notifyListeners();
  }

  /* --------------------------------------------------
   * PASSWORD
   * -------------------------------------------------- */

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> requestPasswordReset() async {
    if (_currentUser?.email == null) return;
    await _auth.sendPasswordResetEmail(email: _currentUser!.email);
  }

  /* --------------------------------------------------
   * PROVIDERS
   * -------------------------------------------------- */

  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == "google.com");
  }

  bool get isPasswordUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == "password");
  }

  Future<void> restoreGoogleProfilePhoto() async {
    final user = _auth.currentUser;
    if (user?.photoURL == null) return;

    await _db.collection("users").doc(user!.uid).update({
      "Photo_profile": user.photoURL
    });

    _currentUser?.photoProfile = user.photoURL!;
    notifyListeners();
  }

  /* --------------------------------------------------
   * USER LEVEL
   * -------------------------------------------------- */

  Future<void> updateUserLevel(String difficulty) async {
    int intermediate = _currentUser?.intermediate ?? 0;
    int advanced = _currentUser?.advanced ?? 0;

    if (difficulty == "Intermediate") intermediate++;
    if (difficulty == "Advanced") advanced++;

    String level = "Beginner";
    if (advanced >= 5) level = "Advanced";
    else if (intermediate >= 5) level = "Intermediate";

    final uid = _auth.currentUser!.uid;

    await _db.collection("users").doc(uid).update({
      "Intermediate": intermediate,
      "Advanced": advanced,
      "Level": level,
    });

    _currentUser?.intermediate = intermediate;
    _currentUser?.advanced = advanced;
    _currentUser?.level = level;

    notifyListeners();
  }
}