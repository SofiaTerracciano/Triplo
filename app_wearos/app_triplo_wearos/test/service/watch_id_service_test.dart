import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'watch_id_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential, MemoryService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeDb;
  late MockMemoryService memory;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    memory = MockMemoryService();
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();

    // Inietta le dipendenze nel service
    WatchIdService.firestore = fakeDb;
    WatchIdService.memoryService = memory;
    WatchIdService.auth = mockAuth;
  });

  // Helper: simula utente già autenticato (evita Firebase.initializeApp)
  void givenUserAlreadyAuthenticated() {
    final mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);
  }

  // Helper: simula login anonimo riuscito
  void givenAnonymousSignInSucceeds() {
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.signInAnonymously())
        .thenAnswer((_) async => mockUserCredential);
  }

  // ── getOrCreateWatchId ──────────────────────────────────────────────────

  group('WatchIdService – getOrCreateWatchId –', () {
    test('returns local watchId when already saved locally', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => 'local-watch-id');

      final result = await WatchIdService.getOrCreateWatchId();

      expect(result, 'local-watch-id');
      verify(memory.getWatchId()).called(1);
    });

    test('creates Firestore document when no local watchId exists', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => null);
      when(memory.saveWatchId(any)).thenAnswer((_) async {});

      final watchId = await WatchIdService.getOrCreateWatchId();

      expect(watchId, isNotEmpty);
      final snap = await fakeDb.collection('watch').doc(watchId).get();
      expect(snap.exists, true);
    });

    test('saves generated watchId locally', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => null);
      when(memory.saveWatchId(any)).thenAnswer((_) async {});

      final result = await WatchIdService.getOrCreateWatchId();

      verify(memory.saveWatchId(result)).called(1);
    });

    test('uses fallback UUID when Firestore creation times out', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => null);
      when(memory.saveWatchId(any)).thenAnswer((_) async {});

      // Sostituisci firestore con uno lento che fa scattare il timeout
      WatchIdService.firestore = _SlowFirestore();

      final result = await WatchIdService.getOrCreateWatchId();

      expect(result, isNotEmpty);
      verify(memory.saveWatchId(any)).called(1);
    });

    test('uses fallback UUID when Firestore throws', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => null);
      when(memory.saveWatchId(any)).thenAnswer((_) async {});

      WatchIdService.firestore = _ThrowingFirestore();

      final result = await WatchIdService.getOrCreateWatchId();

      expect(result, isNotEmpty);
      verify(memory.saveWatchId(any)).called(1);
    });

    test('calls signInAnonymously when no user is authenticated', () async {
      givenAnonymousSignInSucceeds();
      when(memory.getWatchId()).thenAnswer((_) async => 'watch-anon');

      final result = await WatchIdService.getOrCreateWatchId();

      expect(result, 'watch-anon');
      verify(mockAuth.signInAnonymously()).called(1);
    });

    test('local watchId triggers ensureWatchDoc in background', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => 'bg-watch-id');

      await WatchIdService.getOrCreateWatchId();
      // Lascia girare i microtask unawaited
      await Future.delayed(Duration.zero);

      final snap =
          await fakeDb.collection('watch').doc('bg-watch-id').get();
      expect(snap.exists, true);
    });
  });

  // ── _ensureWatchDoc ─────────────────────────────────────────────────────

  group('WatchIdService – ensureWatchDoc –', () {
    test('creates document when it does not exist', () async {
      await WatchIdService.ensureWatchDocForTest(fakeDb, 'watch-new');

      final snap = await fakeDb.collection('watch').doc('watch-new').get();
      expect(snap.exists, true);
      expect(snap.data()?['platform'], 'wearos');
      expect(snap.data()?['createdAt'], isNotNull);
      expect(snap.data()?['lastSeenAt'], isNotNull);
    });

    test('updates lastSeenAt when document already exists', () async {
      await fakeDb.collection('watch').doc('watch-exists').set({
        'platform': 'wearos',
        'createdAt': Timestamp.now(),
      });

      await WatchIdService.ensureWatchDocForTest(fakeDb, 'watch-exists');

      final snap =
          await fakeDb.collection('watch').doc('watch-exists').get();
      expect(snap.data()?['lastSeenAt'], isNotNull);
    });

    test('does not throw when firestore fails', () async {
      // ensureWatchDoc swallows exceptions internamente
      await expectLater(
        WatchIdService.ensureWatchDocForTest(
          _ThrowingFirestore(),
          'watch-err',
        ),
        completes,
      );
    });
  });

  // ── anonymous auth ──────────────────────────────────────────────────────

  group('WatchIdService – anonymous auth –', () {
    test('skips signInAnonymously when user already exists', () async {
      givenUserAlreadyAuthenticated();
      when(memory.getWatchId()).thenAnswer((_) async => 'skip-auth-id');

      await WatchIdService.getOrCreateWatchId();

      verifyNever(mockAuth.signInAnonymously());
    });

    test('calls signInAnonymously when currentUser is null', () async {
      givenAnonymousSignInSucceeds();
      when(memory.getWatchId()).thenAnswer((_) async => 'new-anon-id');

      await WatchIdService.getOrCreateWatchId();

      verify(mockAuth.signInAnonymously()).called(1);
    });
  });
}

// ── Firestore fakes ─────────────────────────────────────────────────────────

/// Firestore che non risponde mai → fa scattare il timeout da 4 s
class _SlowFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _SlowCollectionReference();
}

class _SlowCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
      Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 10));
    throw Exception('timeout');
  }
}

/// Firestore che lancia subito un'eccezione
class _ThrowingFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _ThrowingCollectionReference();

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _ThrowingDocumentReference();
}

class _ThrowingCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
      Map<String, dynamic> data) async {
    throw Exception('firestore error');
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _ThrowingDocumentReference();
}

class _ThrowingDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      throw Exception('firestore error');

  @override
  Future<void> set(Map<String, dynamic> data,
          [SetOptions? options]) async =>
      throw Exception('firestore error');

  @override
  Future<void> update(Map<Object, Object?> data) async =>
      throw Exception('firestore error');
}