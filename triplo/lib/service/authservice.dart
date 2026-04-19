import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../exception/change_email_exception.dart';
import '../model/user.dart';

class AuthService extends ChangeNotifier {
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  //final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  Users? _currentUser;
  Users? get currentUser => _currentUser;

  String? get currentUid => _currentUser?.uid ?? _auth.currentUser?.uid;

  bool get isAuthenticated => _auth.currentUser != null;




  String? get currentPhotoUrl => _auth.currentUser?.photoURL;
  String? get currentEmailFromAuth => _auth.currentUser?.email;

  Future<void> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    final username = email.split("@")[0];

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

  /*
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
   */


  Future<void> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    try {
      debugPrint("AuthService: Google login start"); //coverage:ignore-line

      debugPrint("AuthService: calling googleSignIn.signOut()"); //coverage:ignore-line
      await googleSignIn.signOut();
      debugPrint("AuthService: signOut completed"); //coverage:ignore-line


      // try {
      //   debugPrint("AuthService: calling googleSignIn.disconnect()");
      //   await googleSignIn.disconnect();
      //   debugPrint("AuthService: disconnect completed");
      // } catch (e) {
      //   debugPrint("AuthService: disconnect skipped/failed: $e");
      // }

      debugPrint("AuthService: opening Google account picker"); //coverage:ignore-line
      final googleUser = await googleSignIn.signIn();

      debugPrint("AuthService: signIn() returned");  //coverage:ignore-line
      if (googleUser == null) {
        debugPrint("AuthService: Google sign-in cancelled by user"); //coverage:ignore-line
        throw Exception("Google sign-in cancelled");
      }

      debugPrint("AuthService: selected Google account = ${googleUser.email}"); //coverage:ignore-line

      debugPrint("AuthService: requesting Google authentication tokens"); //coverage:ignore-line
      final googleAuth = await googleUser.authentication;
      debugPrint("AuthService: tokens received"); //coverage:ignore-line
      debugPrint(
          "AuthService: accessToken null? ${googleAuth.accessToken == null}"); //coverage:ignore-line
      debugPrint("AuthService: idToken null? ${googleAuth.idToken == null}"); //coverage:ignore-line

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint("AuthService: Firebase credential created");  //coverage:ignore-line

      debugPrint("AuthService: calling FirebaseAuth.signInWithCredential()"); //coverage:ignore-line
      final cred = await _auth.signInWithCredential(credential);
      debugPrint("AuthService: Firebase signInWithCredential completed"); //coverage:ignore-line

      final user = cred.user;
      debugPrint("AuthService: Firebase user uid = ${user?.uid}"); //coverage:ignore-line
      debugPrint("AuthService: Firebase user email = ${user?.email}"); //coverage:ignore-line

      if (user == null) {
        throw StateError("Firebase user is null after Google sign-in");
      }

      debugPrint("AuthService: ensuring Firestore docs"); //coverage:ignore-line
      await _ensureUserFirestoreDocs(user);
      debugPrint("AuthService: Firestore docs ensured"); //coverage:ignore-line

      debugPrint("AuthService: loading user core"); //coverage:ignore-line
      await loadUserCore(user.uid);
      debugPrint("AuthService: loadUserCore completed"); //coverage:ignore-line
    } catch (e, st) {
      debugPrint("AuthService: Google login failed"); //coverage:ignore-line
      debugPrint("AuthService ERROR: $e"); //coverage:ignore-line
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }


  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }


  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> requestPasswordReset() async {
    if (_currentUser?.email == null) return;
    await _auth.sendPasswordResetEmail(email: _currentUser!.email);
  }


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

    final email = user.email ?? "";
    final displayName = user.displayName ?? "";
    final photoUrl = user.photoURL ?? "";

    String username;
    if (displayName
        .trim()
        .isNotEmpty) {
      username = displayName
          .trim()
          .split(RegExp(r"\s+"))
          .first;
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
    final uri = Uri.tryParse(raw.trim());

    if (uri == null || uri.scheme != "triplo" || uri.host != "watch-pair") {
      throw const FormatException("QR non valido");
    }
    final seg = uri.pathSegments;
    if (seg.isEmpty) throw const FormatException("watchId mancante");
    final watchId = seg.first.trim();
    if (watchId.isEmpty) throw const FormatException("watchId mancante");
    final token = uri.queryParameters['t']?.trim();
    if (token == null || token.isEmpty) {
      throw const FormatException("token mancante");
    }

    return (watchId: watchId, token: token);
  }

  Future<void> approveWatchPair({
    required String watchId,
    required String token,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Devi essere loggato sul telefono.");
    }

    final ref = _db.collection('watch_pair').doc(
        watchId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception("watch_pair non trovato (watchId=$watchId)");
      }

      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final qrToken = data['qrToken'] as String?;
      final expiresAt = data['expiresAt'] as Timestamp?;

      if (status != 'waiting') {
        throw Exception("QR non in waiting (status=$status)");
      }
      if (qrToken != token) {
        throw Exception("Token non valido / QR rigenerato");
      }
      if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception("QR scaduto");
      }

      tx.update(ref, {
        'status': 'approved',
        'uid': user.uid,
      });
    });
  }

  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ChangeEmailException("not-authenticated");
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw ChangeEmailException("missing-current-email");
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw ChangeEmailException(e.code);
    } catch (_) {
      throw ChangeEmailException("unknown");
    }
  }

  Future<void> refreshEmailFromAuth() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nessun utente autenticato");
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      throw Exception("Utente non disponibile dopo reload");
    }

    // forza refresh del token
    await refreshedUser.getIdToken(true);

    final refreshedEmail = refreshedUser.email;
    if (refreshedEmail == null || refreshedEmail.isEmpty) {
      throw Exception("Email non disponibile");
    }

    debugPrint("refreshEmailFromAuth: email Firebase Auth = $refreshedEmail"); //coverage:ignore-line
    debugPrint("refreshEmailFromAuth: uid = ${refreshedUser.uid}"); //coverage:ignore-line

    await _db.collection("users").doc(refreshedUser.uid).update({
      "Email": refreshedEmail,
    });

    await loadUserCore(refreshedUser.uid);
  }

  Future<List<Map<String, dynamic>>> getConnectedWatches() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No authenticated user");
    }

    final snap = await _db
        .collection('watch_pair')
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'watchId': doc.id,
        'status': data['status'],
        'uid': data['uid'],
        'platform': data['platform'],
        'createdAt': data['createdAt'],
        'expiresAt': data['expiresAt'],
        'remoteLogoutAt': data['remoteLogoutAt'],
        'qrToken': data['qrToken'],
      };
    }).toList();
  }

  Future<void> enableRemoteLogoutForWatch(String watchId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No authenticated user");
    }

    await _db.collection('watch_pair').doc(watchId).update({
      'remoteLogoutAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearRemoteLogoutForWatch(String watchId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No authenticated user");
    }

    await _db.collection('watch_pair').doc(watchId).update({
      'remoteLogoutAt': null,
    });
  }

  @visibleForTesting
  Future<void> ensureUserFirestoreDocsPublic(User user) =>
      _ensureUserFirestoreDocs(user);
}
