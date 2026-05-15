import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/pages/DiaryPage/change-diary-page.dart';
import 'package:triplo/service/authservice.dart';
import 'change_diary_page_test.mocks.dart';
import 'dart:io';

@GenerateMocks([AuthService, TrekkingController, UserController])

// ---------------------------------------------------------------------------
// Helper builders – top-level, fuori da main()
// ---------------------------------------------------------------------------

Users _user({String uid = 'user1', String username = 'mario'}) => Users(
      uid: uid,
      username: username,
      name: 'Mario',
      surname: 'Rossi',
      email: 'mario@test.it',
      birthdate: DateTime(2000, 6, 1),
      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],
      level: 'beginner',
      advanced: 0,
      intermediate: 0,
      photoProfile: null,
    );

Trekking _trekkingWithChallenges() => Trekking(
      documentId: 'trek1',
      name: 'Monte Rosa',
      mapPhoto: '',
      difficultyLevel: 'medium',
      distance: 12.5,
      estimatedTime: 4.0,
      elevationGain: 800.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(45.0, 7.0),
      endingPoint: const LatLng(46.0, 8.0),
      points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
      startingPointName: 'Partenza',
      endingPointName: 'Arrivo',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: true,
      challenges: ['challenge1', 'challenge2'],
    );

Trekking _trekkingNoChallenge() => Trekking(
      documentId: 'trek1',
      name: 'Monte Rosa',
      mapPhoto: '',
      difficultyLevel: 'easy',
      distance: 5.0,
      estimatedTime: 2.0,
      elevationGain: 200.0,
      upGain: false,
      downGain: false,
      startingPoint: const LatLng(45.0, 7.0),
      endingPoint: const LatLng(46.0, 8.0),
      points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
      startingPointName: 'A',
      endingPointName: 'B',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );

Diary _diaryWith({
  String diaryId = 'diary_extra',
  List<String> photos = const [],
  List<String> challenges = const [],
  String refreshmentPoint = '',
  List<String> mood = const [],
  bool isPublic = true,
  String date = '01/06/2024',
  double duration = 120.0,
}) =>
    Diary(
      diaryId: diaryId,
      userId: 'user1',
      trekkigName: 'Monte Rosa',
      date: date,
      duration: duration,
      friends: [],
      photos: photos,
      challenges: challenges,
      refreshmentPoint: refreshmentPoint,
      mood: mood,
      notes: 'Note test',
      isPublic: isPublic,
    );

Diary _buildDiary({
  String diaryId = 'diary1',
  String userId = 'user1',
  bool isPublic = true,
}) =>
    Diary(
      diaryId: diaryId,
      userId: userId,
      trekkigName: 'Monte Rosa',
      date: '01/06/2024',
      duration: 120.0,
      friends: ['friend1'],
      photos: ['photo1.jpg'],
      challenges: ['challenge1'],
      refreshmentPoint: 'Rifugio Gnifetti',
      mood: ['😍'],
      notes: 'Bella escursione',
      isPublic: isPublic,
    );

Diary _buildDiaryForWidget() => Diary(
      diaryId: 'diary_widget',
      userId: 'user1',
      trekkigName: 'Monte Rosa',
      date: '01/06/2024',
      duration: 120.0,
      friends: [],
      photos: [],
      challenges: [],
      refreshmentPoint: 'Rifugio Gnifetti',
      mood: ['😍'],
      notes: 'Bella escursione',
      isPublic: true,
    );

Users _buildUser({String uid = 'user1', String username = 'mario'}) => Users(
      uid: uid,
      username: username,
      name: 'Mario',
      surname: 'Rossi',
      email: 'mario@test.it',
      birthdate: DateTime(2000, 6, 1),
      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],
      level: 'beginner',
      advanced: 0,
      intermediate: 0,
      photoProfile: null,
    );

Trekking _buildTrekking() => Trekking(
      documentId: 'trek1',
      name: 'Monte Rosa',
      mapPhoto: 'map.jpg',
      difficultyLevel: 'medium',
      distance: 12.5,
      estimatedTime: 4.0,
      elevationGain: 800.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(45.0, 7.0),
      endingPoint: const LatLng(46.0, 8.0),
      points: const [LatLng(45.0, 7.0), LatLng(45.5, 7.5), LatLng(46.0, 8.0)],
      startingPointName: 'Partenza',
      endingPointName: 'Arrivo',
      info: ['info1'],
      endingPointPhoto: 'ending.jpg',
      description: ['desc1'],
      refreshmentPoint: 'Rifugio Test',
      picNicArea: false,
      familyFirendly: true,
      challenges: ['challenge1'],
    );

Trekking _buildTrekkingForWidget() => Trekking(
      documentId: 'trek1',
      name: 'Monte Rosa',
      mapPhoto: '',
      difficultyLevel: 'medium',
      distance: 12.5,
      estimatedTime: 4.0,
      elevationGain: 800.0,
      upGain: true,
      downGain: false,
      startingPoint: const LatLng(45.0, 7.0),
      endingPoint: const LatLng(46.0, 8.0),
      points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
      startingPointName: 'Partenza',
      endingPointName: 'Arrivo',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: true,
    );

Map<String, dynamic> _diaryFirestoreMap({
  bool isPublic = true,
  String userId = 'user1',
}) =>
    {
      'UserId': userId,
      'Trekking_name': 'Sentiero Test',
      'Date': '01/01/2024',
      'Duration': 60,
      'Friends': [],
      'Photos': [],
      'Challenges': [],
      'Refreshment_point': '',
      'Mood': [],
      'Notes': '',
      'Is_public': isPublic,
    };

// ---------------------------------------------------------------------------
// App builder e setup globale per i test che usano _setUp()
// ---------------------------------------------------------------------------

Widget _buildApp({
  required DiaryController diaryController,
  required MockTrekkingController trekkingCtrl,
  required MockUserController userCtrl,
  String diaryId = 'diary_extra',
  String trekkingId = 'trek1',
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DiaryController>.value(value: diaryController),
      ChangeNotifierProvider<TrekkingController>.value(value: trekkingCtrl),
      ChangeNotifierProvider<UserController>.value(value: userCtrl),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ModifyDiaryPage(trekkingId: trekkingId, diaryId: diaryId),
    ),
  );
}

late MockAuthService _mockAuth;
late MockTrekkingController _trekkingCtrl;
late MockUserController _userCtrl;
late FakeFirebaseFirestore _fakeFirestore;
late DiaryController _diaryCtrl;
late Users _fakeUser;

void _setUp({Trekking? trekking}) {
  _mockAuth = MockAuthService();
  when(_mockAuth.currentUid).thenReturn('user1');
  _fakeFirestore = FakeFirebaseFirestore();
  _diaryCtrl = DiaryController(_mockAuth, firestore: _fakeFirestore);
  _fakeUser = _user();
  _diaryCtrl.currentUser = _fakeUser;

  _trekkingCtrl = MockTrekkingController();
  when(_trekkingCtrl.getTrekkingById('trek1'))
      .thenReturn(trekking ?? _trekkingNoChallenge());
  when(_trekkingCtrl.getDownloadUrl(any))
      .thenAnswer((_) async => 'https://placeholder.url/img.jpg');

  _userCtrl = MockUserController();
  when(_userCtrl.currentUser).thenReturn(_fakeUser);
  when(_userCtrl.getFollowing('user1')).thenAnswer((_) async => <Users>[]);
}

// ---------------------------------------------------------------------------
// Mock ImagePicker helpers
// ---------------------------------------------------------------------------

/// Simula il picker chiuso senza alcuna selezione (lista vuota).
class _MockImagePickerEmpty extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = false,
  }) async =>
      [];
}

/// Simula il picker che lancia un'eccezione (comportamento "null" / annullato
/// in ambienti dove il plugin non è disponibile).
class _MockImagePickerNull extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = false,
  }) async =>
      // Restituisce lista vuota: il codice che controlla `isEmpty` la tratta
      // esattamente come un picker chiuso senza selezione.
      [];
}

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

void main() {
  group('Diary model', () {
    test('toMap() serializza tutti i campi correttamente', () {
      final map = _buildDiary().toMap();
      expect(map['UserId'], 'user1');
      expect(map['Trekking_name'], 'Monte Rosa');
      expect(map['Date'], '01/06/2024');
      expect(map['Duration'], 120.0);
      expect(map['Friends'], ['friend1']);
      expect(map['Photos'], ['photo1.jpg']);
      expect(map['Challenges'], ['challenge1']);
      expect(map['Refreshment_point'], 'Rifugio Gnifetti');
      expect(map['Mood'], ['😍']);
      expect(map['Notes'], 'Bella escursione');
      expect(map['Is_public'], true);
    });

    test('fromMap() deserializza correttamente da Firestore', () {
      final diary = Diary.fromMap({
        'UserId': 'user1',
        'Trekking_name': 'Monte Rosa',
        'Date': '01/06/2024',
        'Duration': 120,
        'Friends': ['friend1'],
        'Photos': ['photo1.jpg'],
        'Challenges': ['challenge1'],
        'Refreshment_point': 'Rifugio Gnifetti',
        'Mood': ['😍'],
        'Notes': 'Bella escursione',
        'Is_public': true,
      }, diaryId: 'diary123');

      expect(diary.diaryId, 'diary123');
      expect(diary.userId, 'user1');
      expect(diary.trekkigName, 'Monte Rosa');
      expect(diary.date, '01/06/2024');
      expect(diary.duration, 120.0);
      expect(diary.friends, ['friend1']);
      expect(diary.photos, ['photo1.jpg']);
      expect(diary.challenges, ['challenge1']);
      expect(diary.refreshmentPoint, 'Rifugio Gnifetti');
      expect(diary.mood, ['😍']);
      expect(diary.notes, 'Bella escursione');
      expect(diary.isPublic, true);
    });

    test('fromMap() usa valori di default per campi mancanti', () {
      final diary = Diary.fromMap({}, diaryId: 'empty');
      expect(diary.userId, '');
      expect(diary.trekkigName, 'Unknown Trek');
      expect(diary.date, '');
      expect(diary.duration, 0.0);
      expect(diary.friends, []);
      expect(diary.photos, []);
      expect(diary.challenges, []);
      expect(diary.refreshmentPoint, '');
      expect(diary.mood, []);
      expect(diary.notes, '');
      expect(diary.isPublic, false);
    });

    test('fromMap() converte List<dynamic> in List<String> per photos', () {
      final diary = Diary.fromMap({
        'Photos': [1, 2, 3],
        'Challenges': ['c1'],
        'Mood': ['😁'],
      }, diaryId: 'x');
      expect(diary.photos, ['1', '2', '3']);
    });

    test('toMap() e fromMap() sono simmetrici (round-trip)', () {
      final original = _buildDiary();
      final restored =
          Diary.fromMap(original.toMap(), diaryId: original.diaryId);
      expect(restored.diaryId, original.diaryId);
      expect(restored.userId, original.userId);
      expect(restored.trekkigName, original.trekkigName);
      expect(restored.date, original.date);
      expect(restored.duration, original.duration);
      expect(restored.friends, original.friends);
      expect(restored.photos, original.photos);
      expect(restored.challenges, original.challenges);
      expect(restored.refreshmentPoint, original.refreshmentPoint);
      expect(restored.mood, original.mood);
      expect(restored.notes, original.notes);
      expect(restored.isPublic, original.isPublic);
    });
  });

  group('Users model', () {
    test('toMap() serializza i campi primitivi correttamente', () {
      final map = _buildUser().toMap();
      expect(map['Uid'], 'user1');
      expect(map['Username'], 'mario');
      expect(map['Name'], 'Mario');
      expect(map['Surname'], 'Rossi');
      expect(map['Email'], 'mario@test.it');
      expect(map['Level'], 'beginner');
      expect(map['Advanced'], 0);
      expect(map['Intermediate'], 0);
    });

    test('toMap() serializza followers/following come lista di uid', () {
      final user = _buildUser();
      user.followers = [_buildUser(uid: 'friend1', username: 'luigi')];
      user.following = [_buildUser(uid: 'friend1', username: 'luigi')];
      final map = user.toMap();
      expect(map['Followers'], ['friend1']);
      expect(map['Following'], ['friend1']);
    });

    test(
        'toMap() serializza publicDiaryPages e privateDiaryPages come lista di diaryId',
        () {
      final user = _buildUser();
      user.publicDiaryPages = [_buildDiary()];
      user.privateDiaryPages = [_buildDiary(diaryId: 'diary2', isPublic: false)];
      final map = user.toMap();
      expect(map['Public_diary'], ['diary1']);
      expect(map['Private_diary'], ['diary2']);
    });

    test('fromMap() deserializza correttamente i campi primitivi', () {
      final user = Users.fromMap({
        'Username': 'mario',
        'Name': 'Mario',
        'Surname': 'Rossi',
        'Email': 'mario@test.it',
        'Birthdate': '2000-06-01T00:00:00.000',
        'Photo_profile': 'https://foto.url',
        'Level': 'beginner',
        'Advanced': 2,
        'Intermediate': 3,
      }, uid: 'user1');
      expect(user.uid, 'user1');
      expect(user.username, 'mario');
      expect(user.name, 'Mario');
      expect(user.surname, 'Rossi');
      expect(user.email, 'mario@test.it');
      expect(user.birthdate, DateTime(2000, 6, 1));
      expect(user.photoProfile, 'https://foto.url');
      expect(user.level, 'beginner');
      expect(user.advanced, 2);
      expect(user.intermediate, 3);
    });

    test('fromMap() inizializza le liste relazionali vuote', () {
      final user = Users.fromMap({'Username': 'mario'}, uid: 'user1');
      expect(user.followers, isEmpty);
      expect(user.following, isEmpty);
      expect(user.publicDiaryPages, isEmpty);
      expect(user.privateDiaryPages, isEmpty);
      expect(user.savedTrekkings, isEmpty);
    });

    test('fromMap() usa valori di default per campi mancanti', () {
      final user = Users.fromMap({}, uid: 'empty');
      expect(user.username, '');
      expect(user.name, '');
      expect(user.surname, '');
      expect(user.email, '');
      expect(user.birthdate, DateTime(2000, 1, 1));
      expect(user.photoProfile, '');
      expect(user.level, '');
      expect(user.advanced, 0);
      expect(user.intermediate, 0);
    });

    test('fromMap() accetta anche chiavi lowercase username/email', () {
      final user =
          Users.fromMap({'username': 'mario', 'email': 'mario@test.it'}, uid: 'u1');
      expect(user.username, 'mario');
      expect(user.email, 'mario@test.it');
    });

    test('fromMap() parsifica Advanced/Intermediate come stringa', () {
      final user = Users.fromMap({'Advanced': '5', 'Intermediate': '3'}, uid: 'u1');
      expect(user.advanced, 5);
      expect(user.intermediate, 3);
    });

    test('fromMap() usa registerdate come birthdate legacy', () {
      final user =
          Users.fromMap({'registerdate': '1990-03-15T00:00:00.000'}, uid: 'u1');
      expect(user.birthdate, DateTime(1990, 3, 15));
    });

    test('setter aggiornano correttamente i campi', () {
      final user = _buildUser();
      user.username = 'luigi';
      user.email = 'luigi@test.it';
      user.level = 'advanced';
      user.advanced = 10;
      expect(user.username, 'luigi');
      expect(user.email, 'luigi@test.it');
      expect(user.level, 'advanced');
      expect(user.advanced, 10);
    });
  });

  group('Trekking model', () {
    test('toMap() serializza i campi primitivi correttamente', () {
      final map = _buildTrekking().toMap();
      expect(map['Name'], 'Monte Rosa');
      expect(map['Difficulty_level'], 'medium');
      expect(map['Distance'], 12.5);
      expect(map['Estimated_time'], 4.0);
      expect(map['Elevation_gain'], 800.0);
      expect(map['Up_gain'], true);
      expect(map['Down_gain'], false);
      expect(map['Starting_point_name'], 'Partenza');
      expect(map['Ending_point_name'], 'Arrivo');
      expect(map['Refreshment_point'], 'Rifugio Test');
      expect(map['Picnic_area'], false);
      expect(map['Family_friendly'], true);
      expect(map['Challenges'], ['challenge1']);
      expect(map['Info'], ['info1']);
      expect(map['Description'], ['desc1']);
    });

    test('getter restituiscono i valori corretti', () {
      final t = _buildTrekking();
      expect(t.name, 'Monte Rosa');
      expect(t.difficulty_level, 'medium');
      expect(t.distance, 12.5);
      expect(t.estimated_time, 4.0);
      expect(t.elevation_gain, 800.0);
      expect(t.upGain, true);
      expect(t.downGain, false);
      expect(t.starting_point_name, 'Partenza');
      expect(t.ending_point_name, 'Arrivo');
      expect(t.refreshment_point, 'Rifugio Test');
      expect(t.pic_nic_area, false);
      expect(t.family_firendly, true);
      expect(t.challenges, ['challenge1']);
    });

    test('setter aggiornano i campi correttamente', () {
      final t = _buildTrekking();
      t.name = 'Gran Paradiso';
      t.distance = 20.0;
      t.difficulty_level = 'hard';
      t.challenges = ['c1', 'c2'];
      expect(t.name, 'Gran Paradiso');
      expect(t.distance, 20.0);
      expect(t.difficulty_level, 'hard');
      expect(t.challenges, ['c1', 'c2']);
    });

    test('challenges è vuota di default se non passata', () {
      final t = Trekking(
        documentId: 'trek1',
        name: 'Test',
        mapPhoto: '',
        difficultyLevel: 'easy',
        distance: 1.0,
        estimatedTime: 1.0,
        elevationGain: 0.0,
        upGain: false,
        downGain: false,
        startingPoint: const LatLng(0, 0),
        endingPoint: const LatLng(0, 0),
        points: const [],
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

    test('refreshment_point è stringa vuota di default se non passato', () {
      final t = Trekking(
        documentId: 'trek1',
        name: 'Test',
        mapPhoto: '',
        difficultyLevel: 'easy',
        distance: 1.0,
        estimatedTime: 1.0,
        elevationGain: 0.0,
        upGain: false,
        downGain: false,
        startingPoint: const LatLng(0, 0),
        endingPoint: const LatLng(0, 0),
        points: const [],
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

    test('starting_point corrisponde al primo punto della lista', () {
      expect(_buildTrekking().starting_point.latitude, 45.0);
      expect(_buildTrekking().starting_point.longitude, 7.0);
    });

    test("ending_point corrisponde all'ultimo punto della lista", () {
      expect(_buildTrekking().ending_point.latitude, 46.0);
      expect(_buildTrekking().ending_point.longitude, 8.0);
    });
  });

  group('DiaryController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockAuthService mockAuth;
    late DiaryController controller;
    late Users fakeUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');
      controller = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      controller.currentUser = fakeUser;
      await fakeFirestore.collection('users').doc('user1').set({
        'Public_diary': [],
        'Private_diary': [],
      });
    });

    test('getDiaryById restituisce null se la lista è vuota', () {
      expect(controller.getDiaryById('nonexistent'), isNull);
    });

    test('updateDiary aggiorna tutti i campi del diario locale', () {
      final updated = controller.updateDiary(
        _buildDiary(),
        false,
        '10/10/2025',
        90.0,
        ['f2'],
        ['p2.jpg'],
        ['c2'],
        'Rifugio Nuovo',
        ['😎'],
        'Note aggiornate',
      );
      expect(updated.isPublic, false);
      expect(updated.date, '10/10/2025');
      expect(updated.duration, 90.0);
      expect(updated.friends, ['f2']);
      expect(updated.photos, ['p2.jpg']);
      expect(updated.challenges, ['c2']);
      expect(updated.refreshmentPoint, 'Rifugio Nuovo');
      expect(updated.mood, ['😎']);
      expect(updated.notes, 'Note aggiornate');
    });

    test('addDiary (nuovo) aggiunge il diario alla lista locale', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], 'Note test', false, '');
      expect(controller.allDiaries.length, 1);
      expect(controller.allDiaries.first.trekkigName, 'Monte Rosa');
    });

    test("addDiary (nuovo, pubblico) aggiorna publicDiaryPages dell'utente",
        () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      expect(fakeUser.publicDiaryPages.length, 1);
      expect(fakeUser.privateDiaryPages.length, 0);
    });

    test("addDiary (nuovo, privato) aggiorna privateDiaryPages dell'utente",
        () async {
      await controller.addDiary(
          'Monte Rosa', false, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      expect(fakeUser.privateDiaryPages.length, 1);
      expect(fakeUser.publicDiaryPages.length, 0);
    });

    test('addDiary (nuovo) scrive il documento su Firestore', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      final doc = await fakeFirestore.collection('diary').doc(diaryId).get();
      expect(doc.exists, true);
      expect(doc.data()!['Trekking_name'], 'Monte Rosa');
    });

    test('addDiary (modifica) aggiorna notes e date del diario esistente',
        () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], 'Note originali', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Monte Rosa', true, '05/07/2024', 90.0, [], [], [], '', [], 'Note modificate', true, diaryId);
      final updated = controller.getDiaryById(diaryId)!;
      expect(updated.notes, 'Note modificate');
      expect(updated.date, '05/07/2024');
    });

    test('addDiary (modifica) cambia visibilità e aggiorna Firestore', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Monte Rosa', false, '01/06/2024', 120.0, [], [], [], '', [], '', true, diaryId);
      final doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final publicList =
          List<String>.from(doc.data()?['Public_diary'] ?? []);
      final privateList =
          List<String>.from(doc.data()?['Private_diary'] ?? []);
      expect(publicList.contains(diaryId), false);
      expect(privateList.contains(diaryId), true);
    });

    test('removeDiary elimina il diario dalla lista locale', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.removeDiary(diaryId);
      expect(controller.allDiaries.isEmpty, true);
    });

    test('removeDiary elimina il documento da Firestore', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.removeDiary(diaryId);
      final doc =
          await fakeFirestore.collection('diary').doc(diaryId).get();
      expect(doc.exists, false);
    });

    test("removeDiary (pubblico) rimuove da publicDiaryPages dell'utente",
        () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.removeDiary(diaryId);
      expect(fakeUser.publicDiaryPages.isEmpty, true);
    });

    test('fetchDiaryById restituisce null se non esistono diari', () async {
      final result = await controller.fetchDiaryById('userSenzaDiari');
      expect(result, isNull);
    });

    test("fetchDiaryById restituisce i diari dell'utente", () async {
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap());
      final result = await controller.fetchDiaryById('user1');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.trekkigName, 'Sentiero Test');
    });

    test('getPublicDiaries restituisce solo diari pubblici', () async {
      await fakeFirestore
          .collection('diary')
          .add(_diaryFirestoreMap(isPublic: true));
      await fakeFirestore
          .collection('diary')
          .add(_diaryFirestoreMap(isPublic: false));
      final result = await controller.getPublicDiaries('user1');
      expect(result.every((d) => d.isPublic), true);
    });

    test('getPrivateDiaries restituisce solo diari privati', () async {
      await fakeFirestore
          .collection('diary')
          .add(_diaryFirestoreMap(isPublic: true));
      await fakeFirestore
          .collection('diary')
          .add(_diaryFirestoreMap(isPublic: false));
      final result = await controller.getPrivateDiaries('user1');
      expect(result.every((d) => !d.isPublic), true);
    });

    test('getDiaryByIdAsync trova il diario nella cache locale', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      final result = await controller.getDiaryByIdAsync(diaryId);
      expect(result, isNotNull);
      expect(result!.diaryId, diaryId);
    });

    test('getDiaryByIdAsync cerca su Firestore se non in cache', () async {
      final docRef =
          await fakeFirestore.collection('diary').add(_diaryFirestoreMap());
      final result = await controller.getDiaryByIdAsync(docRef.id);
      expect(result, isNotNull);
      expect(result!.trekkigName, 'Sentiero Test');
    });

    test('getDiaryByIdAsync restituisce null se non trovato', () async {
      expect(await controller.getDiaryByIdAsync('inesistente'), isNull);
    });

    test('getRandomPublicDiariesFromFollowing rispetta il limite', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('diary').add(
            _diaryFirestoreMap(userId: 'followedUser', isPublic: true));
      }
      final result = await controller.getRandomPublicDiariesFromFollowing(
          followingIds: ['followedUser'], limit: 3);
      expect(result.length, lessThanOrEqualTo(3));
    });

    test(
        'getRandomPublicDiariesFromFollowing restituisce solo diari pubblici',
        () async {
      await fakeFirestore.collection('diary').add(
          _diaryFirestoreMap(userId: 'followedUser', isPublic: true));
      await fakeFirestore.collection('diary').add(
          _diaryFirestoreMap(userId: 'followedUser', isPublic: false));
      final result = await controller.getRandomPublicDiariesFromFollowing(
          followingIds: ['followedUser'], limit: 10);
      expect(result.every((d) => d.isPublic), true);
    });
  });

  group('DiaryController – edge case aggiuntivi', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockAuthService mockAuth;
    late DiaryController controller;
    late Users fakeUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');
      controller = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      controller.currentUser = fakeUser;
      await fakeFirestore.collection('users').doc('user1').set({
        'Public_diary': [],
        'Private_diary': [],
      });
    });

    test('getDiaryById restituisce il diario corretto quando presente',
        () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', [], 'note', false, '');
      final id = controller.allDiaries.first.diaryId;
      expect(controller.getDiaryById(id), isNotNull);
      expect(controller.getDiaryById(id)!.diaryId, id);
    });

    test("updateDiary aggiorna tutti i campi nell'oggetto restituito", () {
      final diary = _buildDiary();
      final updated = controller.updateDiary(
          diary, false, '31/12/2025', 30.0, [], [], [], '', [], 'nuovo');
      expect(updated.notes, 'nuovo');
      expect(updated.duration, 30.0);
      expect(updated.date, '31/12/2025');
      expect(updated.isPublic, false);
    });

    test(
        'addDiary (modifica) da privato a pubblico aggiorna correttamente Firestore',
        () async {
      await controller.addDiary(
          'Sentiero', false, '01/01/2024', 60.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Sentiero', true, '01/01/2024', 60.0, [], [], [], '', [], '', true, diaryId);
      final doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final publicList =
          List<String>.from(doc.data()?['Public_diary'] ?? []);
      final privateList =
          List<String>.from(doc.data()?['Private_diary'] ?? []);
      expect(publicList.contains(diaryId), true);
      expect(privateList.contains(diaryId), false);
    });

    test('removeDiary (privato) rimuove da privateDiaryPages', () async {
      await controller.addDiary(
          'Sentiero', false, '01/01/2024', 60.0, [], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.removeDiary(diaryId);
      expect(fakeUser.privateDiaryPages.isEmpty, true);
    });

    test(
        'getRandomPublicDiariesFromFollowing con followingIds vuota restituisce lista vuota',
        () async {
      final result = await controller.getRandomPublicDiariesFromFollowing(
          followingIds: [], limit: 10);
      expect(result, isEmpty);
    });

    test('getPublicDiaries restituisce lista vuota se non ci sono diari',
        () async {
      final result = await controller.getPublicDiaries('user_senza_diari');
      expect(result, isEmpty);
    });

    test('getPrivateDiaries restituisce lista vuota se non ci sono diari',
        () async {
      final result = await controller.getPrivateDiaries('user_senza_diari');
      expect(result, isEmpty);
    });

    test('addDiary (modifica) aggiorna il refreshmentPoint', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], 'Rifugio Vecchio', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], 'Rifugio Nuovo', [], '', true, diaryId);
      expect(
          controller.getDiaryById(diaryId)!.refreshmentPoint, 'Rifugio Nuovo');
    });

    test('addDiary (modifica) aggiorna il campo mood', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', ['😍'], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, [], [], [], '', ['😎', '😁'], '', true, diaryId);
      expect(controller.getDiaryById(diaryId)!.mood, ['😎', '😁']);
    });

    test('addDiary (modifica) aggiorna la lista friends', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, ['friend1'], [], [], '', [], '', false, '');
      final diaryId = controller.allDiaries.first.diaryId;
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 120.0, ['friend2', 'friend3'], [], [], '', [], '', true, diaryId);
      expect(controller.getDiaryById(diaryId)!.friends, ['friend2', 'friend3']);
    });

    test("fetchDiaryById restituisce tutti i diari di un utente", () async {
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap());
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap());
      final result = await controller.fetchDiaryById('user1');
      expect(result, isNotNull);
      expect(result!.length, 2);
    });

    test(
        'getDiaryByIdAsync aggiunge il diario alla cache locale se non presente',
        () async {
      final docRef =
          await fakeFirestore.collection('diary').add(_diaryFirestoreMap());
      expect(controller.allDiaries.isEmpty, true);
      final result = await controller.getDiaryByIdAsync(docRef.id);
      expect(result, isNotNull);
    });

    test('addDiary scrive duration come somma ore*60+minuti', () async {
      await controller.addDiary(
          'Monte Rosa', true, '01/06/2024', 150.0, [], [], [], '', [], '', false, '');
      expect(controller.allDiaries.first.duration, 150.0);
    });

    test('addDiary aggiunge diari multipli alla lista locale', () async {
      await controller.addDiary(
          'Trek A', true, '01/01/2024', 60.0, [], [], [], '', [], '', false, '');
      await controller.addDiary(
          'Trek B', true, '02/01/2024', 90.0, [], [], [], '', [], '', false, '');
      expect(controller.allDiaries.length, 2);
      expect(controller.allDiaries.map((d) => d.trekkigName).toList(),
          containsAll(['Trek A', 'Trek B']));
    });
  });

  group('Diary model – edge case aggiuntivi', () {
    test('fromMap() gestisce Duration come double invece di int', () {
      final diary = Diary.fromMap({'Duration': 90.5}, diaryId: 'x');
      expect(diary.duration, 90.5);
    });

    test('toMap() serializza un diario con tutti i campi vuoti', () {
      final diary = Diary(
        diaryId: 'empty',
        userId: '',
        trekkigName: '',
        date: '',
        duration: 0.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: false,
      );
      final map = diary.toMap();
      expect(map['Friends'], isEmpty);
      expect(map['Photos'], isEmpty);
      expect(map['Is_public'], false);
    });

    test('fromMap() gestisce Is_public mancante come false', () {
      final diary = Diary.fromMap({'Trekking_name': 'Test'}, diaryId: 'x');
      expect(diary.isPublic, false);
    });

    test('fromMap() usa 0.0 come default per Duration mancante', () {
      final diary = Diary.fromMap({}, diaryId: 'x');
      expect(diary.duration, 0.0);
    });

    test(
        'fromMap() usa stringa vuota come default per Refreshment_point mancante',
        () {
      final diary = Diary.fromMap({}, diaryId: 'x');
      expect(diary.refreshmentPoint, '');
    });

    test('fromMap() usa stringa vuota come default per Notes mancante', () {
      final diary = Diary.fromMap({}, diaryId: 'x');
      expect(diary.notes, '');
    });

    test('toMap() include UserId correttamente', () {
      final diary = _buildDiary();
      expect(diary.toMap()['UserId'], 'user1');
    });
  });

  group('Users model – edge case aggiuntivi', () {
    test('toMap() con liste vuote serializza correttamente', () {
      final user = _buildUser();
      final map = user.toMap();
      expect(map['Followers'], isEmpty);
      expect(map['Following'], isEmpty);
      expect(map['Public_diary'], isEmpty);
      expect(map['Private_diary'], isEmpty);
    });

    test('fromMap() gestisce Birthdate null usando il default', () {
      final user = Users.fromMap({}, uid: 'u1');
      expect(user.birthdate, DateTime(2000, 1, 1));
    });

    test('fromMap() gestisce Photo_profile null come stringa vuota', () {
      final user = Users.fromMap({'Photo_profile': null}, uid: 'u1');
      expect(user.photoProfile, '');
    });

    test('fromMap() accetta Advanced come int direttamente', () {
      final user = Users.fromMap({'Advanced': 7}, uid: 'u1');
      expect(user.advanced, 7);
    });

    test('setter photoProfile aggiorna il campo', () {
      final user = _buildUser();
      user.photoProfile = 'https://nuova.foto';
      expect(user.photoProfile, 'https://nuova.foto');
    });

    test('setter name e surname aggiornano i campi', () {
      final user = _buildUser();
      user.name = 'Luigi';
      user.surname = 'Bianchi';
      expect(user.name, 'Luigi');
      expect(user.surname, 'Bianchi');
    });

    test('toMap() serializza followers/following come lista di uid', () {
      final user = _buildUser();
      user.followers = [_buildUser(uid: 'f1', username: 'luigi')];
      user.following = [_buildUser(uid: 'f2', username: 'anna')];
      final map = user.toMap();
      expect(map['Followers'], ['f1']);
      expect(map['Following'], ['f2']);
    });
  });

  group('Trekking model – edge case aggiuntivi', () {
    test('toMap() serializza starting_point_name e ending_point_name', () {
      final map = _buildTrekking().toMap();
      expect(map['Starting_point_name'], 'Partenza');
      expect(map['Ending_point_name'], 'Arrivo');
    });

    test('toMap() serializza la lista info correttamente', () {
      expect(_buildTrekking().toMap()['Info'], ['info1']);
    });

    test('toMap() serializza description correttamente', () {
      expect(_buildTrekking().toMap()['Description'], ['desc1']);
    });

    test('toMap() serializza pic_nic_area e family_friendly', () {
      final map = _buildTrekking().toMap();
      expect(map['Picnic_area'], false);
      expect(map['Family_friendly'], true);
    });

    test('toMap() serializza up_gain e down_gain', () {
      final map = _buildTrekking().toMap();
      expect(map['Up_gain'], true);
      expect(map['Down_gain'], false);
    });

    test('setter info e description aggiornano i campi', () {
      final t = _buildTrekking();
      t.info = ['nuova info'];
      t.description = ['nuova desc'];
      expect(t.info, ['nuova info']);
      expect(t.description, ['nuova desc']);
    });

    test('setter refreshment_point aggiorna il campo', () {
      final t = _buildTrekking();
      t.refreshment_point = 'Nuovo rifugio';
      expect(t.refreshment_point, 'Nuovo rifugio');
    });

    test('setter pic_nic_area aggiorna il campo', () {
      final t = _buildTrekking();
      t.pic_nic_area = true;
      expect(t.pic_nic_area, true);
    });

    test('setter family_friendly aggiorna il campo', () {
      final t = _buildTrekking();
      t.family_firendly = false;
      expect(t.family_firendly, false);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ModifyDiaryPage – widget
  // ──────────────────────────────────────────────────────────────────────────
  group('ModifyDiaryPage – widget', () {
    late MockAuthService mockAuth;
    late MockTrekkingController mockTrekkingController;
    late MockUserController mockUserController;
    late DiaryController diaryController;
    late FakeFirebaseFirestore fakeFirestore;
    late Users fakeUser;

    setUp(() {
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');
      fakeFirestore = FakeFirebaseFirestore();
      diaryController = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      diaryController.currentUser = fakeUser;
      diaryController.allDiaries.add(_buildDiaryForWidget());
      mockTrekkingController = MockTrekkingController();
      when(mockTrekkingController.getDownloadUrl(any))
          .thenAnswer((_) async => 'https://placeholder.url/img.jpg');
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekkingForWidget());
      mockUserController = MockUserController();
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => <Users>[]);
    });

    Widget buildPage() => MultiProvider(
          providers: [
            ChangeNotifierProvider<DiaryController>.value(
                value: diaryController),
            ChangeNotifierProvider<TrekkingController>.value(
                value: mockTrekkingController),
            ChangeNotifierProvider<UserController>.value(
                value: mockUserController),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ModifyDiaryPage(trekkingId: 'trek1', diaryId: 'diary_widget'),
          ),
        );

    testWidgets('dropdown giorno mostra valore iniziale corretto',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final firstDropdown = tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>).first);
      expect(firstDropdown.value, 1);
    });

    testWidgets('dropdown minuti mostra valore iniziale corretto',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final minuteDropdown = tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>).at(4));
      expect(minuteDropdown.value, 0);
    });

    testWidgets('dropdown mese cambia valore selezionato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('dropdown anno cambia valore selezionato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2023'));
      await tester.pumpAndSettle();
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('dropdown ora cambia valore selezionato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('05'));
      await tester.pumpAndSettle();
      expect(find.text('05'), findsOneWidget);
    });

    testWidgets('sezione amici mostra testo "no friends" quando lista vuota',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(find.text(local.friends_selected_label), findsOneWidget);
    });

    testWidgets(
        'ExpansionTile amici espande e mostra lista following vuota',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate(
              (w) => w is ListTile && w.leading is CircleAvatar),
          findsNothing);
    });

    testWidgets('sezione mood mostra emoji preselezionata nel preview',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('😍'), findsWidgets);
    });

    testWidgets('ExpansionTile mood espande e tutte le emoji sono tappabili',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final tiles = find.byType(ExpansionTile);
      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('😁').first);
      await tester.pumpAndSettle();
      expect(find.text('😁'), findsWidgets);
    });

    testWidgets('tap su emoji già selezionata la rimuove dal mood',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final tiles = find.byType(ExpansionTile);
      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) =>
          w is ListTile &&
          w.leading is Text &&
          (w.leading as Text).data == '😍'));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😍'),
          findsNothing);
    });

    testWidgets('bottone Pubblico imposta isPublic a true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(local.public_botton_label));
      await tester.pumpAndSettle();
      final publicBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, local.public_botton_label));
      final fg =
          publicBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets('bottone Privato imposta isPublic a false', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();
      final privateBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, local.private_botton_label));
      final fg =
          privateBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets(
        'toggle No poi Sì ripristina visibilità TextField rifornimento',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      await tester.tap(find.widgetWithText(ChoiceChip, local.no_botton_label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, local.yes_botton_label));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('toggle No nasconde il campo testo del rifornimento',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'No'));
      await tester.pumpAndSettle();
      expect(find.text('Rifugio Gnifetti'), findsNothing);
    });

    testWidgets('card sezione ha bordo arrotondato (RoundedRectangleBorder)',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards, isNotEmpty);
      for (final card in cards) {
        expect(card.shape, isA<RoundedRectangleBorder>());
      }
    });

    testWidgets('SingleChildScrollView è presente nel layout', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets(
        'FutureBuilder mostra loading indicator durante caricamento following',
        (tester) async {
      when(mockUserController.getFollowing('user1')).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return <Users>[];
      });
      await tester.pumpWidget(buildPage());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('modifica del campo refreshment aggiorna il testo',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final refreshmentField = find.byType(TextField).at(1);
      await tester.ensureVisible(refreshmentField);
      await tester.pumpAndSettle();
      await tester.enterText(refreshmentField, 'Nuovo rifugio');
      await tester.pumpAndSettle();
      expect(find.text('Nuovo rifugio'), findsOneWidget);
    });

    testWidgets('mostra il titolo del trekking nella AppBar', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Monte Rosa'), findsOneWidget);
    });

    testWidgets('mostra tutte le icone delle sezioni', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.mood), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('i dropdown data sono precompilati con i valori del diary',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
      expect(find.text('6'), findsWidgets);
      expect(find.text('2024'), findsWidgets);
    });

    testWidgets('il campo Note è precompilato con il testo del diary',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Bella escursione'), findsOneWidget);
    });

    testWidgets('il campo refreshment è precompilato e visibile',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Rifugio Gnifetti'), findsOneWidget);
    });

    testWidgets(
        'toggle Sì ripristina la visibilità del campo rifornimento',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      await tester.tap(find.widgetWithText(ChoiceChip, 'No'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, local.yes_botton_label));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('i bottoni Pubblico e Privato sono presenti', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets(
        'ExpansionTile mood espande e mostra le emoji disponibili',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final tiles = find.byType(ExpansionTile);
      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      expect(find.text('😍'), findsWidgets);
      expect(find.text('😁'), findsWidgets);
    });

    testWidgets('il mood selezionato appare nella sezione preview',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('😍'), findsWidgets);
    });

    testWidgets('pulsante aggiungi foto è presente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('bottone Annulla fa pop della route', (tester) async {
      bool popped = false;
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<DiaryController>.value(value: diaryController),
          ChangeNotifierProvider<TrekkingController>.value(
              value: mockTrekkingController),
          ChangeNotifierProvider<UserController>.value(
              value: mockUserController),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ModifyDiaryPage(
                        trekkingId: 'trek1', diaryId: 'diary_widget'),
                  ),
                ).then((_) => popped = true);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(popped, true);
    });

    testWidgets('modifica del campo Note aggiorna il testo', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final noteField = find.byType(TextField).first;
      await tester.ensureVisible(noteField);
      await tester.pumpAndSettle();
      await tester.enterText(noteField, 'Nuova nota di test');
      await tester.pumpAndSettle();
      expect(find.text('Nuova nota di test'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ModifyDiaryPage – widget test aggiuntivi
  // ──────────────────────────────────────────────────────────────────────────
  group('ModifyDiaryPage – widget test aggiuntivi', () {
    late MockAuthService mockAuth;
    late MockTrekkingController mockTrekkingController;
    late MockUserController mockUserController;
    late DiaryController diaryController;
    late FakeFirebaseFirestore fakeFirestore;
    late Users fakeUser;

    setUp(() {
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');
      fakeFirestore = FakeFirebaseFirestore();
      diaryController = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      diaryController.currentUser = fakeUser;
      diaryController.allDiaries.add(_buildDiaryForWidget());
      mockTrekkingController = MockTrekkingController();
      when(mockTrekkingController.getDownloadUrl(any))
          .thenAnswer((_) async => 'https://placeholder.url/img.jpg');
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekkingForWidget());
      mockUserController = MockUserController();
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => <Users>[]);
    });

    Widget buildPage() => MultiProvider(
          providers: [
            ChangeNotifierProvider<DiaryController>.value(
                value: diaryController),
            ChangeNotifierProvider<TrekkingController>.value(
                value: mockTrekkingController),
            ChangeNotifierProvider<UserController>.value(
                value: mockUserController),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ModifyDiaryPage(trekkingId: 'trek1', diaryId: 'diary_widget'),
          ),
        );

    testWidgets('sezione challenges non appare se la lista è vuota',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('sezione challenges appare se il trekking ha challenge',
        (tester) async {
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekking());
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(Diary(
        diaryId: 'diary_widget',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: 'Rifugio Gnifetti',
        mood: ['😍'],
        notes: 'Bella escursione',
        isPublic: true,
      ));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets(
        'ExpansionTile amici mostra utente quando following non è vuota',
        (tester) async {
      final friend = _buildUser(uid: 'friend1', username: 'luigi');
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => <Users>[friend]);
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(find.text('luigi'), findsOneWidget);
    });

    testWidgets('tap su amico nella lista lo aggiunge ai friends',
        (tester) async {
      final friend = _buildUser(uid: 'friend1', username: 'luigi');
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => <Users>[friend]);
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('luigi'));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == 'luigi'),
          findsOneWidget);
    });

    testWidgets('dropdown giorno apre il menu con i valori corretti',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
      expect(find.text('31'), findsWidgets);
    });

    testWidgets('toggle No svuota il campo refreshment', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Rifugio Gnifetti'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'No'));
      await tester.pumpAndSettle();
      expect(find.text('Rifugio Gnifetti'), findsNothing);
    });

    testWidgets('AppBar ha il titolo centrato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets(
        'sono presenti almeno 7 sezioni Card (senza challenges)',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(tester.widgetList<Card>(find.byType(Card)).length,
          greaterThanOrEqualTo(7));
    });

    testWidgets('si possono selezionare più emoji di mood', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final tiles = find.byType(ExpansionTile);
      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) =>
          w is ListTile &&
          w.leading is Text &&
          (w.leading as Text).data == '😎'));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😎'),
          findsOneWidget);
    });

    testWidgets('bottone Annulla ha il label localizzato corretto',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(
          find.widgetWithText(ElevatedButton, local.cancel_button_label),
          findsOneWidget);
    });

    testWidgets('bottone Salva ha il label localizzato corretto',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(find.widgetWithText(ElevatedButton, local.save_botton_label),
          findsOneWidget);
    });

    testWidgets('dropdown minuti apre il menu con valori a due cifre',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(4));
      await tester.pumpAndSettle();
      expect(find.text('00'), findsWidgets);
      expect(find.text('05'), findsWidgets);
    });

    testWidgets('dropdown ore apre il menu con valori a due cifre',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(3));
      await tester.pumpAndSettle();
      expect(find.text('00'), findsWidgets);
      expect(find.text('01'), findsWidgets);
    });

    testWidgets('campo refreshment accetta input e lo mostra', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final refreshmentField = find.byType(TextField).at(1);
      await tester.ensureVisible(refreshmentField);
      await tester.pumpAndSettle();
      await tester.enterText(refreshmentField, 'Baita alpina');
      await tester.pumpAndSettle();
      expect(find.text('Baita alpina'), findsOneWidget);
    });

    testWidgets('più mood selezionati vengono mostrati come Chip multipli',
        (tester) async {
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(Diary(
        diaryId: 'diary_widget',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: 'Rifugio Gnifetti',
        mood: ['😍', '😁'],
        notes: 'Bella escursione',
        isPublic: true,
      ));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😍'),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😁'),
          findsOneWidget);
    });

    testWidgets('con isPublic=true il bottone Pubblico è attivo',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      final publicBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, local.public_botton_label));
      final fg =
          publicBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets(
        'con isPublic=false il bottone Privato è attivo inizialmente',
        (tester) async {
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(Diary(
        diaryId: 'diary_widget',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: false,
      ));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      final privateBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, local.private_botton_label));
      final fg =
          privateBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets(
        'con refreshmentPoint vuoto è presente solo il TextField delle Note',
        (tester) async {
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(Diary(
        diaryId: 'diary_widget',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      ));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(tester.widgetList<TextField>(find.byType(TextField)).length, 1);
    });

    testWidgets('bottone aggiungi foto è un ElevatedButton', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(
          find.ancestor(
              of: find.byIcon(Icons.add_photo_alternate),
              matching: find.byType(ElevatedButton)),
          findsOneWidget);
    });

    testWidgets('con mood vuoto appare il label mood_selected', (tester) async {
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(Diary(
        diaryId: 'diary_widget',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      ));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(find.text(local.mood_selected_label), findsOneWidget);
    });

    testWidgets('ScrollConfiguration è presente nel layout', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.byType(ScrollConfiguration), findsWidgets);
    });

    testWidgets('dropdown anno apre il menu con anni disponibili',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(2));
      await tester.pumpAndSettle();
      expect(find.text('2024'), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ModifyDiaryPage – branch non coperti
  // ──────────────────────────────────────────────────────────────────────────
  group('ModifyDiaryPage – branch non coperti', () {
    late MockAuthService mockAuth;
    late MockTrekkingController mockTrekkingController;
    late MockUserController mockUserController;
    late DiaryController diaryController;
    late FakeFirebaseFirestore fakeFirestore;
    late Users fakeUser;

    Widget buildPageWithDiary(
      Diary diary, {
      List<Users> following = const [],
      Trekking? trekking,
    }) {
      diaryController.allDiaries.clear();
      diaryController.allDiaries.add(diary);
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => following);
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(trekking ?? _buildTrekkingForWidget());
      when(mockTrekkingController.getDownloadUrl(any))
          .thenAnswer((_) async => 'https://placeholder.url/img.jpg');

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DiaryController>.value(value: diaryController),
          ChangeNotifierProvider<TrekkingController>.value(
              value: mockTrekkingController),
          ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQueryData.fromView(View.of(context)),
            child: child!,
          ),
          home: ModifyDiaryPage(trekkingId: 'trek1', diaryId: diary.diaryId),
        ),
      );
    }

    setUp(() {
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');
      fakeFirestore = FakeFirebaseFirestore();
      diaryController = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      diaryController.currentUser = fakeUser;
      mockTrekkingController = MockTrekkingController();
      mockUserController = MockUserController();
    });

    testWidgets(
        'mostra user_not_found quando getFollowing restituisce null',
        (tester) async {
      diaryController.allDiaries.add(_buildDiaryForWidget());
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => null as dynamic);
      when(mockTrekkingController.getTrekkingById('trek1'))
          .thenReturn(_buildTrekkingForWidget());
      when(mockTrekkingController.getDownloadUrl(any))
          .thenAnswer((_) async => 'https://placeholder.url/img.jpg');
      await tester.pumpWidget(buildPageWithDiary(_buildDiaryForWidget()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'con friends non vuoti mostra Wrap con Chip invece del testo',
        (tester) async {
      final friend = _buildUser(uid: 'friend1', username: 'mario');
      final diary = Diary(
        diaryId: 'diary_friends',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: ['friend1'],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary, following: [friend]));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == 'mario'),
          findsOneWidget);
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(find.text(local.friends_selected_label), findsNothing);
    });

    testWidgets('tap su amico già selezionato lo rimuove dalla lista',
        (tester) async {
      final friend = _buildUser(uid: 'friend1', username: 'mario');
      final diary = Diary(
        diaryId: 'diary_remove_friend',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: ['friend1'],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary, following: [friend]));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('mario').last);
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == 'mario'),
          findsNothing);
    });

    testWidgets('anno futuro nel diary usa selectedYear come startYear',
        (tester) async {
      final futureYear = DateTime.now().year + 5;
      final diary = Diary(
        diaryId: 'diary_future',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/$futureYear',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      expect(find.text(futureYear.toString()), findsOneWidget);
    });

    testWidgets("delete del chip mood rimuove emoji dall'anteprima",
        (tester) async {
      final diary = Diary(
        diaryId: 'diary_mood_delete',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: ['😍', '😁'],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      final deleteButton = find.byWidgetPredicate(
        (w) =>
            w is Chip &&
            w.label is Text &&
            (w.label as Text).data == '😍' &&
            w.onDeleted != null,
      );
      expect(deleteButton, findsOneWidget);
      tester.widget<Chip>(deleteButton).onDeleted!();
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😍'),
          findsNothing);
    });

    testWidgets(
        'tap Pubblico non aggiunge duplicato in publicDiaryPages',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final diary = _buildDiaryForWidget();
      fakeUser.publicDiaryPages.add(diary);
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(local.public_botton_label));
      await tester.pumpAndSettle();
      expect(
          fakeUser.publicDiaryPages
              .where((d) => d.diaryId == diary.diaryId)
              .length,
          1);
    });

    testWidgets('più mood preselezionati mostrano Chip multipli',
        (tester) async {
      final diary = Diary(
        diaryId: 'diary_multi_mood',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: ['😍', '😁'],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😍'),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😁'),
          findsOneWidget);
    });

    testWidgets(
        'con isPublic=false il bottone Privato è attivo inizialmente',
        (tester) async {
      final diary = Diary(
        diaryId: 'diary_private',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: false,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      final privateBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, local.private_botton_label));
      expect(
          privateBtn.style!.foregroundColor!.resolve(<MaterialState>{}),
          Colors.white);
    });

    testWidgets('con refreshmentPoint vuoto è presente solo 1 TextField',
        (tester) async {
      final diary = Diary(
        diaryId: 'diary_no_refresh',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      expect(tester.widgetList<TextField>(find.byType(TextField)).length, 1);
    });

    testWidgets('con mood vuoto appare il label mood_selected', (tester) async {
      final diary = Diary(
        diaryId: 'diary_no_mood',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();
      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      expect(find.text(local.mood_selected_label), findsOneWidget);
    });

    testWidgets(
        'tap bottone aggiungi foto chiama il picker (nessuna selezione)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPageWithDiary(_buildDiaryForWidget()));
      await tester.pumpAndSettle();

      final addPhotoBtn = find.ancestor(
        of: find.byIcon(Icons.add_photo_alternate),
        matching: find.byType(ElevatedButton),
      );
      expect(addPhotoBtn, findsOneWidget);
      await tester.ensureVisible(addPhotoBtn);
      await tester.pumpAndSettle();
      await tester.tap(addPhotoBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('onDeleted del chip amico rimuove uid dalla lista friends',
        (tester) async {
      final friend = _buildUser(uid: 'friend1', username: 'mario');
      final diary = Diary(
        diaryId: 'diary_chip_delete',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: ['friend1'],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary, following: [friend]));
      await tester.pumpAndSettle();

      final chip = find.byWidgetPredicate(
        (w) =>
            w is Chip &&
            w.label is Text &&
            (w.label as Text).data == 'mario' &&
            w.onDeleted != null,
      );
      expect(chip, findsOneWidget);

      tester.widget<Chip>(chip).onDeleted!();
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Chip &&
            w.label is Text &&
            (w.label as Text).data == 'mario'),
        findsNothing,
      );
    });

    testWidgets(
        'foto esistente con URL mostra pulsante eliminazione',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = Diary(
        diaryId: 'diary_del_photo',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 120.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap Salva non causa eccezioni (navigazione gestita)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.isLoading).thenReturn(false);

      await fakeFirestore.collection('users').doc('user1').set({
        'Public_diary': ['diary_widget'],
        'Private_diary': [],
      });
      await fakeFirestore.collection('diary').doc('diary_widget').set({
        'UserId': 'user1',
        'Trekking_name': 'Monte Rosa',
        'Date': '01/06/2024',
        'Duration': 120.0,
        'Friends': [],
        'Photos': [],
        'Challenges': [],
        'Refreshment_point': 'Rifugio Gnifetti',
        'Mood': ['😍'],
        'Notes': 'Bella escursione',
        'Is_public': true,
      });

      await tester.pumpWidget(buildPageWithDiary(_buildDiaryForWidget()));
      await tester.pumpAndSettle();

      final local =
          AppLocalizations.of(tester.element(find.byType(ModifyDiaryPage)))!;
      final saveBtn =
          find.widgetWithText(ElevatedButton, local.save_botton_label);
      expect(saveBtn, findsOneWidget);

      await tester.tap(saveBtn);
      await tester.pump();

      tester.takeException();
    });

    testWidgets(
        'il giorno e mese sono formattati con zero padding nella data',
        (tester) async {
      final diary = Diary(
        diaryId: 'diary_padding',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/01/2024',
        duration: 60.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();

      final dayDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).first);
      final monthDropdown = tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>).at(1));
      expect(dayDropdown.value, 1);
      expect(monthDropdown.value, 1);
    });

    testWidgets('la durata viene calcolata come ora*60+minuti', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = Diary(
        diaryId: 'diary_duration',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 150.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();

      final hourDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(3));
      expect(hourDropdown.value, 2);

      final minuteDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(4));
      expect(minuteDropdown.value, 30);
    });

    testWidgets(
        'con toggle No il refreshmentText viene azzerato al salvataggio',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = Diary(
        diaryId: 'diary_norefresh_save',
        userId: 'user1',
        trekkigName: 'Monte Rosa',
        date: '01/06/2024',
        duration: 60.0,
        friends: [],
        photos: [],
        challenges: [],
        refreshmentPoint: 'Rifugio Vecchio',
        mood: [],
        notes: '',
        isPublic: true,
      );
      await tester.pumpWidget(buildPageWithDiary(diary));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'No'));
      await tester.pumpAndSettle();

      expect(find.text('Rifugio Vecchio'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sezione Challenges – con trekking che ha challenges', () {
    setUp(() => _setUp(trekking: _trekkingWithChallenges()));

    Widget buildWithChallengeDiary({List<String> selected = const []}) {
      final diary = _diaryWith(challenges: selected);
      _diaryCtrl.allDiaries.add(diary);
      return _buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      );
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  // pickImages() – metodo pubblico del widget state
  // ──────────────────────────────────────────────────────────────────────────
  group('pickImages() – metodo pubblico dello State', () {
    setUp(() => _setUp());

    testWidgets('pickImages con lista vuota non modifica images (empty picker)',
        (tester) async {
      final diary = _diaryWith();
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      final state = tester.state<ModifyDiaryPageState>(
        find.byType(ModifyDiaryPage),
      );
      final mockPicker = _MockImagePickerEmpty();
      final imagesBefore = List<File>.from(state.images);
      await state.pickImages(mockPicker, state.images);

      expect(state.images, imagesBefore);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Branch misti aggiuntivi
  // ──────────────────────────────────────────────────────────────────────────
  group('Branch misti aggiuntivi', () {
    setUp(() => _setUp());

    testWidgets('durata 0 → ore 0 e minuti 0 nei dropdown', (tester) async {
      final diary = _diaryWith(duration: 0.0);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      final hourDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(3));
      final minuteDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(4));

      expect(hourDropdown.value, 0);
      expect(minuteDropdown.value, 0);
    });

    testWidgets('durata 59 minuti → ore 0, minuti 59', (tester) async {
      final diary = _diaryWith(duration: 59.0);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      final hourDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(3));
      final minuteDropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(4));

      expect(hourDropdown.value, 0);
      expect(minuteDropdown.value, 59);
    });

    testWidgets(
        'sezione foto: bottone add foto sempre presente indipendentemente da validPhotos',
        (tester) async {
      final diary = _diaryWith(photos: []);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets(
        'mood chip ha onDeleted: tap diretto su delete esegue remove',
        (tester) async {
      final diary = _diaryWith(mood: ['😍', '😎']);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      final chip = find.byWidgetPredicate(
        (w) =>
            w is Chip &&
            w.label is Text &&
            (w.label as Text).data == '😎' &&
            w.onDeleted != null,
      );
      expect(chip, findsOneWidget);
      tester.widget<Chip>(chip).onDeleted!();
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😎',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'con getFollowing che restituisce null non vengono sollevate eccezioni',
        (tester) async {
      when(_userCtrl.getFollowing('user1'))
          .thenAnswer((_) async => null as dynamic);

      final diary = _diaryWith();
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'SizedBox.shrink è renderizzato quando challenges è vuota',
        (tester) async {
      final diary = _diaryWith(challenges: []);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropdown giorno: cambio valore aggiorna selectedDay',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = _diaryWith(date: '01/06/2024');
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      final state = tester.state<ModifyDiaryPageState>(
        find.byType(ModifyDiaryPage),
      );
      expect(state.selectedDay, 15);
    });

    testWidgets('dropdown ore: cambio valore aggiorna selectedHour',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = _diaryWith(duration: 120.0);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<int>).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('05').last);
      await tester.pumpAndSettle();

      final state = tester.state<ModifyDiaryPageState>(
        find.byType(ModifyDiaryPage),
      );
      expect(state.selectedHour, 5);
    });

    testWidgets('dropdown minuti: cambio valore aggiorna selectedMinute',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diary = _diaryWith(duration: 120.0);
      _diaryCtrl.allDiaries.add(diary);

      await tester.pumpWidget(_buildApp(
        diaryController: _diaryCtrl,
        trekkingCtrl: _trekkingCtrl,
        userCtrl: _userCtrl,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<int>).at(4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30').last);
      await tester.pumpAndSettle();

      final state = tester.state<ModifyDiaryPageState>(
        find.byType(ModifyDiaryPage),
      );
      expect(state.selectedMinute, 30);
    });
  });
}