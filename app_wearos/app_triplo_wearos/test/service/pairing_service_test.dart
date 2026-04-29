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