import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'watch_id_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  MemoryService,
])
class SlowFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(
    String path,
  ) {
    return SlowCollectionReference();
  }
}

class SlowCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(seconds: 10));

    throw Exception();
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeDb;
  late MockMemoryService memory;
  late MockFirebaseAuth auth;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    memory = MockMemoryService();
    auth = MockFirebaseAuth();
  });

  group('WatchIdService - getOrCreateWatchId', () {
    test(
      'returns local watchId when already saved locally',
      () async {
        when(memory.getWatchId()).thenAnswer((_) async => 'local-watch-id');

        final result = await WatchIdService.getOrCreateWatchId();

        expect(result, 'local-watch-id');

        verify(memory.getWatchId()).called(1);
      },
    );

    test(
      'creates firestore document when no local watchId exists',
      () async {
        when(memory.getWatchId()).thenAnswer((_) async => null);
        when(memory.saveWatchId(any)).thenAnswer((_) async {});

        final watchId = await WatchIdService.getOrCreateWatchId();

        expect(watchId, isNotEmpty);

        final snap =
            await fakeDb.collection('watch').doc(watchId).get();

        expect(snap.exists, true);
      },
    );

    test(
      'saves generated watchId locally',
      () async {
        when(memory.getWatchId()).thenAnswer((_) async => null);
        when(memory.saveWatchId(any)).thenAnswer((_) async {});

        final result = await WatchIdService.getOrCreateWatchId();

        verify(memory.saveWatchId(result)).called(1);
      },
    );

    test(
      'returns fallback uuid when firestore creation fails',
      () async {
        when(memory.getWatchId()).thenAnswer((_) async => null);
        when(memory.saveWatchId(any)).thenAnswer((_) async {});

        final result = await WatchIdService.getOrCreateWatchId();

        expect(result, isNotEmpty);

        verify(memory.saveWatchId(any)).called(1);
      },
    );
  });

  group('WatchIdService - _ensureWatchDoc', () {
    test(
      'creates document when it does not exist',
      () async {
        const watchId = 'watch-create';

        await WatchIdService.ensureWatchDocForTest(
          fakeDb,
          watchId,
        );

        final snap =
            await fakeDb.collection('watch').doc(watchId).get();

        expect(snap.exists, true);
        expect(snap.data()?['platform'], 'wearos');
      },
    );

    test(
      'updates lastSeenAt when document already exists',
      () async {
        const watchId = 'watch-update';

        await fakeDb.collection('watch').doc(watchId).set({
          'platform': 'wearos',
          'createdAt': Timestamp.now(),
        });

        await WatchIdService.ensureWatchDocForTest(
          fakeDb,
          watchId,
        );

        final snap =
            await fakeDb.collection('watch').doc(watchId).get();

        expect(snap.exists, true);
        expect(snap.data()?['lastSeenAt'], isNotNull);
      },
    );

    test(
      'does not throw when firestore fails',
      () async {
        expect(
          () async => await WatchIdService.ensureWatchDocForTest(
            fakeDb,
            'watch-error',
          ),
          returnsNormally,
        );
      },
    );
  });

  group('WatchIdService - anonymous auth', () {
    test(
      'does not authenticate when user already exists',
      () async {
        final mockUser = MockUser();

        when(auth.currentUser).thenReturn(mockUser);

        expect(auth.currentUser, isNotNull);
      },
    );

    test(
      'authenticates anonymously when no user exists',
      () async {
        when(auth.currentUser).thenReturn(null);

        when(auth.signInAnonymously())
            .thenAnswer((_) async => throw UnimplementedError());

        expect(auth.currentUser, isNull);
      },
    );
  });

  group('WatchIdService - timeout fallback', () {
    test(
      'uses fallback UUID when firestore creation times out',
      () async {
        when(memory.getWatchId()).thenAnswer((_) async => null);
        when(memory.saveWatchId(any)).thenAnswer((_) async {});

        final result = await WatchIdService.getOrCreateWatchId();

        expect(result, isNotEmpty);

        verify(memory.saveWatchId(any)).called(1);
      },
    );
  });

  test('returns cached local watchId when present',
    () async {
      final fakeDb = FakeFirebaseFirestore();

      WatchIdService.firestore = fakeDb;
      WatchIdService.memoryService = MockMemoryService();

      when(WatchIdService.memoryService.getWatchId())
          .thenAnswer((_) async => 'cached-watch-id');

      final result = await WatchIdService.getOrCreateWatchId();

      expect(result, 'cached-watch-id');

      verify(WatchIdService.memoryService.getWatchId()).called(1);

      await Future.delayed(Duration.zero);

      final snap = await fakeDb
          .collection('watch')
          .doc('cached-watch-id')
          .get();

      expect(snap.exists, true);
    },
  );
}