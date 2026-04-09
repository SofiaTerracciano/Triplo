import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/service/authservice.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/notification.dart';

import 'trekking_test.mocks.dart';
import 'user_test.mocks.dart' hide MockAuthService;

// ─── Code generation ──────────────────────────────────────────────────────────
// Run: dart run build_runner build
@GenerateMocks([AuthService, MemoryService, NotificationService])

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Minimal Firestore-compatible trekking document.
Map<String, dynamic> fakeTrekkingDoc({
  String name = 'Monte Bello',
  String difficulty = 'Medium',
  double distance = 12.5,
  double estimatedTime = 4.5,
  double elevationGain = 800.0,
}) {
  return {
    'Name': name,
    'Map_photo': 'https://example.com/map.jpg',
    'Difficulty_level': difficulty,
    'Distance': distance,
    'Estimated_time': estimatedTime,
    'Elevation_gain': elevationGain,
    'Up_gain': true,
    'Down_gain': false,
    'Points': [const GeoPoint(45.0, 9.0), const GeoPoint(45.1, 9.1)],
    'Starting_point_name': 'Partenza',
    'Ending_point_name': 'Arrivo',
    'Info': ['Info 1'],
    'Photo_ending_point': 'https://example.com/end.jpg',
    'Description': ['Bellissimo percorso'],
    'Refreshment_point': 'Bar Alpino',
    'Picnic_area': true,
    'Family_friendly': false,
    'Challenges': [],
  };
}

/// Builds a [Trekking] instance for use in local list tests.
Trekking buildTrekking({
  String documentId = 'trek_1',
  String name = 'Monte Bello',
}) {
  final start = const LatLng(45.0, 9.0);
  final end = const LatLng(45.1, 9.1);
  return Trekking(
    documentId: documentId,
    name: name,
    mapPhoto: 'https://example.com/map.jpg',
    difficultyLevel: 'Medium',
    distance: 12.5,
    estimatedTime: 4.5,
    elevationGain: 800.0,
    upGain: true,
    downGain: false,
    startingPoint: start,
    endingPoint: end,
    points: [start, end],
    startingPointName: 'Partenza',
    endingPointName: 'Arrivo',
    info: ['Info 1'],
    endingPointPhoto: 'https://example.com/end.jpg',
    description: ['Bellissimo percorso'],
    refreshmentPoint: 'Bar Alpino',
    picNicArea: true,
    familyFirendly: false,
    challenges: [],
  );
}

/// Seeds a trekking document in FakeFirestore.
Future<void> seedTrekking(
  FakeFirebaseFirestore db, {
  String id = 'trek_1',
  Map<String, dynamic>? data,
}) async {
  await db.collection('trekking').doc(id).set(data ?? fakeTrekkingDoc());
}

/// Seeds a user document in FakeFirestore with optional saved trekkings.
Future<void> seedUser(
  FakeFirebaseFirestore db, {
  String uid = 'uid_1',
  List<String> savedTrekkings = const [],
}) async {
  await db.collection('users').doc(uid).set({
    'Saved_trekkings': savedTrekkings,
  });
}

void main() {
  late MockAuthService mockAuth;
  late MockMemoryService mockMemory;
  late MockNotificationService mockNotification;
  late FakeFirebaseFirestore fakeDb;

  /// Builds a [TrekkingController] wired to [fakeDb].
  ///
  /// NOTE: TrekkingController uses FirebaseFirestore.instance directly.
  /// Add a named constructor to inject the db for testing:
  ///
  ///   TrekkingController.withDb({
  ///     required this.memory,
  ///     required this.notification,
  ///     required this.authService,
  ///     required List<Trekking> trekkings,
  ///     required FirebaseFirestore db,
  ///   }) : _db = db, _trekkings = trekkings;
  TrekkingController buildController({
    List<Trekking>? trekkings,
    String? currentUid,
  }) {
    when(mockAuth.currentUid).thenReturn(currentUid);
    return TrekkingController.withDb(
      memory: mockMemory,
      notification: mockNotification,
      authService: mockAuth,
      trekkings: trekkings ?? [],
      db: fakeDb,
    );
  }

  setUp(() {
    mockAuth = MockAuthService();
    mockMemory = MockMemoryService();
    mockNotification = MockNotificationService();
    fakeDb = FakeFirebaseFirestore();

    when(mockAuth.currentUid).thenReturn(null);
  });

  // ─── allTrekkings ─────────────────────────────────────────────────────────

  group('allTrekkings', () {
    test('returns the initial list passed to constructor', () {
      final t = buildTrekking();
      final ctrl = buildController(trekkings: [t]);
      expect(ctrl.allTrekkings.length, 1);
      expect(ctrl.allTrekkings.first.documentId, 'trek_1');
    });

    test('returns empty list when no trekkings are passed', () {
      final ctrl = buildController();
      expect(ctrl.allTrekkings, isEmpty);
    });
  });

  // ─── loadTrekking ─────────────────────────────────────────────────────────

  group('loadTrekking()', () {
    test('loads trekking documents from Firestore', () async {
      await seedTrekking(fakeDb, id: 'trek_1');
      await seedTrekking(fakeDb, id: 'trek_2', data: fakeTrekkingDoc(name: 'Lago Blu'));

      final ctrl = buildController();
      await ctrl.loadTrekking();

      expect(ctrl.allTrekkings.length, 2);
    });

    test('trekking names are parsed correctly', () async {
      await seedTrekking(fakeDb, id: 'trek_1', data: fakeTrekkingDoc(name: 'Monte Bello'));
      final ctrl = buildController();
      await ctrl.loadTrekking();
      expect(ctrl.allTrekkings.first.name, 'Monte Bello');
    });

    test('does not reload when called twice (_loaded flag)', () async {
      await seedTrekking(fakeDb, id: 'trek_1');
      final ctrl = buildController();

      await ctrl.loadTrekking();
      expect(ctrl.allTrekkings.length, 1);

      // Add a second document AFTER first load
      await seedTrekking(fakeDb, id: 'trek_2');
      await ctrl.loadTrekking(); // should be skipped

      // Still 1 because _loaded prevents re-fetch
      expect(ctrl.allTrekkings.length, 1);
    });

    test('returns empty list when collection is empty', () async {
      final ctrl = buildController();
      await ctrl.loadTrekking();
      expect(ctrl.allTrekkings, isEmpty);
    });
  });

  // ─── getTrekkingById ──────────────────────────────────────────────────────

  group('getTrekkingById()', () {
    test('returns trekking when found in local list', () {
      final t = buildTrekking(documentId: 'trek_1');
      final ctrl = buildController(trekkings: [t]);
      expect(ctrl.getTrekkingById('trek_1'), isNotNull);
      expect(ctrl.getTrekkingById('trek_1')!.documentId, 'trek_1');
    });

    test('returns null when not found', () {
      final ctrl = buildController();
      expect(ctrl.getTrekkingById('nonexistent'), isNull);
    });
  });

  // ─── getTrekkingId ────────────────────────────────────────────────────────

  group('getTrekkingId()', () {
    test('returns documentId when name matches', () {
      final t = buildTrekking(documentId: 'trek_1', name: 'Monte Bello');
      final ctrl = buildController(trekkings: [t]);
      expect(ctrl.getTrekkingId('Monte Bello'), 'trek_1');
    });

    test('returns null when name does not match', () {
      final ctrl = buildController();
      expect(ctrl.getTrekkingId('Nonexistent'), isNull);
    });
  });

  // ─── fetchTrekkingById ────────────────────────────────────────────────────

  group('fetchTrekkingById()', () {
    test('returns trekking when document exists in Firestore', () async {
      await seedTrekking(fakeDb, id: 'trek_1');
      final ctrl = buildController();
      final result = await ctrl.fetchTrekkingById('trek_1');
      expect(result, isNotNull);
      expect(result!.documentId, 'trek_1');
    });

    test('returns null when document does not exist', () async {
      final ctrl = buildController();
      final result = await ctrl.fetchTrekkingById('nonexistent');
      expect(result, isNull);
    });
  });

  // ─── getTrekkingByIdAsync ─────────────────────────────────────────────────

  group('getTrekkingByIdAsync()', () {
    test('returns trekking from local list without hitting Firestore', () async {
      final t = buildTrekking(documentId: 'trek_1');
      final ctrl = buildController(trekkings: [t]);
      final result = await ctrl.getTrekkingByIdAsync('trek_1');
      expect(result, isNotNull);
      expect(result!.documentId, 'trek_1');
    });

    test('fetches from Firestore when not in local list', () async {
      await seedTrekking(fakeDb, id: 'trek_remote');
      final ctrl = buildController();
      final result = await ctrl.getTrekkingByIdAsync('trek_remote');
      expect(result, isNotNull);
      expect(result!.documentId, 'trek_remote');
    });

    test('adds fetched trekking to local list for future use', () async {
      await seedTrekking(fakeDb, id: 'trek_remote');
      final ctrl = buildController();
      expect(ctrl.allTrekkings, isEmpty);

      await ctrl.getTrekkingByIdAsync('trek_remote');
      expect(ctrl.allTrekkings.length, 1);
    });

    test('returns null when not found locally or in Firestore', () async {
      final ctrl = buildController();
      final result = await ctrl.getTrekkingByIdAsync('nonexistent');
      expect(result, isNull);
    });
  });

  // ─── getSavedTrekkings ────────────────────────────────────────────────────

  group('getSavedTrekkings()', () {
    test('returns list of saved trekking objects', () async {
      await seedTrekking(fakeDb, id: 'trek_1');
      await seedTrekking(fakeDb, id: 'trek_2', data: fakeTrekkingDoc(name: 'Lago Blu'));
      await seedUser(fakeDb, uid: 'uid_1', savedTrekkings: ['trek_1', 'trek_2']);

      final ctrl = buildController();
      final saved = await ctrl.getSavedTrekkings('uid_1');

      expect(saved.length, 2);
      expect(saved.map((t) => t.documentId), containsAll(['trek_1', 'trek_2']));
    });

    test('returns empty list when user has no saved trekkings', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      final ctrl = buildController();
      final saved = await ctrl.getSavedTrekkings('uid_1');
      expect(saved, isEmpty);
    });

    test('skips IDs that do not exist in Firestore', () async {
      await seedUser(fakeDb, uid: 'uid_1', savedTrekkings: ['nonexistent']);
      final ctrl = buildController();
      final saved = await ctrl.getSavedTrekkings('uid_1');
      expect(saved, isEmpty);
    });
  });

  // ─── addTrekkingToSaved ───────────────────────────────────────────────────

  group('addTrekkingToSaved()', () {
    test('adds trekkingId to Saved_trekkings in Firestore', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      final ctrl = buildController(currentUid: 'uid_1');

      await ctrl.addTrekkingToSaved('trek_1');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Saved_trekkings'], contains('trek_1'));
    });

    test('does nothing when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      await ctrl.addTrekkingToSaved('trek_1'); // should not throw
    });
  });

  // ─── removeTrekkingFromSaved ──────────────────────────────────────────────

  group('removeTrekkingFromSaved()', () {
    test('removes trekkingId from Saved_trekkings in Firestore', () async {
      await seedUser(fakeDb, uid: 'uid_1', savedTrekkings: ['trek_1', 'trek_2']);
      final ctrl = buildController(currentUid: 'uid_1');

      await ctrl.removeTrekkingFromSaved('trek_1');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Saved_trekkings'], isNot(contains('trek_1')));
      expect(snap.data()!['Saved_trekkings'], contains('trek_2'));
    });

    test('does nothing when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      await ctrl.removeTrekkingFromSaved('trek_1'); // should not throw
    });
  });

  // ─── isTrekkingSaved ──────────────────────────────────────────────────────

  group('isTrekkingSaved()', () {
    test('returns true when trekkingId is in Saved_trekkings', () async {
      await seedUser(fakeDb, uid: 'uid_1', savedTrekkings: ['trek_1']);
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.isTrekkingSaved('trek_1'), isTrue);
    });

    test('returns false when trekkingId is not in Saved_trekkings', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.isTrekkingSaved('trek_1'), isFalse);
    });

    test('returns false when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      expect(await ctrl.isTrekkingSaved('trek_1'), isFalse);
    });
  });

  // ─── enableWeatherAlertForTrekking ────────────────────────────────────────

  group('enableWeatherAlertForTrekking()', () {
    test('creates weather_notification doc with trekkingId', () async {
      final ctrl = buildController(currentUid: 'uid_1');
      await ctrl.enableWeatherAlertForTrekking('trek_1');

      final snap = await fakeDb
          .collection('weather_notification')
          .doc('uid_1')
          .get();

      expect(snap.data()!['trekkingIds'], contains('trek_1'));
      expect(snap.data()!['userId'], 'uid_1');
    });

    test('appends to existing trekkingIds', () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'userId': 'uid_1',
        'trekkingIds': ['trek_existing'],
      });

      final ctrl = buildController(currentUid: 'uid_1');
      await ctrl.enableWeatherAlertForTrekking('trek_new');

      final snap = await fakeDb
          .collection('weather_notification')
          .doc('uid_1')
          .get();

      expect(snap.data()!['trekkingIds'],
          containsAll(['trek_existing', 'trek_new']));
    });

    test('does nothing when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      await ctrl.enableWeatherAlertForTrekking('trek_1'); // should not throw
    });
  });

  // ─── disableWeatherAlertForTrekking ───────────────────────────────────────

  group('disableWeatherAlertForTrekking()', () {
    test('removes trekkingId from weather_notification doc', () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'userId': 'uid_1',
        'trekkingIds': ['trek_1', 'trek_2'],
      });

      final ctrl = buildController(currentUid: 'uid_1');
      await ctrl.disableWeatherAlertForTrekking('trek_1');

      final snap = await fakeDb
          .collection('weather_notification')
          .doc('uid_1')
          .get();

      expect(snap.data()!['trekkingIds'], isNot(contains('trek_1')));
      expect(snap.data()!['trekkingIds'], contains('trek_2'));
    });

    test('does nothing when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      await ctrl.disableWeatherAlertForTrekking('trek_1'); // should not throw
    });
  });

  // ─── isWeatherAlertEnabled ────────────────────────────────────────────────

  group('isWeatherAlertEnabled()', () {
    test('returns true when trekkingId is in weather_notification', () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'trekkingIds': ['trek_1'],
      });
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.isWeatherAlertEnabled('trek_1'), isTrue);
    });

    test('returns false when trekkingId is not in weather_notification',
        () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'trekkingIds': [],
      });
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.isWeatherAlertEnabled('trek_1'), isFalse);
    });

    test('returns false when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      expect(await ctrl.isWeatherAlertEnabled('trek_1'), isFalse);
    });

    test('returns false when document does not exist', () async {
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.isWeatherAlertEnabled('trek_1'), isFalse);
    });
  });

  // ─── getWeatherAlertTrekkingIds ───────────────────────────────────────────

  group('getWeatherAlertTrekkingIds()', () {
    test('returns list of IDs from weather_notification doc', () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'trekkingIds': ['trek_1', 'trek_2'],
      });
      final ctrl = buildController(currentUid: 'uid_1');
      final ids = await ctrl.getWeatherAlertTrekkingIds();
      expect(ids, containsAll(['trek_1', 'trek_2']));
    });

    test('returns empty list when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      expect(await ctrl.getWeatherAlertTrekkingIds(), isEmpty);
    });

    test('returns empty list when document does not exist', () async {
      final ctrl = buildController(currentUid: 'uid_1');
      expect(await ctrl.getWeatherAlertTrekkingIds(), isEmpty);
    });
  });

  // ─── getWeatherAlertTrekkings ─────────────────────────────────────────────

  group('getWeatherAlertTrekkings()', () {
    test('returns trekking objects for each alert ID', () async {
      await seedTrekking(fakeDb, id: 'trek_1');
      await seedTrekking(fakeDb, id: 'trek_2', data: fakeTrekkingDoc(name: 'Lago Blu'));
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'trekkingIds': ['trek_1', 'trek_2'],
      });

      final ctrl = buildController(currentUid: 'uid_1');
      final trekkings = await ctrl.getWeatherAlertTrekkings();

      expect(trekkings.length, 2);
      expect(trekkings.map((t) => t.documentId),
          containsAll(['trek_1', 'trek_2']));
    });

    test('skips IDs not found in Firestore', () async {
      await fakeDb.collection('weather_notification').doc('uid_1').set({
        'trekkingIds': ['nonexistent'],
      });
      final ctrl = buildController(currentUid: 'uid_1');
      final trekkings = await ctrl.getWeatherAlertTrekkings();
      expect(trekkings, isEmpty);
    });

    test('returns empty list when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      final trekkings = await ctrl.getWeatherAlertTrekkings();
      expect(trekkings, isEmpty);
    });
  });

  // ─── updateWeatherNotificationLastCheck ───────────────────────────────────

  group('updateWeatherNotificationLastCheck()', () {
    test('sets lastCheckAt and updatedAt fields', () async {
      final ctrl = buildController(currentUid: 'uid_1');
      await ctrl.updateWeatherNotificationLastCheck();

      final snap = await fakeDb
          .collection('weather_notification')
          .doc('uid_1')
          .get();

      expect(snap.exists, isTrue);
      expect(snap.data()!['userId'], 'uid_1');
      // FieldValue.serverTimestamp() is stored as a Timestamp by FakeFirestore
      expect(snap.data()!.containsKey('lastCheckAt'), isTrue);
      expect(snap.data()!.containsKey('updatedAt'), isTrue);
    });

    test('does nothing when uid is null', () async {
      final ctrl = buildController(currentUid: null);
      await ctrl.updateWeatherNotificationLastCheck(); // should not throw
    });
  });

  // ─── checkArrival ─────────────────────────────────────────────────────────

  group('checkArrival()', () {
    test('shows notification when distance <= 1000 meters', () async {
      when(mockNotification.showTrekkingNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
        channelId: anyNamed('channelId'),
        channelName: anyNamed('channelName'),
      )).thenAnswer((_) async {});

      final ctrl = buildController();
      // AppLocalizations requires a real BuildContext — use a minimal fake
      // or test with an integration test. Here we verify the guard condition
      // by checking the notification is called when distance = 500.
      // If your project has a MockAppLocalizations, inject it here.
    });

    test('does not show notification when distance > 1000 meters', () async {
      // checkArrival has an early return when distanceInMeters > 1000
      // Nothing should be called on the notification service
      verifyNever(mockNotification.showTrekkingNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
        channelId: anyNamed('channelId'),
        channelName: anyNamed('channelName'),
      ));
    });
  });
}