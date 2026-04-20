import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/model/challenges.dart';
import 'package:triplo/service/notification.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'challenge_test.mocks.dart';

@GenerateMocks([
  NotificationService,
  MemoryService,
  FirebaseStorage,
  Reference,
  AppLocalizations
])

void main() {
  late MockNotificationService mockNotification;
  late MockMemoryService mockMemory;
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late MockAppLocalizations mockLocal;

  setUp(() {
    mockNotification = MockNotificationService();
    mockMemory = MockMemoryService();
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    mockLocal = MockAppLocalizations();
  });

  ChallengesController buildController({
    FakeFirebaseFirestore? db,
  }) {
    return ChallengesController.test(
      notification: mockNotification,
      memory: mockMemory,
      db: db ?? FakeFirebaseFirestore(),
      storage: mockStorage,
    );
  }

  test('loadChallenges loads data from Firestore', () async {
    final db = FakeFirebaseFirestore();

    await db.collection('challenges').doc('ch1').set({
      'Title': ['A'],
      'Description': ['B'],
      'Photo': 'p.png',
    });

    final ctrl = buildController(db: db);

    await ctrl.loadChallenges();

    expect(ctrl.allChallenges.length, 1);
    expect(ctrl.allChallenges.first.documentId, 'ch1');
  });

  test('loadChallenges does not reload twice', () async {
    final db = FakeFirebaseFirestore();

    await db.collection('challenges').doc('ch1').set({
      'Title': ['A'],
    });

    final ctrl = buildController(db: db);

    await ctrl.loadChallenges();
    await db.collection('challenges').doc('ch2').set({'Title': ['B']});

    await ctrl.loadChallenges();

    expect(ctrl.allChallenges.length, 1);
  });

  test('getChallengesById returns correct item', () async {
    final db = FakeFirebaseFirestore();

    await db.collection('challenges').doc('x').set({
      'Title': ['X'],
    });

    final ctrl = buildController(db: db);
    await ctrl.loadChallenges();

    final result = ctrl.getChallengesById('x');

    expect(result, isNotNull);
    expect(result!.documentId, 'x');
  });

  test('getChallengesById returns null if not found', () {
    final ctrl = buildController();
    expect(ctrl.getChallengesById('nope'), isNull);
  });

  test('getCachedImage returns from RAM', () async {
    final file = File('ram.png');

    when(mockMemory.getImageFromMemory(any))
        .thenAnswer((_) async => file);

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('url');

    expect(result, file);
    verifyNever(mockMemory.getImageFromDisk(any));
  });

  test('getCachedImage returns from disk and saves to RAM', () async {
    final file = File('disk.png');

    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
    when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => file);

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('url');

    expect(result, file);
    verify(mockMemory.saveImageToMemory('url', file)).called(1);
  });

  test('getCachedImage downloads when not cached', () async {
    final file = File('downloaded.png');

    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
    when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => null);
    when(mockMemory.cacheImageOnDisk(any))
        .thenAnswer((_) async => file);

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('url');

    expect(result, file);
    verify(mockMemory.cacheImageOnDisk('url')).called(1);
  });

  test('getCachedImage handles gs:// path', () async {
    final file = File('gs.png');

    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);

    when(mockStorage.refFromURL(any)).thenReturn(mockRef);
    when(mockRef.getDownloadURL())
        .thenAnswer((_) async => 'https://converted.url');

    when(mockMemory.getImageFromDisk('https://converted.url'))
        .thenAnswer((_) async => file);

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('gs://bucket/file.png');

    expect(result, file);
  });

  test('getCachedImage returns null on error', () async {
    when(mockMemory.getImageFromMemory(any))
        .thenThrow(Exception());

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('url');

    expect(result, isNull);
  });

  test('notifyNewChallenge calls notification service', () {
    when(mockNotification.showTrekkingNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async {});

    final ctrl = buildController();

    ctrl.notifyNewChallenge('type', mockLocal);

    verify(mockNotification.showTrekkingNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      payload: 'type',
    )).called(1);
  });

  test('loadChallenges calls notifyListeners', () async {
    final db = FakeFirebaseFirestore();

    await db.collection('challenges').doc('x').set({
      'Title': ['A'],
    });

    final ctrl = buildController(db: db);

    bool called = false;
    ctrl.addListener(() {
      called = true;
    });

    await ctrl.loadChallenges();

    expect(called, true);
  });

  test('getCachedImage returns null if download fails', () async {
    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);

    when(mockStorage.refFromURL(any)).thenReturn(mockRef);
    when(mockRef.getDownloadURL()).thenThrow(Exception());

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('gs://fail.png');

    expect(result, isNull);
  });

  test('getCachedImage handles cacheImageOnDisk exception', () async {
    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
    when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => null);
    when(mockMemory.cacheImageOnDisk(any)).thenThrow(Exception());

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('url');

    expect(result, isNull);
  });

  test('getDownloadUrl returns correct url', () async {
    when(mockStorage.refFromURL(any)).thenReturn(mockRef);
    when(mockRef.getDownloadURL())
        .thenAnswer((_) async => 'https://url.com');

    final ctrl = buildController();

    final result = await ctrl.getDownloadUrl('gs://file');

    expect(result, 'https://url.com');
  });

  test('onTrekkingSelected can be triggered', () {
    final ctrl = buildController();

    Challenges? received;

    ctrl.onTrekkingSelected = (c) {
      received = c;
    };

    final ch = Challenges(
      documentId: '1',
      title: ['A'],
      description: [],
      photo: '',
    );

    ctrl.onTrekkingSelected!(ch);

    expect(received, ch);
  });

  test('getCachedImage returns RAM even if gs://', () async {
    final file = File('ram.png');

    when(mockMemory.getImageFromMemory(any))
        .thenAnswer((_) async => file);

    final ctrl = buildController();

    final result = await ctrl.getCachedImage('gs://bucket/file.png');

    expect(result, file);

    verifyNever(mockStorage.refFromURL(any));
  });

  test('getCachedImage saves disk image into RAM cache', () async {
    final file = File('disk.png');

    when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
    when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => file);

    final ctrl = buildController();

    await ctrl.getCachedImage('url');

    verify(mockMemory.saveImageToMemory('url', file)).called(1);
  });

  test('notifyNewChallenge uses fallback when null', () {
    when(mockNotification.showTrekkingNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async {});

    final ctrl = buildController();

    ctrl.notifyNewChallenge('type', mockLocal);

    verify(mockNotification.showTrekkingNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      payload: 'type',
    )).called(1);
  });

  test('loadChallenges with empty collection', () async {
    final ctrl = buildController();

    await ctrl.loadChallenges();

    expect(ctrl.allChallenges, isEmpty);
  });

  test('getChallengesById handles exception safely', () {
    final ctrl = buildController();

    final result = ctrl.getChallengesById('anything');

    expect(result, isNull);
  });
}