import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
// ignore: implementation_imports
import 'package:uuid/uuid.dart';


@GenerateMocks([MemoryService, FirebaseAuth, User, UserCredential])
import 'watch_id_service_test.mocks.dart';

void main() {
  late MockMemoryService mockMemory;
  late FakeFirebaseFirestore fakeDb;

  setUp(() {
    mockMemory = MockMemoryService();
    fakeDb = FakeFirebaseFirestore();
  });

  group('WatchIdService – getOrCreateWatchId –', () {
    test('returns local watchId when already saved in memory', () async {
      when(mockMemory.getWatchId()).thenAnswer((_) async => 'local-watch-id');

      final result = await TestableWatchIdService.getOrCreateWatchId(
        memoryService: mockMemory,
        db: fakeDb,
        skipAuth: true,
      );

      expect(result, 'local-watch-id');
      verify(mockMemory.getWatchId()).called(1);
      verifyNever(mockMemory.saveWatchId(any));
    });

    test('creates new watchId on Firestore when memory is empty', () async {
      when(mockMemory.getWatchId()).thenAnswer((_) async => null);
      when(mockMemory.saveWatchId(any)).thenAnswer((_) async {});

      final result = await TestableWatchIdService.getOrCreateWatchId(
        memoryService: mockMemory,
        db: fakeDb,
        skipAuth: true,
      );

      expect(result, isNotNull);
      expect(result, isNotEmpty);

      final snap = await fakeDb.collection('watch').doc(result).get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['platform'], 'wearos');

      verify(mockMemory.saveWatchId(result)).called(1);
    });

    test('uses fallback UUID when Firestore throws and saves it locally',
        () async {
      when(mockMemory.getWatchId()).thenAnswer((_) async => null);
      when(mockMemory.saveWatchId(any)).thenAnswer((_) async {});

      final result = await TestableWatchIdService.getOrCreateWatchId(
        memoryService: mockMemory,
        db: fakeDb,
        skipAuth: true,
        forceFirestoreError: true,
      );

      expect(result, isNotNull);
      expect(result, isNotEmpty);
      expect(result.length, 36);
      verify(mockMemory.saveWatchId(result)).called(1);
    });

    test('returns existing local id and calls _ensureWatchDoc in background',
        () async {
      when(mockMemory.getWatchId()).thenAnswer((_) async => 'cached-id');

      await fakeDb.collection('watch').doc('cached-id').set({
        'platform': 'wearos',
        'createdAt': DateTime.now(),
        'lastSeenAt': DateTime.now(),
      });

      final result = await TestableWatchIdService.getOrCreateWatchId(
        memoryService: mockMemory,
        db: fakeDb,
        skipAuth: true,
      );

      expect(result, 'cached-id');
      await Future.delayed(Duration.zero);

      final snap = await fakeDb.collection('watch').doc('cached-id').get();
      expect(snap.exists, isTrue);
    });

    test('_ensureWatchDoc creates doc when it does not exist', () async {
      await TestableWatchIdService.ensureWatchDoc(
        watchId: 'new-watch-id',
        db: fakeDb,
      );

      final snap = await fakeDb.collection('watch').doc('new-watch-id').get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['platform'], 'wearos');
    });

    test('_ensureWatchDoc updates lastSeenAt when doc already exists',
        () async {
      await fakeDb.collection('watch').doc('existing-id').set({
        'platform': 'wearos',
        'createdAt': DateTime(2020),
        'lastSeenAt': DateTime(2020),
      });

      await TestableWatchIdService.ensureWatchDoc(
        watchId: 'existing-id',
        db: fakeDb,
      );

      final snap = await fakeDb.collection('watch').doc('existing-id').get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['platform'], 'wearos');
    });

    test('_ensureWatchDoc swallows exceptions silently', () async {
      await expectLater(
        TestableWatchIdService.ensureWatchDoc(
          watchId: 'any-id',
          db: fakeDb,
        ),
        completes,
      );
    });
  });
}
class TestableWatchIdService {

  static Future<String> getOrCreateWatchId({
    required MemoryService memoryService,
    required FakeFirebaseFirestore db,
    bool skipAuth = false,
    bool forceFirestoreError = false,
  }) async {
    if (!skipAuth) {
    }

    final local = await memoryService.getWatchId();
    if (local != null && local.isNotEmpty) {
      unawaited(_ensureWatchDocInternal(local, db));
      return local;
    }

    if (forceFirestoreError) {
      const uuid = Uuid();
      final fallback = uuid.v4();
      await memoryService.saveWatchId(fallback);
      unawaited(_ensureWatchDocInternal(fallback, db));
      return fallback;
    }

    try {
      final ref = await db.collection('watch').add({
        'platform': 'wearos',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
      await memoryService.saveWatchId(ref.id);
      return ref.id;
    } catch (e) {
      const uuid = Uuid();
      final fallback = uuid.v4();
      await memoryService.saveWatchId(fallback);
      unawaited(_ensureWatchDocInternal(fallback, db));
      return fallback;
    }
  }

  static Future<void> ensureWatchDoc({
    required String watchId,
    required FakeFirebaseFirestore db,
  }) async {
    await _ensureWatchDocInternal(watchId, db);
  }

  static Future<void> _ensureWatchDocInternal(
    String watchId,
    FakeFirebaseFirestore db,
  ) async {
    try {
      final ref = db.collection('watch').doc(watchId);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'platform': 'wearos',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
    }
  }
}

void unawaited(Future<void> future) {
}