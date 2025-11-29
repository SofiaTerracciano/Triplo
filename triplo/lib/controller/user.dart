import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../model/diary.dart';

class UserController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Users? _currentUser;
  bool _loaded = false;


  Users? get currentUser => _currentUser;

  // -----------------------------------------------------------
  // REGISTER (EMAIL + PWD)
  // -----------------------------------------------------------
  Future<void> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Crea documento Firestore coerente con il MODEL
    await _createFirestoreUser(uid, email);

    await loadUser(uid);
  }

  // -----------------------------------------------------------
  // LOGIN EMAIL + PASSWORD
  // -----------------------------------------------------------
  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await loadUser(credential.user!.uid);


    final uid = credential.user!.uid;

    //se il documento non esiste, crealo con la struttura del MODEL
    await _ensureFirestoreUserExists(
      uid: uid,
      email: email,
      username: email.split('@')[0],
      photoURL: "",
    );

    // poi carica il MODEL
    await loadUser(uid);


  }

  // -----------------------------------------------------------
  // LOGIN GOOGLE
  // -----------------------------------------------------------
  Future<void> loginWithGoogle(AuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final uid = user.uid;

    final email = user.email ?? "";
    final display = user.displayName ?? "";

    // Fallback sicuri
    final username = display.isNotEmpty
        ? display
        : (email.contains("@") ? email.split("@")[0] : uid);

    final photoURL = user.photoURL ?? "";

    await _ensureFirestoreUserExists(
      uid: uid,
      email: email,
      username: username,
      photoURL: photoURL,
    );

    await loadUser(uid);
  }


  // -----------------------------------------------------------
  // CREA DOCUMENTO FIRESTORE SE NON ESISTE
  // -----------------------------------------------------------
  Future<void> _createFirestoreUser(String uid, String email) async {
    await _db.collection("users").doc(uid).set({
      "Username": email.split('@')[0],
      "Photo_profile": "",
      "Name": "",
      "Surname": "",
      "Birthdate": DateTime.now().toIso8601String(),
      "Email": email,

      "Followers": [],           // List<String>
      "Following": [],           // List<String>
      "Public_diary": [],        // List<String>
      "Private_diary": [],       // List<String>
      "Saved_trekkings": [],     // List<String>
    });
  }

  Future<void> _ensureFirestoreUserExists({
    required String uid,
    required String email,
    required String username,
    required String photoURL,
  }) async {
    final doc = await _db.collection("users").doc(uid).get();

    if (!doc.exists) {
      await _db.collection("users").doc(uid).set({
        "Username": username,
        "Photo_profile": photoURL,
        "Name": "",
        "Surname": "",
        "Birthdate": DateTime.now().toIso8601String(),
        "Email": email,

        "Followers": [],
        "Following": [],
        "Public_diary": [],
        "Private_diary": [],
        "Saved_trekkings": [],
      });
    }
  }

  // -----------------------------------------------------------
  // LOAD USER
  // -----------------------------------------------------------
  Future<void> loadUser(String uid) async {

    //if (_loaded) return;
    _loaded = true;

    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;

    // campi "semplici" con fallback anche per documenti vecchi
    final username = (data["Username"] ?? data["username"] ?? "") as String;
    final name = (data["Name"] ?? "") as String;
    final surname = (data["Surname"] ?? "") as String;
    final email = (data["Email"] ?? data["email"] ?? "") as String;
    final photoProfile = (data["Photo_profile"] ?? data["photoURL"] ?? "") as String;

    // Birthdate robusto (nuovo + vecchia struttura)
    DateTime birthdate;
    final rawBirth = data["Birthdate"];
    if (rawBirth is String && rawBirth.isNotEmpty) {
      birthdate = DateTime.tryParse(rawBirth) ?? DateTime(2000, 1, 1);
    } else if (data["registerdate"] is Timestamp) {
      birthdate = (data["registerdate"] as Timestamp).toDate();
    } else {
      birthdate = DateTime(2000, 1, 1);
    }

    // Convertiamo le liste di stringhe --> Oggetti Users e Diary
    List<String> followersIds = List<String>.from(data["Followers"] ?? []);
    List<String> followingIds = List<String>.from(data["Following"] ?? []);
    List<String> publicDiaryIds = List<String>.from(data["Public_diary"] ?? []);
    List<String> privateDiaryIds = List<String>.from(data["Private_diary"] ?? []);
    List<String> savedTrekkingIds = List<String>.from(data["Saved_trekkings"] ?? []);



    // Conversione ID --> Oggetti Users (Followers, Following)
    List<Users> followers = [];
    for (final id in followersIds) {
      final u = await _fetchUserById(id);
      if (u != null) followers.add(u);
    }

    List<Users> following = [];
    for (final id in followingIds) {
      final u = await _fetchUserById(id);
      if (u != null) following.add(u);
    }

    // Conversione ID --> Oggetti Diary
    List<Diary> publicDiary = [];
    for (final id in publicDiaryIds) {
      final d = await _fetchDiary(id);
      if (d != null) publicDiary.add(d);
    }

    List<Diary> privateDiary = [];
    for (final id in privateDiaryIds) {
      final d = await _fetchDiary(id);
      if (d != null) privateDiary.add(d);
    }

    List<Diary> savedTrek = [];
    for (final id in savedTrekkingIds) {
      final d = await _fetchDiary(id);
      if (d != null) savedTrek.add(d);
    }
    /*
    _currentUser = Users(
      uid: uid,
      username: data["Username"],
      name: data["Name"],
      surname: data["Surname"],
      birthdate: DateTime.parse(data["Birthdate"]),
      email: data["Email"],
      photoProfile: data["Photo_profile"],
      followers: followers,
      following: following,
      publicDiaryPages: publicDiary,
      privateDiaryPages: privateDiary,
      savedTrekkings: savedTrek,
     */
    _currentUser = Users(
      uid: uid,
      username: username,
      name: name,
      surname: surname,
      birthdate: birthdate,
      email: email,
      photoProfile: photoProfile,
      followers: followers,
      following: following,
      publicDiaryPages: publicDiary,
      privateDiaryPages: privateDiary,
      savedTrekkings: savedTrek,
    );

    notifyListeners();
  }

  // -----------------------------------------------------------
  // HELPERS: FETCH USER + FETCH DIARY
  // -----------------------------------------------------------


  Future<Users?> _fetchUserById(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;

    final data = snap.data()!;
    return Users.fromMap(data, uid: uid);
  }



  Future<Diary?> _fetchDiary(String docId) async {
    final snap = await _db.collection("diary").doc(docId).get();
    if (!snap.exists) return null;

    return Diary.fromMap(snap.data()!, diaryId: docId);
  }

  // -----------------------------------------------------------
  // LOGOUT
  // -----------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _loaded = false;
    notifyListeners();
  }






















  Future<void> updateProfilePhoto(File image) async {
    final uid = _auth.currentUser!.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(uid)
        .child('$uid.jpg');

    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    await _db.collection("users").doc(uid).update({
      "Photo_profile": url,
    });

    _currentUser?.photoProfile = url;
    notifyListeners();
  }

}
