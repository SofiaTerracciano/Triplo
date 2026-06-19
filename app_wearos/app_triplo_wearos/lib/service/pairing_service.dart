import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controller/user.dart';
import '../pages/PairingLoginPage/login.dart';

class PairingService extends ChangeNotifier {
  //final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFirestore _db;
  final String watchId;
  final Uuid _uuid = const Uuid();

  static const Duration _qrTtl = Duration(minutes: 12);
  String? _pairId;
  String? get pairId => _pairId;

  bool _pairing = false;
  bool get pairing => _pairing;

  String? _pairingError;
  String? get pairingError => _pairingError;

  String? _pairedUid;
  String? get pairedUid => _pairedUid;
  String? get effectiveUid => _pairedUid;

  String? _qrToken;
  String? get qrToken => _qrToken;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pairSub;
  Timer? _expiryTimer;
  DateTime? _pairCreatedAtLocal;
  bool _remoteLogoutActive = false;
  bool get remoteLogoutActive => _remoteLogoutActive;
  PairingService({required this.watchId}) : _db = FirebaseFirestore.instance;

  PairingService.withFirestore({
    required this.watchId,
    required FirebaseFirestore db,
  }) : _db = db;
  String? get qrPayload {
    if (_qrToken == null) return null;
    return "triplo://watch-pair/$watchId?t=$_qrToken";
  }

  bool get hasValidPairId {
    if (_pairId == null || _pairCreatedAtLocal == null) {
      return false;
    }


    return DateTime.now().difference(_pairCreatedAtLocal!) < _qrTtl;
  }

  @visibleForTesting
  set testPairingError(String? v) {
    _pairingError = v;
    notifyListeners();
  }

  Future<void> startWatchPairing({bool forceNew = false}) async {
    if (_pairing) return;
    if (_remoteLogoutActive) return;
    if (!forceNew && hasValidPairId) return;
    _pairing = true;
    _pairingError = null;
    notifyListeners();

    await _pairSub?.cancel();
    _pairSub = null;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    final token = _uuid.v4();

    _pairedUid = null;
    _qrToken = token;
    _pairId = token;
    _pairCreatedAtLocal = DateTime.now();
    notifyListeners();

    final docRef = _db.collection('watch_pair').doc(watchId);

    try {
      await docRef.set({
        'watchId': watchId,
        'qrToken': token,
        'status': 'waiting',
        'platform': 'wearos',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().toUtc().add(_qrTtl)),
        'uid': null,
      }, SetOptions(merge: true));

      _expiryTimer = Timer(_qrTtl, () {
        _pairingError = "Expired QR code";
        notifyListeners();
      });

      _pairSub = docRef.snapshots().listen(
            (doc) {
          final data = doc.data();
          if (data == null) return;
          _applyRemoteLogoutFlag(data);
          if (_remoteLogoutActive) return;
          final status = data['status'] as String?;
          final uid = data['uid'] as String?;
          final tokenOnDb = data['qrToken'] as String?;


          //checks the token in order to not approve stale qr codes
          if (tokenOnDb != _qrToken) return;

          if (status == 'approved' && uid != null && uid.isNotEmpty) {
            _expiryTimer?.cancel();
            _pairedUid = uid;
            notifyListeners();
          }

          if (status == 'expired') {
            _pairingError = "Expired QR code";
            notifyListeners();
          }
        },
        onError: (e) {
          _pairingError = "Pairing listener error: $e";
          notifyListeners();
        },
      );
    } catch (e) {
      _pairingError = "Pairing Error $e";
    } finally {
      _pairing = false;
      notifyListeners();
    }
  }
  void _applyRemoteLogoutFlag(Map<String, dynamic>? data) {
    final remoteLogoutAt = data?['remoteLogoutAt'];
    final active = remoteLogoutAt != null;

    if (_remoteLogoutActive != active) {
      _remoteLogoutActive = active;
      if (active) {
        _pairedUid = null;
        _pairingError = null;
      }
      notifyListeners();
    } else if (active && _pairedUid != null) {
      _pairedUid = null;
      _pairingError = null;
      notifyListeners();
    }
  }
  Future<bool> restoreWatchPairing() async {
    _pairingError = null;

    await _pairSub?.cancel();
    _pairSub = null;

    final docRef = _db.collection('watch_pair').doc(watchId);

    try {
      final snap = await docRef.get();
      final data = snap.data();
      _applyRemoteLogoutFlag(data);
      if (_remoteLogoutActive) {
        _pairSub = docRef.snapshots().listen(
              (doc) {
            final d = doc.data();
            _applyRemoteLogoutFlag(d);
            if (_remoteLogoutActive) return;

            final st = d?['status'] as String?;
            final u = d?['uid'] as String?;

            if (st == 'approved' && u != null && u.isNotEmpty) {
              if (_pairedUid != u) {
                _pairedUid = u;
                notifyListeners();
              }
            }

            if (st == 'waiting' && _pairedUid != null) {
              _pairedUid = null;
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint("restoreWatchPairing listener error: $e");
          },
        );

        return false;
      }
      if (data != null) {
        final status = data['status'] as String?;
        final uid = data['uid'] as String?;

        if (status == 'approved' && uid != null && uid.isNotEmpty) {
          _pairedUid = uid;
          notifyListeners();

          _pairSub = docRef.snapshots().listen((doc) {
            final d = doc.data();
            if (d == null) return;
            _applyRemoteLogoutFlag(d);
            if (_remoteLogoutActive) return;
            final st = d['status'] as String?;
            final u = d['uid'] as String?;
            if (st == 'approved' && u != null && u.isNotEmpty) {
              if (_pairedUid != u) {
                _pairedUid = u;
                notifyListeners();
              }
            }
            if (st == 'waiting') {
              if (_pairedUid != null) {
                _pairedUid = null;
                notifyListeners();
              }
            }
          });

          return true;
        }
      }
    } catch (e) {
      debugPrint("restoreWatchPairing get failed: $e");  //coverage:ignore-line
    }

    _pairSub = docRef.snapshots().listen(
          (doc) {
        final d = doc.data();
        if (d == null) return;
        _applyRemoteLogoutFlag(d);
        if (_remoteLogoutActive) return;
        final st = d['status'] as String?;
        final u = d['uid'] as String?;

        if (st == 'approved' && u != null && u.isNotEmpty) {
          _pairedUid = u;
          notifyListeners();
        }

        if (st == 'waiting' && _pairedUid != null) {
          _pairedUid = null;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint("restoreWatchPairing listener error: $e"); //coverage:ignore-line
      },
    );

    return false;
  }

  Future<void> resetPairingOnLogout({bool regenerateQr = true}) async {
    final docRef = _db.collection('watch_pair').doc(watchId);

    final newToken = _uuid.v4();
    final now = DateTime.now();

    try {
      if (regenerateQr) {
        await docRef.set({
          'watchId': watchId,
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
  Future<void> logoutWatch() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _pairSub?.cancel();
    _pairSub = null;

    await resetPairingOnLogout(regenerateQr: true);

    _pairedUid = null;
    _pairingError = null;
    notifyListeners();
    await restoreWatchPairing();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _pairSub?.cancel();
    super.dispose();
  }
}

class PairingGateway extends StatefulWidget {
  final Widget child;
  const PairingGateway({super.key, required this.child});

  @override
  State<PairingGateway> createState() => _PairingGatewayState();
}

class _PairingGatewayState extends State<PairingGateway> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pairing = context.read<PairingService>();
      final userCtrl = context.read<UserController>();


      if (_bootstrapped) return;
      _bootstrapped = true;

      try {
        final alreadyPaired = await pairing.restoreWatchPairing();
        if (!mounted) return;
        if (pairing.remoteLogoutActive) {
          return;
        }
        if (alreadyPaired) {
          await userCtrl.loadCurrentPairedUser();
        } else {
          await pairing.startWatchPairing(forceNew: true);
        }
      } catch (_) {

      }
    });
  }





  @override
  Widget build(BuildContext context) {
    //Pairing Gateway listens to PairingService and usercontroller
    return Consumer2<PairingService, UserController>(
      builder: (context, pairing, userCtrl, _) {
        final uid = pairing.effectiveUid;
        if (pairing.remoteLogoutActive) return const LoginPage();
        if (uid == null) return const LoginPage();

        if (userCtrl.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserController>().loadCurrentPairedUser();
          });
        }

        return widget.child;
      },
    );
  }
}
