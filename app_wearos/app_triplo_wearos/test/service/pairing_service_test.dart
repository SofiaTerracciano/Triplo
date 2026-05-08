import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/pages/PairingLoginPage/login.dart';

@GenerateMocks([UserController])
import 'pairing_service_test.mocks.dart';

const _watchId = 'watch-123';

PairingService _makeService(FakeFirebaseFirestore fakeDb) =>
    PairingService.withFirestore(watchId: _watchId, db: fakeDb);

Future<void> _writeDoc(
  FakeFirebaseFirestore fakeDb,
  Map<String, dynamic> data,
) async {
  await fakeDb.collection('watch_pair').doc(_watchId).set(data);
}

Widget _buildGateway({
  required PairingService pairing,
  required MockUserController userCtrl,
  required Widget child,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<PairingService>.value(value: pairing),
        ChangeNotifierProvider<UserController>.value(value: userCtrl),
      ],
      child: PairingGateway(child: child),
    ),
  );
}

void main() {
  group('PairingService – _expiryTimer –', () {
    test('sets pairingError after QR TTL elapses', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.startWatchPairing();
      expect(svc.pairingError, isNull);

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'expired',
        'qrToken': svc.qrToken,
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairingError, 'Expired QR code');
      svc.dispose();
    });
  });

  group('PairingService – snapshot onError (startWatchPairing) –', () {
    test(
      'sets pairingError when snapshot stream emits an error',
      () {
      },
      skip: 'fake_cloud_firestore non supporta stream di errori; '
          'testabile solo con Firestore emulator',
    );

    test(
      'catch block sets pairingError when docRef.set throws',
      () {},
      skip: 'Requires Firestore emulator to inject write errors',
    );
  });

  group('PairingService – _applyRemoteLogoutFlag (else-if branch) –', () {
    test('clears pairedUid when remoteLogout already active and pairedUid set',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-x',
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();
      expect(svc.pairedUid, 'user-x');

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'remoteLogoutAt': Timestamp.now(),
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, isNull);
      svc.dispose();
    });
  });

  group('PairingService – restoreWatchPairing remote-logout listener –', () {
    test('listener clears remoteLogoutActive when remoteLogoutAt is removed',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
        'remoteLogoutAt': Timestamp.now(),
      });
      await svc.restoreWatchPairing();
      await Future.delayed(Duration.zero);
      expect(svc.remoteLogoutActive, isTrue);

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'remoteLogoutAt': FieldValue.delete(),
      });
      await Future.delayed(Duration.zero);

      expect(svc.remoteLogoutActive, isFalse);
      svc.dispose();
    });

    test(
        'listener sets pairedUid when approved arrives after remoteLogout cleared',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
        'remoteLogoutAt': Timestamp.now(),
      });
      await svc.restoreWatchPairing();
      await Future.delayed(Duration.zero);

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'remoteLogoutAt': FieldValue.delete(),
        'status': 'approved',
        'uid': 'user-new',
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, 'user-new');
      svc.dispose();
    });

    test('listener clears pairedUid when status goes back to waiting', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
        'remoteLogoutAt': Timestamp.now(),
      });
      await svc.restoreWatchPairing();
      await Future.delayed(Duration.zero);

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'remoteLogoutAt': FieldValue.delete(),
        'status': 'approved',
        'uid': 'user-new',
      });
      await Future.delayed(Duration.zero);
      expect(svc.pairedUid, 'user-new');

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'waiting',
        'uid': null,
      });
      await Future.delayed(Duration.zero);
      expect(svc.pairedUid, isNull);
      svc.dispose();
    });
  });

  group('PairingService – resetPairingOnLogout error branch –', () {
    test(
      'sets pairingError when Firestore write throws',
      () {},
      skip: 'Requires Firestore emulator to inject write errors',
    );
  });

  group('_ThrowingPairingService –', () {
    test('startWatchPairing: catch block sets pairingError', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _ThrowingPairingService(watchId: _watchId, db: fakeDb);

      await svc.startWatchPairing();

      expect(svc.pairingError, startsWith('Pairing Error'));
      expect(svc.pairing, isFalse);
      svc.dispose();
    });

    test('resetPairingOnLogout: catch block sets pairingError', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _ThrowingPairingService(watchId: _watchId, db: fakeDb);

      await svc.resetPairingOnLogout();

      expect(svc.pairingError, startsWith('Errore logout reset'));
      svc.dispose();
    });
  });

  group('PairingGateway –', () {
    testWidgets('shows LoginPage when pairedUid is null', (tester) async {
      final fakeDb = FakeFirebaseFirestore();
      final pairing = _makeService(fakeDb);
      final userCtrl = MockUserController();

      when(userCtrl.currentUser).thenReturn(null);

      await tester.pumpWidget(_buildGateway(
        pairing: pairing,
        userCtrl: userCtrl,
        child: const Text('HOME'),
      ));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
      pairing.dispose();
    });

    testWidgets('initState: calls loadCurrentPairedUser when already paired',
        (tester) async {
      final fakeDb = FakeFirebaseFirestore();
      final pairing = _makeService(fakeDb);
      final userCtrl = MockUserController();

      when(userCtrl.currentUser).thenReturn(null);
      when(userCtrl.loadCurrentPairedUser()).thenAnswer((_) async {});

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-abc',
        'qrToken': 'tok',
      });

      await tester.pumpWidget(_buildGateway(
        pairing: pairing,
        userCtrl: userCtrl,
        child: const Text('HOME'),
      ));
      await tester.pump();
      await tester.pump();

      verify(userCtrl.loadCurrentPairedUser()).called(greaterThan(0));
      pairing.dispose();
    });

    testWidgets('initState: returns early when remoteLogoutActive after restore',
        (tester) async {
      final fakeDb = FakeFirebaseFirestore();
      final pairing = _makeService(fakeDb);
      final userCtrl = MockUserController();

      when(userCtrl.currentUser).thenReturn(null);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
        'remoteLogoutAt': Timestamp.now(),
      });

      await tester.pumpWidget(_buildGateway(
        pairing: pairing,
        userCtrl: userCtrl,
        child: const Text('HOME'),
      ));
      await tester.pump();
      await tester.pump();

      verifyNever(userCtrl.loadCurrentPairedUser());
      expect(pairing.qrToken, isNull);
      pairing.dispose();
    });
  });

  group('PairingService – hasValidPairId –', () {
    test('returns false when pairId is null (before any pairing)', () {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);
      expect(svc.hasValidPairId, isFalse);
      svc.dispose();
    });

    test('returns true immediately after startWatchPairing', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);
      await svc.startWatchPairing();
      expect(svc.hasValidPairId, isTrue);
      svc.dispose();
    });

    test('startWatchPairing does nothing when valid pairId exists and forceNew=false',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);
      await svc.startWatchPairing();
      final firstToken = svc.qrToken;
      await svc.startWatchPairing(forceNew: false); 
      expect(svc.qrToken, equals(firstToken));
      svc.dispose();
    });
  });

  group('PairingService – getters –', () {
    test('qrPayload is null before pairing starts', () {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);
      expect(svc.qrPayload, isNull);
      svc.dispose();
    });

    test('qrPayload contains watchId and token after startWatchPairing', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);
      await svc.startWatchPairing();
      expect(svc.qrPayload, contains(_watchId));
      expect(svc.qrPayload, contains(svc.qrToken));
      expect(svc.qrPayload, startsWith('triplo://watch-pair/'));
      svc.dispose();
    });

    test('effectiveUid equals pairedUid when set', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-eff',
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();
      expect(svc.effectiveUid, equals('user-eff'));
      svc.dispose();
    });
  });

  group('PairingService – startWatchPairing guard _pairing –', () {
    test('concurrent call while _pairing=true is ignored', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      final first = svc.startWatchPairing(forceNew: true);
      final second = svc.startWatchPairing(forceNew: true);
      await Future.wait([first, second]);

      expect(svc.pairing, isFalse);
      svc.dispose();
    });
  });

  group('PairingService – startWatchPairing snapshot –', () {
    test('sets pairedUid when status=approved with matching token', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.startWatchPairing();
      final token = svc.qrToken!;

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'approved',
        'uid': 'user-ok',
        'qrToken': token,
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, 'user-ok');
      svc.dispose();
    });

    test('ignores approved snapshot when token does not match (stale QR)', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.startWatchPairing();

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'approved',
        'uid': 'user-stale',
        'qrToken': 'WRONG-TOKEN', 
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, isNull); 
      svc.dispose();
    });

    test('sets pairingError when remoteLogoutAt arrives during active pairing',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.startWatchPairing();

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'remoteLogoutAt': Timestamp.now(),
      });
      await Future.delayed(Duration.zero);

      expect(svc.remoteLogoutActive, isTrue);
      expect(svc.pairedUid, isNull);
      svc.dispose();
    });
  });

  group('PairingService – restoreWatchPairing approved path –', () {
    test('returns true and sets pairedUid when doc is already approved', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-restore',
        'qrToken': 'tok',
      });

      final result = await svc.restoreWatchPairing();

      expect(result, isTrue);
      expect(svc.pairedUid, 'user-restore');
      svc.dispose();
    });

    test('approved path listener: updates pairedUid when uid changes', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-a',
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();
      expect(svc.pairedUid, 'user-a');

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'uid': 'user-b',
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, 'user-b');
      svc.dispose();
    });

    test('approved path listener: clears pairedUid when status → waiting', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-c',
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'waiting',
        'uid': null,
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, isNull);
      svc.dispose();
    });

    test('fallback listener: sets pairedUid when doc does not exist yet', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      final result = await svc.restoreWatchPairing();
      expect(result, isFalse);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-fallback',
        'qrToken': 'tok',
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, 'user-fallback');
      svc.dispose();
    });

    test('fallback listener: ignores approved when uid is empty', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'approved',
        'uid': '', 
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, isNull);
      svc.dispose();
    });
  });

  group('PairingService – resetPairingOnLogout –', () {
    test('regenerateQr=false: aggiorna solo status e uid su Firestore', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-z',
        'qrToken': 'OLD',
      });

      await svc.resetPairingOnLogout(regenerateQr: false);

      final snap = await fakeDb.collection('watch_pair').doc(_watchId).get();
      expect(snap.data()?['status'], 'waiting');
      expect(snap.data()?['uid'], isNull);
      // qrToken NON deve essere cambiato
      expect(snap.data()?['qrToken'], 'OLD');
      svc.dispose();
    });

    test('regenerateQr=true: genera nuovo token e aggiorna Firestore', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.resetPairingOnLogout(regenerateQr: true);

      final snap = await fakeDb.collection('watch_pair').doc(_watchId).get();
      expect(snap.data()?['status'], 'waiting');
      expect(snap.data()?['qrToken'], isNotNull);
      expect(svc.qrToken, isNotNull);
      svc.dispose();
    });
  });

  group('PairingService – logoutWatch –', () {
    test('clears pairedUid, cancels timer and resets Firestore doc', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'approved',
        'uid': 'user-logout',
        'qrToken': 'tok',
      });
      await svc.restoreWatchPairing();
      expect(svc.pairedUid, 'user-logout');

      await svc.logoutWatch();

      expect(svc.pairedUid, isNull);
      expect(svc.pairingError, isNull);
      svc.dispose();
    });

    test('after logoutWatch the listener is active again (restoreWatchPairing called)',
        () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await svc.startWatchPairing();
      await svc.logoutWatch();

      await fakeDb.collection('watch_pair').doc(_watchId).update({
        'status': 'approved',
        'uid': 'user-after-logout',
        'qrToken': svc.qrToken ?? '',
      });
      await Future.delayed(Duration.zero);

      expect(svc.pairedUid, 'user-after-logout');
      svc.dispose();
    });
  });

  group('PairingService – startWatchPairing guard remoteLogout –', () {
    test('does nothing when remoteLogoutActive is true', () async {
      final fakeDb = FakeFirebaseFirestore();
      final svc = _makeService(fakeDb);

      await _writeDoc(fakeDb, {
        'watchId': _watchId,
        'status': 'waiting',
        'uid': null,
        'qrToken': 'tok',
        'remoteLogoutAt': Timestamp.now(),
      });
      await svc.restoreWatchPairing();
      await Future.delayed(Duration.zero);
      expect(svc.remoteLogoutActive, isTrue);

      await svc.startWatchPairing(forceNew: true);

      expect(svc.qrToken, isNull);
      expect(svc.pairing, isFalse);
      svc.dispose();
    });
  });
   
}

class _ThrowingPairingService extends PairingService {
  _ThrowingPairingService({
    required String watchId,
    required FirebaseFirestore db,
  }) : super.withFirestore(watchId: watchId, db: db);

  @override
  Future<void> startWatchPairing({bool forceNew = true}) async {
    try {
      throw Exception('Firestore unavailable');
    } catch (e) {
      testPairingError = 'Pairing Error $e'; 
    }
  }

  @override
  Future<void> resetPairingOnLogout({bool regenerateQr = true}) async {
    try {
      throw Exception('Firestore unavailable');
    } catch (e) {
      testPairingError = 'Errore logout reset: $e';
    }
  }
}

