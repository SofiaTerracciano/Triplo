import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/user.dart';

class AuthService extends ChangeNotifier {
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
    final username = email.split("@")[0];

    // -----------------------
    // USERS COLLECTION
    // -----------------------
    await _db.collection("users").doc(uid).set({
      "Username": username,
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
    });

    // -----------------------
    // USERS_INDEX COLLECTION
    // -----------------------
    await _db.collection("users_index").doc(uid).set({
      "uid": uid,
      "username": username,
      "normalized": username.toLowerCase(),
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

  Future<void> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn();

    try {
      // Forza la scelta dell'account ad ogni login
      await googleSignIn.signOut();

      // Se l'utente aveva già autorizzato l'app con un account Google,
      // questa chiamata aiuta a mostrare di nuovo il selettore account.
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // Può fallire se non c'è un account collegato, in tal caso ignoriamo.
      }

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Google sign-in cancelled");
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;

      if (user == null) {
        throw StateError("Firebase user is null after Google sign-in");
      }

      await _ensureUserFirestoreDocs(user);
      await loadUserCore(user.uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
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

  /* --------------------------------------------------
   * LOAD CORE USER
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
   * AUTO LOGIN
   * -------------------------------------------------- */

  Future<void> tryAutoLogin() async {
    final user = _auth.currentUser;

    if (user != null) {
      await loadUserCore(user.uid);
    }
  }

  /* --------------------------------------------------
   * GOOGLE USER DOC CREATION
   * -------------------------------------------------- */

  Future<void> _ensureUserFirestoreDocs(User user) async {
    final uid = user.uid;

    final userRef = _db.collection("users").doc(uid);
    final indexRef = _db.collection("users_index").doc(uid);

    final snap = await userRef.get();
    if (snap.exists) return;

    final email = user.email ?? "";
    final displayName = user.displayName ?? "";
    final photoUrl = user.photoURL ?? "";

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
}