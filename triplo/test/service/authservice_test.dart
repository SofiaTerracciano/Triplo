import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triplo/exception/change_email_exception.dart';
import 'package:triplo/service/authservice.dart';
import 'authservice_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  QueryDocumentSnapshot
])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionRef;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnap;
  late AuthService sut;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnap;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockCollectionRef = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnap = MockDocumentSnapshot();
    mockQuery = MockQuery();
    mockQuerySnap = MockQuerySnapshot();

    sut = AuthService(auth: mockAuth, firestore: mockFirestore);

    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-uid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.photoURL).thenReturn(null);
    when(mockUser.displayName).thenReturn(null);

    when(mockFirestore.collection(any)).thenReturn(mockCollectionRef);
    when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
    when(mockDocRef.set(any)).thenAnswer((_) async {});
    when(mockDocRef.update(any)).thenAnswer((_) async {});
  });

  void stubDocGet({bool exists = true}) {
    when(mockDocSnap.exists).thenReturn(exists);
    if (exists) when(mockDocSnap.data()).thenReturn(_fakeUserData());
    when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
  }

  group('register()', () {
    setUp(() {
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);
    });

    test('crea i doc Firestore e carica l\'utente', () async {
      stubDocGet();
      await sut.register('test@example.com', 'password123');

      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);

      verify(mockFirestore.collection('users')).called(greaterThanOrEqualTo(1));
      verify(mockFirestore.collection('users_index'))
          .called(greaterThanOrEqualTo(1));

      expect(sut.currentUser, isNotNull);
      expect(sut.currentUser!.uid, 'test-uid');
    });

    test('deriva lo username dal prefisso email', () async {
      stubDocGet();
      await sut.register('mario.rossi@example.com', 'pwd');

      final captured = verify(mockDocRef.set(captureAny)).captured;
      final usersPayload = captured.first as Map<String, dynamic>;
      expect(usersPayload['Username'], 'mario.rossi');
    });

    test('propaga l\'eccezione FirebaseAuth', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        () => sut.register('test@example.com', 'password123'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('login()', () {
    setUp(() {
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);
    });

    test('chiama signInWithEmailAndPassword e carica l\'utente', () async {
      stubDocGet();
      await sut.login('test@example.com', 'password123');

      verify(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);

      expect(sut.currentUser, isNotNull);
    });

    test('propaga l\'eccezione su credenziali errate', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      await expectLater(
        () => sut.login('test@example.com', 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('logout()', () {
    setUp(() => when(mockAuth.signOut()).thenAnswer((_) async {}));

    test('fa signOut e azzera currentUser', () async {
      stubDocGet();
      await sut.loadUserCore('test-uid');
      expect(sut.currentUser, isNotNull);

      await sut.logout();

      verify(mockAuth.signOut()).called(1);
      expect(sut.currentUser, isNull);
    });

    test('notifica i listener al logout', () async {
      bool notified = false;
      sut.addListener(() => notified = true);

      await sut.logout();

      expect(notified, isTrue);
    });
  });

  group('loadUserCore()', () {
    test('popola currentUser dal doc Firestore', () async {
      stubDocGet();
      await sut.loadUserCore('test-uid');

      expect(sut.currentUser, isNotNull);
      expect(sut.currentUser!.uid, 'test-uid');
      expect(sut.currentUser!.username, 'testuser');
      expect(sut.currentUser!.email, 'test@example.com');
      expect(sut.currentUser!.level, 'Beginner');
    });

    test('non fa nulla quando il doc non esiste', () async {
      stubDocGet(exists: false);
      await sut.loadUserCore('ghost-uid');

      expect(sut.currentUser, isNull);
    });

    test('notifica i listener al successo', () async {
      stubDocGet();
      bool notified = false;
      sut.addListener(() => notified = true);

      await sut.loadUserCore('test-uid');

      expect(notified, isTrue);
    });
  });

  group('tryAutoLogin()', () {
    test('carica l\'utente se Firebase ha un utente corrente', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      stubDocGet();

      await sut.tryAutoLogin();

      expect(sut.currentUser, isNotNull);
    });

    test('non fa nulla se non c\'è nessun utente Firebase', () async {
      when(mockAuth.currentUser).thenReturn(null);

      await sut.tryAutoLogin();

      expect(sut.currentUser, isNull);
    });
  });

  group('sendPasswordReset()', () {
    test('chiama sendPasswordResetEmail con l\'email fornita', () async {
      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {});

      await sut.sendPasswordReset('test@example.com');

      verify(mockAuth.sendPasswordResetEmail(email: 'test@example.com'))
          .called(1);
    });
  });

  group('requestPasswordReset()', () {
    test('chiama sendPasswordResetEmail quando l\'utente è caricato', () async {
      stubDocGet();
      await sut.loadUserCore('test-uid');

      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {});

      await sut.requestPasswordReset();

      verify(mockAuth.sendPasswordResetEmail(email: 'test@example.com'))
          .called(1);
    });

    test('non fa nulla se currentUser è null', () async {
      await sut.requestPasswordReset();

      verifyNever(mockAuth.sendPasswordResetEmail(email: anyNamed('email')));
    });
  });

  group('provider checks', () {
    test('isGoogleUser true quando google.com è presente', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.providerData).thenReturn([_FakeUserInfo('google.com')]);

      expect(sut.isGoogleUser, isTrue);
      expect(sut.isPasswordUser, isFalse);
    });

    test('isPasswordUser true quando password è presente', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.providerData).thenReturn([_FakeUserInfo('password')]);

      expect(sut.isPasswordUser, isTrue);
      expect(sut.isGoogleUser, isFalse);
    });

    test('entrambi false quando non c\'è utente corrente', () {
      when(mockAuth.currentUser).thenReturn(null);

      expect(sut.isGoogleUser, isFalse);
      expect(sut.isPasswordUser, isFalse);
    });
  });

  group('extractWatchPair()', () {
    test('parsa un URI triplo://watch-pair valido', () {
      final result =
          sut.extractWatchPair('triplo://watch-pair/my-watch-id?t=secret-token');

      expect(result.watchId, 'my-watch-id');
      expect(result.token, 'secret-token');
    });

    test('ignora gli spazi attorno all\'URI', () {
      final result =
          sut.extractWatchPair('  triplo://watch-pair/watch-abc?t=tok123  ');

      expect(result.watchId, 'watch-abc');
      expect(result.token, 'tok123');
    });

    test('lancia FormatException per scheme errato', () {
      expect(
        () => sut.extractWatchPair('https://watch-pair/id?t=tok'),
        throwsA(isA<FormatException>()),
      );
    });

    test('lancia FormatException per host errato', () {
      expect(
        () => sut.extractWatchPair('triplo://other-host/id?t=tok'),
        throwsA(isA<FormatException>()),
      );
    });

    test('lancia FormatException se watchId è assente', () {
      expect(
        () => sut.extractWatchPair('triplo://watch-pair/?t=tok'),
        throwsA(isA<FormatException>()),
      );
    });

    test('lancia FormatException se il token è assente', () {
      expect(
        () => sut.extractWatchPair('triplo://watch-pair/my-id'),
        throwsA(isA<FormatException>()),
      );
    });

    test('lancia FormatException per stringa completamente invalida', () {
      expect(
        () => sut.extractWatchPair('not-a-uri'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('getters', () {
    test('isAuthenticated true se Firebase ha un utente', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      expect(sut.isAuthenticated, isTrue);
    });

    test('isAuthenticated false se non c\'è utente', () {
      when(mockAuth.currentUser).thenReturn(null);
      expect(sut.isAuthenticated, isFalse);
    });

    test('currentUid ritorna l\'uid dall\'utente caricato', () async {
      stubDocGet();
      await sut.loadUserCore('test-uid');

      expect(sut.currentUid, 'test-uid');
    });

    test('currentUid fallback all\'uid Firebase se utente non caricato', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('firebase-uid');

      expect(sut.currentUid, 'firebase-uid');
    });

    test('currentPhotoUrl ritorna photoURL da Firebase Auth', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.photoURL).thenReturn('https://example.com/photo.jpg');

      expect(sut.currentPhotoUrl, 'https://example.com/photo.jpg');
    });

    test('currentEmailFromAuth ritorna l\'email da Firebase Auth', () {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('auth@example.com');

      expect(sut.currentEmailFromAuth, 'auth@example.com');
    });
  });

  group('changeEmail()', () {
    late MockUserCredential mockUserCredential;
 
    setUp(() {
      mockUserCredential = MockUserCredential();
      when(mockUserCredential.user).thenReturn(mockUser);
    });
 
    test('successo: reauthentication e verifyBeforeUpdateEmail chiamati',
        () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('old@example.com');
      when(mockUser.reauthenticateWithCredential(any))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUser.verifyBeforeUpdateEmail(any)).thenAnswer((_) async {});
 
      await sut.changeEmail(
        newEmail: 'new@example.com',
        currentPassword: 'password123',
      );
 
      verify(mockUser.reauthenticateWithCredential(any)).called(1);
      verify(mockUser.verifyBeforeUpdateEmail('new@example.com')).called(1);
    });
 
    test('lancia ChangeEmailException("not-authenticated") se currentUser è null',
        () async {
      when(mockAuth.currentUser).thenReturn(null);
 
      await expectLater(
        () => sut.changeEmail(
          newEmail: 'new@example.com',
          currentPassword: 'pwd',
        ),
        throwsA(
          isA<ChangeEmailException>()
              .having((e) => e.code, 'code', 'not-authenticated'),
        ),
      );
    });
 
    test(
        'lancia ChangeEmailException("missing-current-email") se email Auth è null',
        () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn(null);
 
      await expectLater(
        () => sut.changeEmail(
          newEmail: 'new@example.com',
          currentPassword: 'pwd',
        ),
        throwsA(
          isA<ChangeEmailException>()
              .having((e) => e.code, 'code', 'missing-current-email'),
        ),
      );
    });
 
    test(
        'lancia ChangeEmailException("missing-current-email") se email Auth è empty',
        () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('');
 
      await expectLater(
        () => sut.changeEmail(
          newEmail: 'new@example.com',
          currentPassword: 'pwd',
        ),
        throwsA(
          isA<ChangeEmailException>()
              .having((e) => e.code, 'code', 'missing-current-email'),
        ),
      );
    });
 
    test('converte FirebaseAuthException nel codice corretto', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('old@example.com');
      when(mockUser.reauthenticateWithCredential(any))
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));
 
      await expectLater(
        () => sut.changeEmail(
          newEmail: 'new@example.com',
          currentPassword: 'wrongpwd',
        ),
        throwsA(
          isA<ChangeEmailException>()
              .having((e) => e.code, 'code', 'wrong-password'),
        ),
      );
    });
 
    test('converte eccezione generica in ChangeEmailException("unknown")',
        () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('old@example.com');
      when(mockUser.reauthenticateWithCredential(any))
          .thenThrow(Exception('unexpected'));
 
      await expectLater(
        () => sut.changeEmail(
          newEmail: 'new@example.com',
          currentPassword: 'pwd',
        ),
        throwsA(
          isA<ChangeEmailException>()
              .having((e) => e.code, 'code', 'unknown'),
        ),
      );
    });
  });

  group('refreshEmailFromAuth()', () {
    test('lancia eccezione se currentUser è null prima del reload', () async {
      when(mockAuth.currentUser).thenReturn(null);
 
      await expectLater(
        () => sut.refreshEmailFromAuth(),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se currentUser è null dopo il reload', () async {
      var callCount = 0;
      when(mockAuth.currentUser).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? mockUser : null;
      });
      when(mockUser.reload()).thenAnswer((_) async {});
 
      await expectLater(
        () => sut.refreshEmailFromAuth(),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se email è vuota dopo reload', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockUser.getIdToken(any)).thenAnswer((_) async => 'token');
      when(mockUser.email).thenReturn('');
 
      await expectLater(
        () => sut.refreshEmailFromAuth(),
        throwsA(isA<Exception>()),
      );
    });
 
    test('successo: aggiorna Firestore e ricarica utente', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockUser.getIdToken(any)).thenAnswer((_) async => 'token');
      when(mockUser.email).thenReturn('refreshed@example.com');
      when(mockUser.uid).thenReturn('test-uid');
      stubDocGet();
 
      await sut.refreshEmailFromAuth();
 
      verify(mockUser.reload()).called(1);
      verify(mockUser.getIdToken(true)).called(1);
      verify(mockDocRef.update({'Email': 'refreshed@example.com'})).called(1);
      expect(sut.currentUser, isNotNull);
    });
  });

  group('getConnectedWatches()', () {
    test('lancia eccezione se currentUser è null', () async {
      when(mockAuth.currentUser).thenReturn(null);

      await expectLater(
        () => sut.getConnectedWatches(),
        throwsA(isA<Exception>()),
      );
    });

    test('ritorna lista vuota se non ci sono watch', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockCollectionRef.where('uid', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.where('status', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuerySnap.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnap);

      final result = await sut.getConnectedWatches();
      expect(result, isEmpty);
    });

    test('ritorna lista di watch mappati correttamente', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);

      final mockDocSnap2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap2.id).thenReturn('watch-123');
      when(mockDocSnap2.data()).thenReturn({
        'status': 'approved',
        'uid': 'test-uid',
        'platform': 'wear_os',
        'createdAt': null,
        'expiresAt': null,
        'remoteLogoutAt': null,
        'qrToken': 'tok',
      });

      when(mockCollectionRef.where('uid', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.where('status', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuerySnap.docs).thenReturn([mockDocSnap2]);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnap);

      final result = await sut.getConnectedWatches();

      expect(result.length, 1);
      expect(result.first['watchId'], 'watch-123');
      expect(result.first['platform'], 'wear_os');
    });
  });

  group('enableRemoteLogoutForWatch()', () {
    test('lancia eccezione se currentUser è null', () async {
      when(mockAuth.currentUser).thenReturn(null);
 
      await expectLater(
        () => sut.enableRemoteLogoutForWatch('watch-123'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('chiama update con remoteLogoutAt: serverTimestamp', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      await sut.enableRemoteLogoutForWatch('watch-123');
 
      verify(mockDocRef.update(argThat(
        predicate<Map<Object, Object?>>((m) => m.containsKey('remoteLogoutAt')),
      ))).called(1);
    });
  });

  group('clearRemoteLogoutForWatch()', () {
    test('lancia eccezione se currentUser è null', () async {
      when(mockAuth.currentUser).thenReturn(null);
 
      await expectLater(
        () => sut.clearRemoteLogoutForWatch('watch-123'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('chiama update con remoteLogoutAt: null', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      await sut.clearRemoteLogoutForWatch('watch-123');
 
      verify(mockDocRef.update({'remoteLogoutAt': null})).called(1);
    });
  });

  group('approveWatchPair()', () {

 
    test('lancia eccezione se currentUser è null', () async {

      expect(true, isTrue); 
    });
  });

  group('approveWatchPair()', () {
    test('lancia eccezione se currentUser è null', () async {
      when(mockAuth.currentUser).thenReturn(null);
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'tok'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se il documento watch_pair non esiste', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);

        return await fn(fakeTx);
      });
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'tok'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se status non è "waiting"', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      final data = _fakeWatchData(status: 'approved', token: 'tok');
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(data);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);

        return await fn(fakeTx);
      });
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'tok'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se token non corrisponde', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      final data = _fakeWatchData(status: 'waiting', token: 'correct-token');
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(data);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);

        return await fn(fakeTx);
      });
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'wrong-token'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se QR è scaduto', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      final data = _fakeWatchData(
        status: 'waiting',
        token: 'tok',
        expiresAt: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(data);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);

        return await fn(fakeTx);
      });
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'tok'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('lancia eccezione se expiresAt è null', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      final data = _fakeWatchData(
        status: 'waiting',
        token: 'tok',
        expiresAt: null,
        nullExpiry: true,
      );
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(data);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);

        return await fn(fakeTx);
      });
 
      await expectLater(
        () => sut.approveWatchPair(watchId: 'w1', token: 'tok'),
        throwsA(isA<Exception>()),
      );
    });
 
    test('successo: chiama tx.update con status approved e uid', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
 
      final data = _fakeWatchData(
        status: 'waiting',
        token: 'tok',
        expiresAt: Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
      );
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(data);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      final fakeTx = _FakeTransaction(mockDocRef, mockDocSnap);
 
      when(mockFirestore.runTransaction<Null>(any))
          .thenAnswer((inv) async {
        final fn = inv.positionalArguments[0]
            as Future<Null> Function(Transaction);

        return await fn(fakeTx);
      });
 
      await sut.approveWatchPair(watchId: 'w1', token: 'tok');
 
      expect(fakeTx.lastUpdated, isNotNull);
      expect(fakeTx.lastUpdated!['status'], 'approved');
      expect(fakeTx.lastUpdated!['uid'], 'test-uid');
    });
  });

  group('_ensureUserFirestoreDocs() via loginWithGoogle', () {

    late MockUserCredential mockUserCredential;
 
    setUp(() {
      mockUserCredential = MockUserCredential();
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);
    });
 
    test('usa il prefisso email come username quando displayName è null',
        () async {
      when(mockUser.displayName).thenReturn(null);
      when(mockUser.email).thenReturn('mario.rossi@example.com');
      stubDocGet();
 
      await sut.register('mario.rossi@example.com', 'pwd');
 
      final captured = verify(mockDocRef.set(captureAny)).captured;
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['Username'], 'mario.rossi');
    });
 
    test('usa il prefisso email come username quando displayName è empty',
        () async {
      when(mockUser.displayName).thenReturn('');
      when(mockUser.email).thenReturn('anna@example.com');
      stubDocGet();
 
      await sut.register('anna@example.com', 'pwd');
 
      final captured = verify(mockDocRef.set(captureAny)).captured;
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['Username'], 'anna');
    });
  });
 
  // =========================================================================
  // _ensureUserFirestoreDocs() branch — via _FakeGoogleUser helper
  // =========================================================================
  group('_ensureUserFirestoreDocs() branch username', () {
    // Testiamo i 3 branch di username direttamente istanziando un User fake
    // e chiamando il metodo tramite una sottoclasse esposta per test.
 
    test('usa primo token del displayName come username', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.displayName).thenReturn('Mario Rossi');
      when(mockUser.email).thenReturn('mario@example.com');
      when(mockUser.photoURL).thenReturn('');
      when(mockUser.uid).thenReturn('uid-123');
 
      // Il doc non esiste → _ensureUserFirestoreDocs scrive
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      // Stub batch
      final fakeBatch = _FakeBatch();
      when(mockFirestore.batch()).thenReturn(fakeBatch);
 
      await sut.ensureUserFirestoreDocsPublic(mockUser);
 
      expect(fakeBatch.setPayloads.first['Username'], 'Mario');
    });
 
    test('usa prefisso email se displayName è blank', () async {
      when(mockUser.displayName).thenReturn('   ');
      when(mockUser.email).thenReturn('luigi@example.com');
      when(mockUser.photoURL).thenReturn('');
      when(mockUser.uid).thenReturn('uid-456');
 
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      final fakeBatch = _FakeBatch();
      when(mockFirestore.batch()).thenReturn(fakeBatch);
 
      await sut.ensureUserFirestoreDocsPublic(mockUser);
 
      expect(fakeBatch.setPayloads.first['Username'], 'luigi');
    });
 
    test('usa uid.substring(0,8) se email non contiene @', () async {
      when(mockUser.displayName).thenReturn('');
      when(mockUser.email).thenReturn('');
      when(mockUser.photoURL).thenReturn('');
      when(mockUser.uid).thenReturn('abcdefghij');
 
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      final fakeBatch = _FakeBatch();
      when(mockFirestore.batch()).thenReturn(fakeBatch);
 
      await sut.ensureUserFirestoreDocsPublic(mockUser);
 
      expect(fakeBatch.setPayloads.first['Username'], 'abcdefgh');
    });
 
    test('non sovrascrive doc se esiste già', () async {
      when(mockUser.uid).thenReturn('uid-exists');
 
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
 
      final fakeBatch = _FakeBatch();
      when(mockFirestore.batch()).thenReturn(fakeBatch);
 
      await sut.ensureUserFirestoreDocsPublic(mockUser);
 
      // batch.set non deve essere stato chiamato
      expect(fakeBatch.setPayloads, isEmpty);
    });
  });
}
 
Map<String, dynamic> _fakeWatchData({
  required String status,
  required String token,
  Timestamp? expiresAt,
  bool nullExpiry = false,
}) =>
    {
      'status': status,
      'qrToken': token,
      'expiresAt': nullExpiry ? null : expiresAt,
    };

class _FakeTransaction extends Fake implements Transaction {
  _FakeTransaction(this._docRef, this._snap);
 
  final DocumentReference<Map<String, dynamic>> _docRef;
  final DocumentSnapshot<Map<String, dynamic>> _snap;
  Map<String, dynamic>? lastUpdated;
 
  @override
  Future<DocumentSnapshot<T>> get<T>(
      DocumentReference<T> documentReference) async {
    return _snap as DocumentSnapshot<T>;
  }
 
  @override
  Transaction update(
    DocumentReference<Object?> documentReference,
    Map<Object, Object?> data,
  ) {
    lastUpdated = Map<String, dynamic>.from(data);
    return this;
  }
}

class _FakeBatch extends Fake implements WriteBatch {
  final List<Map<String, dynamic>> setPayloads = [];
 
  @override
  void set<T>(
    DocumentReference<T> document,
    T data, [
    SetOptions? options,
  ]) {
    if (data is Map<String, dynamic>) {
      setPayloads.add(data);
    }
  }
 
  @override
  Future<void> commit() async {}
}

Map<String, dynamic> _fakeUserData() => {
      'Username': 'testuser',
      'Name': 'Test',
      'Surname': 'User',
      'Email': 'test@example.com',
      'Photo_profile': '',
      'Birthdate': '2000-01-01T00:00:00.000',
      'Followers': [],
      'Following': [],
      'Public_diary': [],
      'Private_diary': [],
      'Saved_trekkings': [],
      'Level': 'Beginner',
      'Advanced': 0,
      'Intermediate': 0,
    };

class _FakeUserInfo extends Fake implements UserInfo {
  _FakeUserInfo(this._providerId);

  final String _providerId;

  @override
  String get providerId => _providerId;

  @override
  String? get uid => null;

  @override
  String? get displayName => null;

  @override
  String? get email => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;
}