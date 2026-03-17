import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../model/diary.dart';
import '../model/trekking.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Users? _currentUser;

  Users? get currentUser => _currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  late final StreamSubscription<User?> _authSub;

  final _uuid = const Uuid();

  String? _pairId;

  String? get pairId => _pairId;

  bool _pairing = false;

  bool get pairing => _pairing;

  String? _pairingError;

  String? get pairingError => _pairingError;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pairSub;
  Timer? _expiryTimer;
  DateTime? _pairCreatedAtLocal;

  static const Duration _qrTtl = Duration(minutes: 2);

  String? _pairedUid;
  String? get pairedUid => _pairedUid;
  String? get effectiveUid {
    return _pairedUid;
  }

  static const _storage = FlutterSecureStorage();
  static const _watchIdKey = 'watch_id';

  String? _watchId;
  String? get watchId => _watchId;

  String? _qrToken;
  String? get qrToken => _qrToken;

  // stringa pronta da trasformare in QR
  String? get qrPayload {
    if (_watchId == null || _qrToken == null) return null;
    return "triplo://watch-pair/$_watchId?t=$_qrToken";
  }

  bool get hasValidPairId {
    if (_pairId == null || _pairCreatedAtLocal == null) {
      return false;
    }

    return DateTime.now().difference(_pairCreatedAtLocal!) < _qrTtl;
  }

  UserController({required String watchId}) {
    _watchId = watchId;

    _authSub = _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }
      await loadUserCore(firebaseUser.uid);
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _pairSub?.cancel();
    _authSub.cancel();
    super.dispose();
  }

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
      "Advanced": 0,
      "Intermediate": 0,
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

  Future<void> loginWithCredential(AuthCredential credential) async {
    final cred = await _auth.signInWithCredential(credential);
    await loadUserCore(cred.user!.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final user = _auth.currentUser;
    if (user != null) await loadUserCore(user.uid);
  }

  /* --------------------------------------------------
   * LOAD CORE USER (lightweight)
   * -------------------------------------------------- */

  Future<void> loadUserCore(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return;

    final data = snap.data()!;

    _currentUser = Users.fromMap(data, uid: uid);

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
   * DIARY (optional sul watch)
   * -------------------------------------------------- */

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

  /* --------------------------------------------------
   * TREKKING (optional sul watch)
   * -------------------------------------------------- */

  Future<Trekking?> getTrekkingById(String id) async {
    final snap = await _db.collection("trekking").doc(id).get();
    if (!snap.exists) return null;
    return Trekking.fromMap(snap.data()!, docId: id);
  }

  Future<List<Trekking>> getSavedTrekkings(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Saved_trekkings"] ?? []);
    final trekkings = await Future.wait(ids.map(getTrekkingById));
    return trekkings.whereType<Trekking>().toList();
  }

  Future<void> addTrekkingToSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayUnion([trekkingId]),
    });

    notifyListeners();
  }

  Future<void> removeTrekkingFromSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Saved_trekkings": FieldValue.arrayRemove([trekkingId]),
    });

    notifyListeners();
  }

  Future<bool> isTrekkingSaved(String trekkingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _db.collection("users").doc(uid).get();
    final ids = List<String>.from(snap.data()?["Saved_trekkings"] ?? []);
    return ids.contains(trekkingId);
  }

  /* --------------------------------------------------
   * PROFILE UPDATE (optional sul watch)
   * -------------------------------------------------- */

  Future<void> updateUsername(String username) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({"Username": username});
    _currentUser?.username = username;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({"Name": name});
    _currentUser?.name = name;
    notifyListeners();
  }

  Future<void> updateSurname(String surname) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({"Surname": surname});
    _currentUser?.surname = surname;
    notifyListeners();
  }

  Future<void> updateBirthdate(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection("users").doc(uid).update({
      "Birthdate": date.toIso8601String(),
    });

    _currentUser?.birthdate = date;
    notifyListeners();
  }

  Future<void> updateProfilePhoto(File image) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_photos")
        .child(uid)
        .child("$uid.jpg");

    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    await _db.collection("users").doc(uid).update({"Photo_profile": url});

    _currentUser?.photoProfile = url;
    notifyListeners();
  }

  Future<void> loginWithCustomToken(String token) async {
    final cred = await _auth.signInWithCustomToken(token);
    await loadUserCore(cred.user!.uid);
  }

  Future<void> startWatchPairing({bool forceNew = false}) async {
    if (_pairing) return;

    if (_watchId == null) {
      _pairingError = "WatchId mancante (bootstrap non eseguito).";
      notifyListeners();
      return;
    }

    if (!forceNew && hasValidPairId) return;

    _pairing = true;
    _pairingError = null;
    notifyListeners();

    await _pairSub?.cancel();
    _pairSub = null;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    if (isLoggedIn) {
      await Future.delayed(const Duration(milliseconds: 50));
      await logout();
    }

    // token QR nuovo
    final token = _uuid.v4();

    _pairedUid = null;
    _qrToken = token;
    _pairId = token;
    _pairCreatedAtLocal = DateTime.now();
    notifyListeners();

    final docRef = _db.collection('watch_pair').doc(_watchId);

    try {
      await docRef.set({
        'watchId': _watchId,
        'qrToken': token,
        'status': 'waiting',
        'platform': 'wearos',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(_qrTtl)),
        'uid': null,
      }, SetOptions(merge: true));

      _expiryTimer = Timer(_qrTtl, () {
        _pairingError = "QR scaduto, rigenera.";
        notifyListeners();
      });

      _pairSub = docRef.snapshots().listen(
        (doc) {
          final data = doc.data();
          if (data == null) return;

          final status = data['status'] as String?;
          final uid = data['uid'] as String?;
          final tokenOnDb = data['qrToken'] as String?;

          if (tokenOnDb != _qrToken) return;

          if (status == 'approved' && uid != null && uid.isNotEmpty) {
            _expiryTimer?.cancel();
            _pairedUid = uid;
            notifyListeners();
          }

          if (status == 'expired') {
            _pairingError = "QR scaduto, rigenera.";
            notifyListeners();
          }
        },
        onError: (e) {
          _pairingError = "Errore listener pairing: $e";
          notifyListeners();
        },
      );
    } catch (e) {
      _pairingError = "Errore pairing: $e";
    } finally {
      _pairing = false;
      notifyListeners();
    }
  }

  Future<void> stopWatchPairing({bool clearId = false}) async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _pairSub?.cancel();
    _pairSub = null;

    if (clearId) {
      _pairId = null;
      _pairCreatedAtLocal = null;
    }

    notifyListeners();
  }

  Future<void> logoutWatch() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _pairSub?.cancel();
    _pairSub = null;

    // 1) reset pairing su Firestore (uid null, waiting + nuovo QR)
    await resetPairingOnLogout(regenerateQr: true);

    // 2) reset locale (NON watchId)
    _pairedUid = null;
    _pairingError = null;

    if (isLoggedIn) {
      await logout();
    }

    notifyListeners();
  }

  Future<bool> restoreWatchPairing() async {
    if (_watchId == null) return false;

    _pairingError = null;

    await _pairSub?.cancel();
    _pairSub = null;

    final docRef = _db.collection('watch_pair').doc(_watchId);

    try {
      final snap = await docRef.get();
      final data = snap.data();

      if (data != null) {
        final status = data['status'] as String?;
        final uid = data['uid'] as String?;

        if (status == 'approved' && uid != null && uid.isNotEmpty) {
          _pairedUid = uid;
          notifyListeners();

          _pairSub = docRef.snapshots().listen((doc) {
            final d = doc.data();
            if (d == null) return;
            final st = d['status'] as String?;
            final u = d['uid'] as String?;
            if (st == 'approved' && u != null && u.isNotEmpty) {
              if (_pairedUid != u) {
                _pairedUid = u;
                notifyListeners();
              }
            }
          });

          return true;
        }
      }
    } catch (e) {
      debugPrint("restoreWatchPairing get failed: $e");
    }

    _pairSub = docRef.snapshots().listen(
      (doc) {
        final d = doc.data();
        if (d == null) return;
        final st = d['status'] as String?;
        final u = d['uid'] as String?;
        if (st == 'approved' && u != null && u.isNotEmpty) {
          _pairedUid = u;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint("restoreWatchPairing listener error: $e");
      },
    );

    return false;
  }

  Future<void> resetPairingOnLogout({bool regenerateQr = true}) async {
    if (_watchId == null) return;

    final docRef = _db.collection('watch_pair').doc(_watchId);

    final newToken = _uuid.v4();
    final now = DateTime.now();

    try {
      if (regenerateQr) {
        await docRef.set({
          'watchId': _watchId,
          'qrToken': newToken,
          'status': 'waiting',
          'platform': 'wearos',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(now.add(_qrTtl)),
          'uid': null,
        }, SetOptions(merge: true));

        _qrToken = newToken;
        _pairId = newToken;
        _pairCreatedAtLocal = now;
      } else {
        await docRef.set({
          'status': 'waiting',
          'uid': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _pairingError = "Errore logout reset: $e";
      notifyListeners();
    }
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
