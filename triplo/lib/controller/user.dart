import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../model/diary.dart';
import '../model/trekking.dart';

/**
 * Controller responsible for:
 * Authentication (email/password + Google)
 * Creating user documents in Firestore
 * Loading complete user profile
 * Converting IDs into full objects (followers, diaries, etc.)
 * Updating profile picture
 */



class UserController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserController();

  Users? _currentUser; // Local copy of logged user
  bool _loaded = false;


  Users? get currentUser => _currentUser;

  set currentUser(Users user) {
    _currentUser = user;
  }

  /**
   * Registers a new user using email and password.
   * Steps:
   * 1. Creates a FirebaseAuth account.
   * 2. Creates a Firestore user document with model fields.
   * 3. Loads the full user profile into the local model.
   *
   * This method is used exclusively for manual email/password sign-up
   */
  Future<void> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Crea documento Firestore coerente con il MODEL
    await _createFirestoreUser(uid, email);
    try {
      await _createUserIndex(uid, email.split('@')[0]);
    } catch (e, st) {
      if (kDebugMode) {
        print("Failed to create user_index for $uid: $e\n$st");
      }
    }

    await loadUser(uid);

  //  Future<List<Users>> searchUsers(String query) async {
  //    final snap = await _db
  //        .collection("users_index")
  //        .where("username", isGreaterThanOrEqualTo: query)
  //        .where("username", isLessThanOrEqualTo: "$query\uf8ff")
  //        .get();

      //final List<Users> results = [];

    //  for (var d in snap.docs) {
    //    final uid = d["uid"];
    //    final user = await _fetchUserById(uid);  // usa già fromMap corretta
    //    if (user != null) results.add(user);
    //  }

    //  return results;
   // }
  }

  /**
   * Logs in a user using email and password.
   * After authentication, this method:
   * 1. Ensures the Firestore user document exists
   * 2. Loads the complete user profile, including
   *    followers, following, and diaries.
   */
  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    //await loadUser(credential.user!.uid);

    final user = credential.user;
    if (user == null) {
      throw StateError("Login riuscito ma FirebaseAuth user è null");
    }

    final uid = user.uid;



    //se il documento non esiste, crealo con la struttura del MODEL
    await _ensureFirestoreUserExists(
      uid: uid,
      email: email,
      username: email.split('@')[0],
      photoURL: "",
    );
    // poi carica il MODEL
    await loadUser(uid);
    if (_currentUser == null) {
      throw StateError("Profilo utente non caricato dopo il login");
    }
  }

  /**
   * Logs in a user using Google Sign-In.
   * This method:
   * Receives Google credentials from the LoginPage
   * Uses them to authenticate with FirebaseAuth
   * Ensures a Firestore document exists for the Google profile.
   * Loads the user's full profile into memory.
   * Supports creating a new Firestore user for the Google profile
   * if the user has never logged in using Google
   */
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


  /** Creates a new user document in Firestore matching the User model fields */
  Future<void> _createFirestoreUser(String uid, String email) async {
    await _db.collection("users").doc(uid).set({
      "Username": email.split('@')[0],
      "Photo_profile": "",
      "Name": "",
      "Surname": "",
      "Birthdate": DateTime.now().toIso8601String(),
      "Email": email,

      // sempre presenti
      "Followers": <String>[],
      "Following": <String>[],
      "Public_diary": <String>[],
      "Private_diary": <String>[],
      "Saved_trekkings": <String>[],
    });

  }

  /**
   * Ensures that a Firestore user document exists.
   * Used mainly for Google login for new users.
   * If the document does not exist, it is created with default fields.
   */
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
      try {
        await _createUserIndex(uid, username);
      } catch (e, st) {
        if (kDebugMode) {
          print("Failed to create user_index (google login) for $uid: $e\n$st");
        }
      }

    }
  }

  /**
   * Loads the user's complete profile from Firestore.
   * This method:
   * Reads basic user fields (email, username, photo, etc.)
   * Reads lists of IDs (followers, following, diaries...)
   * Builds from each ID a full Users/Diary object using helper methods
   */
  /*
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

    // Conversione di liste di stringhe --> Oggetti Users e Diary
    List<String> followersIds = List<String>.from(data["Followers"] ?? []);
    List<String> followingIds = List<String>.from(data["Following"] ?? []);
    List<String> publicDiaryIds = List<String>.from(data["Public_diary"] ?? []);
    List<String> privateDiaryIds = List<String>.from(data["Private_diary"] ?? []);
    List<String> savedTrekkingIds = List<String>.from(data["Saved_trekkings"] ?? []);



    // Conversione ID --> Oggetti Users (Followers, Following)
    List<Users> followers = [];
    for (final id in followersIds) {
      final u = await fetchUserById(id);
      if (u != null) followers.add(u);
    }

    List<Users> following = [];
    for (final id in followingIds) {
      final u = await fetchUserById(id);
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

    List<Trekking> savedTrek = [];
    for (final id in savedTrekkingIds) {
      final d = await _fetchTrekking(id);
      if (d != null) savedTrek.add(d);
    }


    //_currentUser = Users(
    //  uid: uid,
    //  username: data["Username"],
    //  name: data["Name"],
    //  surname: data["Surname"],
    //  birthdate: DateTime.parse(data["Birthdate"]),
    //  email: data["Email"],
    //  photoProfile: data["Photo_profile"],
    //  followers: followers,
    //  following: following,
    //  publicDiaryPages: publicDiary,
    // privateDiaryPages: privateDiary,
    //  savedTrekkings: savedTrek,
    //
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
   */
  Future<void> loadUser(String uid) async {
    _loaded = true;

    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;

    // campi semplici, con fallback per documenti vecchi
    final username = (data["Username"] ?? data["username"] ?? "") as String;
    final name = (data["Name"] ?? "") as String;
    final surname = (data["Surname"] ?? "") as String;
    final email = (data["Email"] ?? data["email"] ?? "") as String;
    final photoProfile =
    (data["Photo_profile"] ?? data["photoURL"] ?? "") as String;

    final birthdate = () {
      final rawBirth = data["Birthdate"];
      if (rawBirth is String && rawBirth.isNotEmpty) {
        return DateTime.tryParse(rawBirth) ?? DateTime(2000, 1, 1);
      }
      final reg = data["registerdate"];
      if (reg is Timestamp) return reg.toDate();
      return DateTime(2000, 1, 1);
    }();

    // Liste di ID
    final followersIds =
    List<String>.from(data["Followers"] ?? const <String>[]);
    final followingIds =
    List<String>.from(data["Following"] ?? const <String>[]);

    final publicDiaryIds = List<String>.from(
      data["Public_diary"] ?? data["Public_Diary"] ?? const <String>[],
    );
    final privateDiaryIds = List<String>.from(
      data["Private_diary"] ?? data["Private_Diary"] ?? const <String>[],
    );

    final savedTrekkingIds =
    List<String>.from(data["Saved_trekkings"] ?? const <String>[]);

    // Conversione ID -> Oggetti

    // Followers
    final followers = (await Future.wait(
      followersIds.map(fetchUserById),
    ))
        .whereType<Users>()
        .toList();

    // Following
    final following = (await Future.wait(
      followingIds.map(fetchUserById),
    ))
        .whereType<Users>()
        .toList();

    // Diary pubblici
    final publicDiary = (await Future.wait(
      publicDiaryIds.map(_fetchDiary),
    ))
        .whereType<Diary>()
        .toList();

    // Diary privati
    final privateDiary = (await Future.wait(
      privateDiaryIds.map(_fetchDiary),
    ))
        .whereType<Diary>()
        .toList();

    // Trekking salvati
    final savedTrek = (await Future.wait(
      savedTrekkingIds.map(_fetchTrekking),
    ))
        .whereType<Trekking>()
        .toList();

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



  /**
   * Fetches a user document by UID and converts it into a Users object.
   * Used by loadUser() to reconstruct followers and following lists.
   */
  Future<Users?> fetchUserById(String uid) async { // da rimettere privato?
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;

    final data = snap.data()!;
    return Users.fromMap(data, uid: uid);
  }


  /**
   * Fetches a diary entry by ID and returns a Diary.
   * Used by loadUser() to build:
   * - publicDiaryPages
   * - privateDiaryPages
   * - savedTrekkings
   */
  Future<Diary?> _fetchDiary(String docId) async {
    final snap = await _db.collection("diary").doc(docId).get();
    if (!snap.exists) return null;

    return Diary.fromMap(snap.data()!, diaryId: docId);
  }

  /** Handles logout of the user */
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _loaded = false;
    notifyListeners();
  }

  Future<Trekking?> _fetchTrekking(String docId) async {
    final snap = await _db.collection("trekking").doc(docId).get();
    if (!snap.exists) return null;

    return Trekking.fromMap(snap.data()!, docId: docId);
  }

  /// Updates the profile picture of the current user.
  /// This method uploads the selected image file to Firebase Storage
  /// inside a folder named "profile_photos/<uid>/uid.jpg".
  /// After the upload, it retrieves the public download URL and
  /// updates the "Photo_profile" field in the user's Firestore record.
  /// Updates the in-memory `_currentUser` model
  /// and notifies listeners so that the UI refreshes.
  /// Steps:
  /// 1. Uploads the image file to Firebase Storage.
  /// 2. Saves the URL of the image inside the "Photo_profile" field in Firestore.
  /// 3. Updates the local user model and refresh UI.
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

  /// Sends a password reset link to the given email.
  /// This method throws FirebaseAuthException if something goes wrong.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Users?> getUserById(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();

    if (!snap.exists) {
      return null;   // The user doesn't exist
    }

    return Users.fromMap(snap.data()!, uid: uid);
  }

  Future<void> addTrekkingToSaved(String trekkingId) async {
    final uid = _auth.currentUser!.uid;
    // Aggiorna Firestore
    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayUnion([trekkingId]),
    });
    // Aggiorna la lista locale se il trekking esiste
    final trek = await _fetchTrekking(trekkingId);
    if (trek != null) {
      _currentUser?.savedTrekkings.add(trek);
      notifyListeners();
    }
  }

  Future<void> removeTrekkingFromSaved(String trekkingId) async {
    final uid = _auth.currentUser!.uid;
    print("Prima di remove: ${_currentUser?.savedTrekkings.map((t) => t.documentId).toList()}");
    // Rimuove dal DB
    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayRemove([trekkingId]),
    });
    // Rimuove dalla lista locale (oggetti Trekking)
    _currentUser?.savedTrekkings.removeWhere((trek) => trek.documentId == trekkingId);
    print("Dopo remove: ${_currentUser?.savedTrekkings.map((t) => t.documentId).toList()}");
    notifyListeners();
  }

  // Fetch image URL from Firebase Storage given complete firestore url
  Future<String?> getDownloadUrl(String? path) async {
    // If you donn't have the profile photo return null
    if (path == null || path.isEmpty) {
      return null;
    }

    try {
      Reference ref = FirebaseStorage.instance.refFromURL(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }


  Future<List<Users>> searchUsers(String query) async {
    final snap = await _db
        .collection("users_index")
        .where("username", isGreaterThanOrEqualTo: query)
        .where("username", isLessThanOrEqualTo: "$query\uf8ff")
        .get();

    final List<Users> results = [];

    for (var d in snap.docs) {
      final uid = d["uid"];
      final user = await fetchUserById(uid);  // usa già fromMap corretta
      if (user != null) results.add(user);
    }

    return results;
  }


  Future<void> _createUserIndex(String uid, String username) async {
    await _db.collection("users_index").doc(uid).set({
      "uid": uid,
      "username": username,
      "normalized": username.toLowerCase(),
    });
  }

  Future<List<String>> getFollowingIds(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return [];

    return List<String>.from(snap.data()?["Following"] ?? []);
  }

  Future<void> updateUsername(String newUsername) async {
    final uid = _auth.currentUser!.uid;

    await _db.collection("users").doc(uid).update({
      "Username": newUsername,
    });

    await _db.collection("users_index").doc(uid).update({
      "username": newUsername,
      "normalized": newUsername.toLowerCase(),
    });

    _currentUser?.username = newUsername;
    notifyListeners();
  }
  Future<void> updateName(String newName) async {
    final uid = _auth.currentUser!.uid;

    await _db.collection("users").doc(uid).update({
      "Name": newName,
    });

    _currentUser?.name = newName;
    notifyListeners();
  }





  Future<void> updateSurname(String newSurname) async {
    final uid = _auth.currentUser!.uid;

    await _db.collection("users").doc(uid).update({
      "Surname": newSurname,
    });

    _currentUser?.surname = newSurname;
    notifyListeners();
  }

  /*
  Future<void> updateBirthdate(DateTime date) async {
    final uid = _auth.currentUser!.uid;

    await _db.collection("users").doc(uid).update({
      "Birthdate": date.toIso8601String(),
    });

    _currentUser?.birthdate = date;
    notifyListeners();
  }
  */






  Future<void> requestPasswordReset() async {
    final email = _currentUser?.email;
    if (email == null || email.isEmpty) return;

    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateBirthdate(DateTime birthdate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Birthdate": birthdate.toIso8601String(),
    });

    _currentUser?.birthdate = birthdate;
    notifyListeners();
  }


}