import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'trekking_test.mocks.dart';

@GenerateMocks([
  GeoService,
  MemoryService,
  NotificationService,
  PairingService,
  AppLocalizations,
])

void main() {
  const testDocId = 'trek-1';
  const testPoint = LatLng(45.0, 9.0);
  const testEndPoint = LatLng(46.0, 10.0);

  Trekking makeTrekking({String id = testDocId, String name = 'Monte Rosa'}) =>
      Trekking(
        documentId: id,
        name: name,
        mapPhoto: 'gs://bucket/map.jpg',
        difficultyLevel: 'medium',
        distance: 12.5,
        estimatedTime: 4.0,
        elevationGain: 800.0,
        upGain: true,
        downGain: false,
        startingPoint: testPoint,
        endingPoint: testEndPoint,
        points: [testPoint, testEndPoint],
        startingPointName: 'Partenza',
        endingPointName: 'Arrivo',
        info: ['info1', 'info2'],
        endingPointPhoto: 'gs://bucket/end.jpg',
        description: ['Prima parte', 'Seconda parte'],
        refreshmentPoint: 'Rifugio Alpino',
        picNicArea: true,
        familyFirendly: false,
        challenges: ['ripido', 'esposto'],
      );

  Map<String, dynamic> makeTrekkingMap() => {
        'Name': 'Monte Rosa',
        'Map_photo': 'gs://bucket/map.jpg',
        'Difficulty_level': 'medium',
        'Distance': 12.5,
        'Estimated_time': 4.0,
        'Elevation_gain': 800.0,
        'Up_gain': true,
        'Down_gain': false,
        'Points': [
          const GeoPoint(45.0, 9.0),
          const GeoPoint(46.0, 10.0),
        ],
        'Starting_point_name': 'Partenza',
        'Ending_point_name': 'Arrivo',
        'Info': ['info1', 'info2'],
        'Photo_ending_point': 'gs://bucket/end.jpg',
        'Description': ['Prima parte', 'Seconda parte'],
        'Refreshment_point': 'Rifugio Alpino',
        'Picnic_area': true,
        'Family_friendly': false,
        'Challenges': ['ripido', 'esposto'],
      };

  MockPairingService pairingWithUid(String? uid) {
    final p = MockPairingService();
    when(p.effectiveUid).thenReturn(uid);
    return p;
  }

  TrekkingController makeController({
    required MockPairingService pairingService,
    FakeFirebaseFirestore? db,
    MockNotificationService? notificationService,
    List<Trekking> trekkings = const [],
  }) =>
      TrekkingController(
        db: db ?? FakeFirebaseFirestore(),
        trekkings: trekkings,
        geo: MockGeoService(),
        memory: MockMemoryService(),
        notification: notificationService ?? MockNotificationService(),
        pairingService: pairingService,
      );

  group('Trekking model', () {
    group('constructor & getters', () {
      test('stores all required fields correctly', () {
        final t = makeTrekking();

        expect(t.documentId, testDocId);
        expect(t.name, 'Monte Rosa');
        expect(t.mapPhoto, 'gs://bucket/map.jpg');
        expect(t.difficulty_level, 'medium');
        expect(t.distance, 12.5);
        expect(t.estimated_time, 4.0);
        expect(t.elevation_gain, 800.0);
        expect(t.upGain, isTrue);
        expect(t.downGain, isFalse);
        expect(t.starting_point, testPoint);
        expect(t.ending_point, testEndPoint);
        expect(t.points, [testPoint, testEndPoint]);
        expect(t.starting_point_name, 'Partenza');
        expect(t.ending_point_name, 'Arrivo');
        expect(t.info, ['info1', 'info2']);
        expect(t.endingPointPhoto, 'gs://bucket/end.jpg');
        expect(t.description, ['Prima parte', 'Seconda parte']);
        expect(t.refreshment_point, 'Rifugio Alpino');
        expect(t.pic_nic_area, isTrue);
        expect(t.family_firendly, isFalse);
        expect(t.challenges, ['ripido', 'esposto']);
      });

      test('refreshmentPoint defaults to empty string when omitted', () {
        final t = Trekking(
          documentId: 'x',
          name: 'Test',
          mapPhoto: '',
          difficultyLevel: 'easy',
          distance: 1.0,
          estimatedTime: 1.0,
          elevationGain: 0.0,
          upGain: false,
          downGain: false,
          startingPoint: testPoint,
          endingPoint: testEndPoint,
          points: [testPoint],
          startingPointName: '',
          endingPointName: '',
          info: [],
          endingPointPhoto: '',
          description: [],
          picNicArea: false,
          familyFirendly: false,
        );
        expect(t.refreshment_point, '');
      });

      test('challenges defaults to empty list when omitted', () {
        final t = Trekking(
          documentId: 'x',
          name: 'Test',
          mapPhoto: '',
          difficultyLevel: 'easy',
          distance: 1.0,
          estimatedTime: 1.0,
          elevationGain: 0.0,
          upGain: false,
          downGain: false,
          startingPoint: testPoint,
          endingPoint: testEndPoint,
          points: [testPoint],
          startingPointName: '',
          endingPointName: '',
          info: [],
          endingPointPhoto: '',
          description: [],
          picNicArea: false,
          familyFirendly: false,
        );
        expect(t.challenges, isEmpty);
      });
    });

    group('setters', () {
      test('name setter updates value', () {
        final t = makeTrekking();
        t.name = 'Gran Paradiso';
        expect(t.name, 'Gran Paradiso');
      });

      test('distance setter updates value', () {
        final t = makeTrekking();
        t.distance = 20.0;
        expect(t.distance, 20.0);
      });

      test('upGain / downGain setters toggle correctly', () {
        final t = makeTrekking();
        t.upGain = false;
        t.downGain = true;
        expect(t.upGain, isFalse);
        expect(t.downGain, isTrue);
      });

      test('points setter replaces the list', () {
        final t = makeTrekking();
        final newPoints = [const LatLng(1.0, 2.0)];
        t.points = newPoints;
        expect(t.points, newPoints);
      });

      test('challenges setter replaces the list', () {
        final t = makeTrekking();
        t.challenges = ['nuovo'];
        expect(t.challenges, ['nuovo']);
      });

      test('pic_nic_area setter updates value', () {
        final t = makeTrekking();
        t.pic_nic_area = false;
        expect(t.pic_nic_area, isFalse);
      });

      test('difficulty_level setter updates value', () {
        final t = makeTrekking();
        t.difficulty_level = 'hard';
        expect(t.difficulty_level, 'hard');
      });
    });

    group('fromMap', () {
      test('parses a complete Firestore map correctly', () {
        final t = Trekking.fromMap(makeTrekkingMap(), docId: testDocId);

        expect(t.documentId, testDocId);
        expect(t.name, 'Monte Rosa');
        expect(t.difficulty_level, 'medium');
        expect(t.distance, 12.5);
        expect(t.estimated_time, 4.0);
        expect(t.elevation_gain, 800.0);
        expect(t.upGain, isTrue);
        expect(t.downGain, isFalse);
        expect(t.points, hasLength(2));
        expect(t.starting_point.latitude, 45.0);
        expect(t.starting_point.longitude, 9.0);
        expect(t.ending_point.latitude, 46.0);
        expect(t.info, ['info1', 'info2']);
        expect(t.challenges, ['ripido', 'esposto']);
        expect(t.pic_nic_area, isTrue);
        expect(t.family_firendly, isFalse);
        expect(t.refreshment_point, 'Rifugio Alpino');
      });

      test('handles completely empty map with safe defaults', () {
        final t = Trekking.fromMap({}, docId: 'empty');

        expect(t.name, '');
        expect(t.distance, 0.0);
        expect(t.estimated_time, 0.0);
        expect(t.elevation_gain, 0.0);
        expect(t.upGain, isFalse);
        expect(t.downGain, isFalse);
        expect(t.points, isEmpty);
        expect(t.starting_point, const LatLng(0, 0));
        expect(t.ending_point, const LatLng(0, 0));
        expect(t.info, isEmpty);
        expect(t.description, isEmpty);
        expect(t.challenges, isEmpty);
        expect(t.refreshment_point, '');
        expect(t.pic_nic_area, isFalse);
        expect(t.family_firendly, isFalse);
      });

      test('_safeDouble handles int stored values', () {
        final map = makeTrekkingMap()..['Distance'] = 10; // stored as int
        expect(Trekking.fromMap(map, docId: 'x').distance, 10.0);
      });

      test('_safeDouble handles String stored values', () {
        final map = makeTrekkingMap()..['Distance'] = '15.5';
        expect(Trekking.fromMap(map, docId: 'x').distance, 15.5);
      });

      test('_safeDouble returns 0 for unparseable String', () {
        final map = makeTrekkingMap()..['Distance'] = 'invalid';
        expect(Trekking.fromMap(map, docId: 'x').distance, 0.0);
      });

      test('startingPoint is first GeoPoint, endingPoint is last', () {
        final map = makeTrekkingMap()
          ..['Points'] = [
            const GeoPoint(10.0, 20.0),
            const GeoPoint(30.0, 40.0),
            const GeoPoint(50.0, 60.0),
          ];
        final t = Trekking.fromMap(map, docId: 'x');

        expect(t.starting_point, const LatLng(10.0, 20.0));
        expect(t.ending_point, const LatLng(50.0, 60.0));
        expect(t.points, hasLength(3));
      });

      test('single-point route has same starting and ending point', () {
        final map = makeTrekkingMap()
          ..['Points'] = [const GeoPoint(45.0, 9.0)];
        final t = Trekking.fromMap(map, docId: 'x');

        expect(t.starting_point, t.ending_point);
      });
    });

    group('toMap', () {
      test('serializes all fields to the expected Firestore keys', () {
        final map = makeTrekking().toMap();

        expect(map['Name'], 'Monte Rosa');
        expect(map['Map_photo'], 'gs://bucket/map.jpg');
        expect(map['Difficulty_level'], 'medium');
        expect(map['Distance'], 12.5);
        expect(map['Estimated_time'], 4.0);
        expect(map['Elevation_gain'], 800.0);
        expect(map['Up_gain'], isTrue);
        expect(map['Down_gain'], isFalse);
        expect(map['Starting_point_name'], 'Partenza');
        expect(map['Ending_point_name'], 'Arrivo');
        expect(map['Info'], ['info1', 'info2']);
        expect(map['Photo_ending_point'], 'gs://bucket/end.jpg');
        expect(map['Description'], ['Prima parte', 'Seconda parte']);
        expect(map['Refreshment_point'], 'Rifugio Alpino');
        expect(map['Picnic_area'], isTrue);
        expect(map['Family_friendly'], isFalse);
        expect(map['Challenges'], ['ripido', 'esposto']);

        final pts = map['Points'] as List;
        expect(pts, hasLength(2));
        expect((pts.first as GeoPoint).latitude, 45.0);
        expect((pts.last as GeoPoint).latitude, 46.0);
      });

      test('toMap → fromMap round-trip preserves all values', () {
        final original = makeTrekking();
        final restored =
            Trekking.fromMap(original.toMap(), docId: original.documentId);

        expect(restored.documentId, original.documentId);
        expect(restored.name, original.name);
        expect(restored.difficulty_level, original.difficulty_level);
        expect(restored.distance, original.distance);
        expect(restored.estimated_time, original.estimated_time);
        expect(restored.elevation_gain, original.elevation_gain);
        expect(restored.upGain, original.upGain);
        expect(restored.downGain, original.downGain);
        expect(restored.info, original.info);
        expect(restored.description, original.description);
        expect(restored.challenges, original.challenges);
        expect(restored.pic_nic_area, original.pic_nic_area);
        expect(restored.family_firendly, original.family_firendly);
        expect(restored.refreshment_point, original.refreshment_point);
        expect(restored.starting_point.latitude,
            original.starting_point.latitude);
        expect(
            restored.ending_point.latitude, original.ending_point.latitude);
      });
    });
  });

  group('TrekkingController', () {
    group('uid', () {
      test('returns null when pairingService has no uid', () {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(c.uid, isNull);
      });

      test('returns uid from pairingService', () {
        final c = makeController(pairingService: pairingWithUid('user-abc'));
        expect(c.uid, 'user-abc');
      });
    });

    group('allTrekkings', () {
      test('returns the initial list passed to the constructor', () {
        final trek = makeTrekking();
        final c = makeController(
          pairingService: pairingWithUid(null),
          trekkings: [trek],
        );
        expect(c.allTrekkings, [trek]);
      });
    });

    group('loadTrekking', () {
      test('populates trekkings from Firestore and notifies listeners', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('trekking').doc(testDocId).set(makeTrekkingMap());

        final c = makeController(pairingService: pairingWithUid(null), db: fakeDb); // ← pass db
        int notifyCount = 0;
        c.addListener(() => notifyCount++);

        await c.loadTrekking();

        expect(c.allTrekkings, hasLength(1));
        expect(c.allTrekkings.first.documentId, testDocId);
        expect(c.allTrekkings.first.name, 'Monte Rosa');
        expect(notifyCount, 1);
      });

      test('is idempotent — does NOT reload on second call', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('trekking').doc(testDocId).set(makeTrekkingMap());

        final c = makeController(pairingService: pairingWithUid(null), db: fakeDb); // ← pass db
        await c.loadTrekking();

        await fakeDb.collection('trekking').doc('trek-2').set(makeTrekkingMap());
        await c.loadTrekking();

        expect(c.allTrekkings, hasLength(1));
      });
    });

    group('getTrekkingById', () {
      test('returns correct Trekking for known id', () {
        final trek = makeTrekking(id: 'trek-42');
        final c = makeController(
          pairingService: pairingWithUid(null),
          trekkings: [trek],
        );
        expect(c.getTrekkingById('trek-42'), trek);
      });

      test('returns null for unknown id', () {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(c.getTrekkingById('not-there'), isNull);
      });
    });

    group('getTrekkingByIdAsync', () {
      test('returns from local cache when available', () async {
        final trek = makeTrekking();
        final c = makeController(
          pairingService: pairingWithUid(null),
          trekkings: [trek],
        );
        expect(await c.getTrekkingByIdAsync(testDocId), trek);
      });

      test('fetches from Firestore when not in local cache', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('trekking').doc('trek-remote').set(makeTrekkingMap());

        final c = makeController(pairingService: pairingWithUid(null), db: fakeDb); // ← pass db
        final result = await c.getTrekkingByIdAsync('trek-remote');

        expect(result, isNotNull);
        expect(result!.documentId, 'trek-remote');
        expect(result.name, 'Monte Rosa');
      });

      test('returns null when id absent from both cache and Firestore',
          () async {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(await c.getTrekkingByIdAsync('ghost-id'), isNull);
      });
    });
    group('getTrekkingId', () {
      test('returns documentId for a known name', () {
        final trek = makeTrekking(id: 'trek-99', name: 'Dolomiti');
        final c = makeController(
          pairingService: pairingWithUid(null),
          trekkings: [trek],
        );
        expect(c.getTrekkingId('Dolomiti'), 'trek-99');
      });

      test('returns null for an unknown name', () {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(c.getTrekkingId('Fantasyland'), isNull);
      });
    });
    group('checkArrival', () {
      MockAppLocalizations mockLocal() {
        final l = MockAppLocalizations();
        when(l.title_notification_arrival).thenReturn('📍 Almost there!');
        when(l.body_notification_arrival).thenReturn('Tap to complete the trek.');
        when(l.alert_notification_arrival).thenReturn(
          'You are close to the arrival point; remember to stop the timer and complete your diary.',
        );
        return l;
      }

      MockNotificationService stubNotif() {
        final n = MockNotificationService();
        when(n.showTrekkingNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: anyNamed('payload'),
          channelId: anyNamed('channelId'),
          channelName: anyNamed('channelName'),
        )).thenAnswer((_) async {});
        return n;
      }

      test('shows notification when distance == 1000 m (boundary)', () async {
        final notif = stubNotif();
        final c = makeController(
          pairingService: pairingWithUid(null),
          notificationService: notif,
        );
        await c.checkArrival(testDocId, 1000, mockLocal());
        verify(notif.showTrekkingNotification(
          id: 999,
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: 'end_trekking_arrival',
          channelId: 'arrival_channel',
          channelName: 'Notifications',
        )).called(1);
      });

      test('shows notification when distance < 1000 m', () async {
        final notif = stubNotif();
        final c = makeController(
          pairingService: pairingWithUid(null),
          notificationService: notif,
        );
        await c.checkArrival(testDocId, 500, mockLocal());
        verify(notif.showTrekkingNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: anyNamed('payload'),
          channelId: anyNamed('channelId'),
          channelName: anyNamed('channelName'),
        )).called(1);
      });

      test('does NOT show notification when distance > 1000 m', () async {
        final notif = MockNotificationService();
        final c = makeController(
          pairingService: pairingWithUid(null),
          notificationService: notif,
        );
        await c.checkArrival(testDocId, 1001, mockLocal());
        verifyNever(notif.showTrekkingNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: anyNamed('payload'),
          channelId: anyNamed('channelId'),
          channelName: anyNamed('channelName'),
        ));
      });
    });
    group('weather alert', () {
      const uid = 'user-123';

      test('isWeatherAlertEnabled → false when uid is null', () async {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(await c.isWeatherAlertEnabled(testDocId), isFalse);
      });

      test('isWeatherAlertEnabled → false when trekkingId not in list',
          () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('weather_notification').doc(uid).set({
          'userId': uid,
          'trekkingIds': ['other-trek'],
        });
        final c = makeController(pairingService: pairingWithUid(uid));
        expect(await c.isWeatherAlertEnabled(testDocId), isFalse);
      });

      test('enableWeatherAlertForTrekking writes trekkingId to Firestore', () async {
        final fakeDb = FakeFirebaseFirestore();
        final c = makeController(pairingService: pairingWithUid(uid), db: fakeDb); // ← pass db

        await c.enableWeatherAlertForTrekking(testDocId);

        final ids = List<String>.from(
          (await fakeDb.collection('weather_notification').doc(uid).get())
                  .data()?['trekkingIds'] ?? [],
        );
        expect(ids, contains(testDocId));
      });

      test('disableWeatherAlertForTrekking removes only the target trekkingId', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('weather_notification').doc(uid).set({
          'userId': uid,
          'trekkingIds': [testDocId, 'other-trek'],
        });
        final c = makeController(pairingService: pairingWithUid(uid), db: fakeDb); // ← pass db
        await c.disableWeatherAlertForTrekking(testDocId);

        final ids = List<String>.from(
          (await fakeDb.collection('weather_notification').doc(uid).get())
                  .data()?['trekkingIds'] ?? [],
        );
        expect(ids, isNot(contains(testDocId)));
        expect(ids, contains('other-trek'));
      });

      test('getWeatherAlertTrekkingIds → returns stored ids', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('weather_notification').doc(uid).set({
          'userId': uid,
          'trekkingIds': [testDocId, 'trek-2'],
        });
        final c = makeController(pairingService: pairingWithUid(uid), db: fakeDb); // ← pass db
        final ids = await c.getWeatherAlertTrekkingIds();
        expect(ids, containsAll([testDocId, 'trek-2']));
      });

      test('getWeatherAlertTrekkings resolves ids to Trekking objects', () async {
        final fakeDb = FakeFirebaseFirestore();
        await fakeDb.collection('trekking').doc(testDocId).set(makeTrekkingMap());
        await fakeDb.collection('weather_notification').doc(uid).set({
          'userId': uid,
          'trekkingIds': [testDocId],
        });

        final c = makeController(pairingService: pairingWithUid(uid), db: fakeDb); // ← pass db
        final trekkings = await c.getWeatherAlertTrekkings();

        expect(trekkings, hasLength(1));
        expect(trekkings.first.documentId, testDocId);
        expect(trekkings.first.name, 'Monte Rosa');
      });

      test('isWeatherAlertEnabled → true after enabling', () async {
        final c = makeController(pairingService: pairingWithUid(uid));
        await c.enableWeatherAlertForTrekking(testDocId);
        expect(await c.isWeatherAlertEnabled(testDocId), isTrue);
      });

      test('isWeatherAlertEnabled → false after disabling', () async {
        final c = makeController(pairingService: pairingWithUid(uid));
        await c.enableWeatherAlertForTrekking(testDocId);
        await c.disableWeatherAlertForTrekking(testDocId);
        expect(await c.isWeatherAlertEnabled(testDocId), isFalse);
      });

      test('getWeatherAlertTrekkingIds → empty when uid is null', () async {
        final c = makeController(pairingService: pairingWithUid(null));
        expect(await c.getWeatherAlertTrekkingIds(), isEmpty);
      });

      test('enableWeatherAlertForTrekking is no-op when uid is null',
          () async {
        final fakeDb = FakeFirebaseFirestore();
        final c = makeController(pairingService: pairingWithUid(null));
        await expectLater(
            c.enableWeatherAlertForTrekking(testDocId), completes);
        expect(
            (await fakeDb.collection('weather_notification').get()).docs,
            isEmpty);
      });

      test('disableWeatherAlertForTrekking is no-op when uid is null',
          () async {
        final c = makeController(pairingService: pairingWithUid(null));
        await expectLater(
            c.disableWeatherAlertForTrekking(testDocId), completes);
      });
    });
  });
}