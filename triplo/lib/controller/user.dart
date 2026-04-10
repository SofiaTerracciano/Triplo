import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import '../model/user.dart';

import '../service/authservice.dart';

class UserController extends ChangeNotifier {

  //final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  final AuthService _authService;


  //UserController(this._authService);


  String? get uid => _authService.currentUid;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  UserController(this._authService) // coverage:ignore-start
      : _db = FirebaseFirestore.instance {
    _init();
  } // coverage:ignore-end

  // Costruttore per i test
  UserController.withDb(this._authService, this._db) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    // Non facciamo notifyListeners qui perché il costruttore sta ancora girando

    try {
      final uid = _authService.currentUid;
      if (uid != null) {
        // Carica i dati dal DB se l'utente è già loggato
        await loadUserCore(uid);
      }
    } catch (e) {
      debugPrint("Errore inizializzazione: $e");  // coverage:ignore-line
    } finally {
      // IMPORTANTE: Questo interrompe il caricamento infinito
      _isLoading = false;
      notifyListeners();
    }
  }

  Users? _currentUser;
  Users? get currentUser => _currentUser;

  /* --------------------------------------------------
   * AUTH
   * -------------------------------------------------- */

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(email, password);
      _currentUser = _authService.currentUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    /*await _authService.register(email, password);
    _currentUser = _authService.currentUser;
    notifyListeners();*/
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email, password);
      _currentUser = _authService.currentUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    /*await _authService.login(email, password);
    _currentUser = _authService.currentUser;
    notifyListeners();*/
  }

  Future<void> loginWithGoogle() async {
    debugPrint("UserController: loginWithGoogle() start");
    _isLoading = true;
    notifyListeners();

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
    } finally {
      _isLoading = false; 
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    final uid = _authService.currentUid;
    if (uid == null) return;
    await _db.collection("users").doc(uid).update({"Username": username});
    _currentUser?.username = username;
    await _db.collection("users_index").doc(uid).update({
      "username": username,
      "normalized": username.toLowerCase(),
    });
    notifyListeners();
  }





  Future<void> updateName(String name) async {
    final uid = _authService.currentUid;
    if (uid == null) return;
    await _db.collection("users").doc(uid).update({"Name": name});
    _currentUser?.name = name;
    notifyListeners();
  }



  Future<void> updateSurname(String surname) async {
    final uid = _authService.currentUid;
    if (uid == null) return;
    await _db.collection("users").doc(uid).update({"Surname": surname});
    _currentUser?.surname = surname;
    notifyListeners();
  }

  Future<void> updateBirthdate(DateTime date) async {
    final uid = _authService.currentUid;
    if (uid == null) return;
    await _db.collection("users").doc(uid).update({
      "Birthdate": date.toIso8601String(),
    });
    _currentUser?.birthdate = date;
    notifyListeners();
  }

  Future<void> updateProfilePhoto(File image) async {
    final uid = _authService.currentUid;

    if (uid == null) return;

    final ref = FirebaseStorage.instance // coverage:ignore-start
        .ref()
        .child("profile_photos")
        .child(uid)
        .child("$uid.jpg");

    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    await _db.collection("users").doc(uid).update({"Photo_profile": url});

    _currentUser?.photoProfile = url;
    notifyListeners();
  } // coverage:ignore-end

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
    final uid = _authService.currentUid;

    final photoUrl = _authService.currentPhotoUrl;

    if (uid == null || photoUrl == null || photoUrl.isEmpty) return;


    await _db.collection("users").doc(uid).update({
      "Photo_profile": _authService.currentPhotoUrl,
    });

    _currentUser?.photoProfile = _authService.currentPhotoUrl!;
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
    if (advanced >= 5)
      level = "Advanced";
    else if (intermediate >= 5)
      level = "Intermediate";

    final uid = _authService.currentUid;
    if (uid == null) return;
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
    final uid = _authService.currentUid;
    if (uid == null) return false;

    final myUid = uid;
    final snap = await _db.collection("users").doc(myUid).get();
    final following = List<String>.from(snap.data()?["Following"] ?? []);

    return following.contains(targetUid);
  }

  // FOLLOW SYSTEM
  Future<bool> followUser(String targetUid) async {
    final uid = _authService.currentUid;
    if (uid == null) return false;
    final myUid = uid;

    if (myUid == targetUid) return false;

    await _db.collection("users").doc(myUid).update({
      "Following": FieldValue.arrayUnion([targetUid]),
    });

    await _db.collection("users").doc(targetUid).update({
      "Followers": FieldValue.arrayUnion([myUid]),
    });
    return true;
  }

  Future<void> unfollowUser(String targetUid) async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    final myUid = uid;

    if (myUid == targetUid) return;

    await _db.collection("users").doc(myUid).update({
      "Following": FieldValue.arrayRemove([targetUid]),
    });

    await _db.collection("users").doc(targetUid).update({
      "Followers": FieldValue.arrayRemove([myUid]),
    });
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _authService.currentUid;

      if (uid != null) {
        await loadUserCore(uid);
      } else {
        _currentUser = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  ({String watchId, String token}) extractWatchPair(String raw) {
    return _authService.extractWatchPair(raw);
  }

  Future<void> approveWatchPair({
    required String watchId,
    required String token,
  }) async {
    await _authService.approveWatchPair(watchId: watchId, token: token);
  }

  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _authService.changeEmail(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }

  Future<void> refreshEmailFromAuth() async {
    await _authService.refreshEmailFromAuth();
    _currentUser = _authService.currentUser;
    notifyListeners();
  }
}
