import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/user.dart';


import '../service/authservice.dart' ;
class UserController extends ChangeNotifier {





  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  UserController(this._authService);



  Users? _currentUser;
  Users? get currentUser => _currentUser;

  /* --------------------------------------------------
   * AUTH
   * -------------------------------------------------- */

  Future<void> register(String email, String password) async {
    await _authService.register(email, password);
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email, password);
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    debugPrint("UserController: loginWithGoogle() start");

    try {
      await _authService.loginWithGoogle();
      debugPrint("UserController: AuthService.loginWithGoogle() completed");

      _currentUser = _authService.currentUser;
      debugPrint("UserController: _currentUser uid = ${_currentUser?.uid}");

      notifyListeners();
      debugPrint("UserController: notifyListeners() called");
    } catch (e, st) {
      debugPrint("UserController: loginWithGoogle() failed");
      debugPrint("UserController ERROR: $e");
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
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



  /* --------------------------------------------------
   * PROFILE UPDATE
   * -------------------------------------------------- */

  Future<void> updateUsername(String username) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection("users").doc(uid).update({"Username": username});
    _currentUser?.username = username;
    await _db.collection("users_index").doc(uid).update({
      "username": username,
      "normalized": username.toLowerCase(),
    });
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
    await _authService.sendPasswordReset(email);
  }

  Future<void> requestPasswordReset() async {
    await _authService.requestPasswordReset();
  }

  /* --------------------------------------------------
   * PROVIDERS
   * -------------------------------------------------- */

  bool get isGoogleUser => _authService.isGoogleUser;

  bool get isPasswordUser => _authService.isPasswordUser;


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
  // CHECK IF I FOLLOW USER
  Future<bool> isFollowing(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final myUid = user.uid;
    final snap = await _db.collection("users").doc(myUid).get();
    final following = List<String>.from(snap.data()?["Following"] ?? []);

    return following.contains(targetUid);
  }

  // FOLLOW SYSTEM
  Future<bool> followUser(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final myUid = user.uid;

    if (myUid == targetUid) return false;

    await _db.collection("users").doc(myUid).update({
      "Following": FieldValue.arrayUnion([targetUid])
    });

    await _db.collection("users").doc(targetUid).update({
      "Followers": FieldValue.arrayUnion([myUid])
    });
    return true;
  }

  Future<void> unfollowUser(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final myUid = user.uid;

    if (myUid == targetUid) return;

    await _db.collection("users").doc(myUid).update({
      "Following": FieldValue.arrayRemove([targetUid])
    });

    await _db.collection("users").doc(targetUid).update({
      "Followers": FieldValue.arrayRemove([myUid])
    });
  }



  Future<void> tryAutoLogin() async {
    final user = _auth.currentUser;

    if (user != null) {
      await loadUserCore(user.uid);
    }
  }

  Future<void> _ensureUserFirestoreDocs(User user) async {
    final uid = user.uid;

    final userRef = _db.collection("users").doc(uid);
    final indexRef = _db.collection("users_index").doc(uid);

    final snap = await userRef.get();
    if (snap.exists) return;

    // Dati base presi da Google
    final email = user.email ?? "";
    final displayName = user.displayName ?? "";
    final photoUrl = user.photoURL ?? "";

    // Username: prova displayName, altrimenti parte dell'email, altrimenti uid corto
    String username;
    if (displayName.trim().isNotEmpty) {
      username = displayName.trim().split(RegExp(r"\s+")).first;
    } else if (email.contains("@")) {
      username = email.split("@")[0];
    } else {
      username = uid.substring(0, 8);
    }


    final batch = _db.batch();

    batch.set(userRef, {
      "Username": username,
      "Photo_profile": photoUrl,
      "Name": displayName,
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

    batch.set(indexRef, {
      "uid": uid,
      "username": username,
      "normalized": username.toLowerCase(),
    });

    await batch.commit();
  }

  ({String watchId, String token}) extractWatchPair(String raw) {
    return _authService.extractWatchPair(raw);
  }

  Future<void> approveWatchPair({
    required String watchId,
    required String token,
  }) async {
    await _authService.approveWatchPair(
      watchId: watchId,
      token: token,
    );
  }
}