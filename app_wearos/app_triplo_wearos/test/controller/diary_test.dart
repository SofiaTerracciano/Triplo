import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/model/user.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _diaryDoc({
  required String userId,
  String trekkingName = 'Monte Rosa',
  String date = '2024-06-01',
  double duration = 3.5,
  bool isPublic = true,
  List<String> friends = const [],
  List<String> challenges = const [],
}) =>
    {
      'UserId': userId,
      'Trekking_name': trekkingName,
      'Date': date,
      'Duration': duration,
      'Is_public': isPublic,
      'Friends': friends,
      'Challenges': challenges,
    };

Users _fakeUser() => Users(
      uid: 'u1',
      username: 'mario',
      name: 'Mario',
      surname: 'Rossi',
      email: 'mario@test.it',
      birthdate: DateTime(1990),
      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],
      level: 'beginner',
      advanced: 0,
      intermediate: 0,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late FakeFirebaseFirestore fakeDb;

  // Ora DiaryController accetta db opzionale — niente più Firebase.initializeApp()
  DiaryController makeCtrl() => DiaryController(db: fakeDb);

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
  });

  // ── currentUser setter / getter ───────────────────────────────────────────

  group('currentUser', () {
    test('getter restituisce null inizialmente', () {
      expect(makeCtrl().currentUser, isNull);
    });

    test('setter aggiorna il valore', () {
      final ctrl = makeCtrl();
      ctrl.currentUser = _fakeUser();
      expect(ctrl.currentUser!.username, 'mario');
    });
  });

  // ── allDiaries getter ─────────────────────────────────────────────────────

  group('allDiaries', () {
    test('lista vuota inizialmente', () {
      expect(makeCtrl().allDiaries, isEmpty);
    });
  });

  // ── loadPublicDiary ───────────────────────────────────────────────────────

  group('loadPublicDiary', () {
    test('carica solo diari pubblici per lo userId', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true,  trekkingName: 'A'));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true,  trekkingName: 'B'));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false, trekkingName: 'C'));

      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');

      expect(ctrl.allDiaries.length, 2);
      expect(ctrl.allDiaries.every((d) => d.isPublic), isTrue);
    });

    test('non carica diari di altri utenti', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u2', isPublic: true));
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');
      expect(ctrl.allDiaries, isEmpty);
    });

    test('nessun diario pubblico → lista invariata', () async {
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u99');
      expect(ctrl.allDiaries, isEmpty);
    });

    test('notifica i listener', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true));
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);
      await ctrl.loadPublicDiary('u1');
      expect(count, greaterThan(0));
    });

    test('i Diary caricati hanno i campi corretti', () async {
      await fakeDb.collection('diary').add(
            _diaryDoc(userId: 'u1', isPublic: true, trekkingName: 'Vetta', duration: 5.0, date: '2024-08-01'),
          );
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');
      final d = ctrl.allDiaries.first;
      expect(d.trekkigName, 'Vetta');
      expect(d.duration, 5.0);
      expect(d.date, '2024-08-01');
    });

    test('secondo caricamento ignorato grazie al flag _loaded', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true));
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');
      await ctrl.loadPublicDiary('u1'); // secondo call → ignorato
      expect(ctrl.allDiaries.length, 1); // non duplicato
    });
  });

  // ── loadPrivateDiary ──────────────────────────────────────────────────────

  group('loadPrivateDiary', () {
    test('carica solo diari privati per lo userId', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false, trekkingName: 'P1'));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false, trekkingName: 'P2'));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true,  trekkingName: 'PUB'));

      final ctrl = makeCtrl();
      await ctrl.loadPrivateDiary('u1');

      expect(ctrl.allDiaries.length, 2);
      expect(ctrl.allDiaries.every((d) => !d.isPublic), isTrue);
    });

    test('non carica diari di altri utenti', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u2', isPublic: false));
      final ctrl = makeCtrl();
      await ctrl.loadPrivateDiary('u1');
      expect(ctrl.allDiaries, isEmpty);
    });

    test('nessun diario privato → lista invariata', () async {
      final ctrl = makeCtrl();
      await ctrl.loadPrivateDiary('u99');
      expect(ctrl.allDiaries, isEmpty);
    });

    test('notifica i listener', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false));
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);
      await ctrl.loadPrivateDiary('u1');
      expect(count, greaterThan(0));
    });

    test('accumula diari pubblici e privati insieme', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false));
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');
      await ctrl.loadPrivateDiary('u1');
      expect(ctrl.allDiaries.length, 2);
    });
  });

  // ── getDiaryById ──────────────────────────────────────────────────────────

  group('getDiaryById', () {
    test('restituisce il diario corretto se presente in lista', () async {
      await fakeDb.collection('diary').doc('d1').set(_diaryDoc(userId: 'u1', trekkingName: 'Target'));
      final ctrl = makeCtrl();
      await ctrl.loadPublicDiary('u1');
      final d = ctrl.getDiaryById('d1');
      expect(d, isNotNull);
      expect(d!.trekkigName, 'Target');
    });

    test('restituisce null se id non trovato', () {
      expect(makeCtrl().getDiaryById('nonexistent'), isNull);
    });

    test('restituisce null su lista vuota', () {
      expect(makeCtrl().getDiaryById('anything'), isNull);
    });
  });

  // ── fetchDiaryById ────────────────────────────────────────────────────────

  group('fetchDiaryById', () {
    test('restituisce lista di diari per userId', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: true));
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u1', isPublic: false));
      final result = await makeCtrl().fetchDiaryById('u1');
      expect(result, isNotNull);
      expect(result!.length, 2);
    });

    test('restituisce null se nessun diario trovato', () async {
      expect(await makeCtrl().fetchDiaryById('u_none'), isNull);
    });

    test('non restituisce diari di altri utenti', () async {
      await fakeDb.collection('diary').add(_diaryDoc(userId: 'u2', isPublic: true));
      expect(await makeCtrl().fetchDiaryById('u1'), isNull);
    });

    test('i Diary restituiti hanno diaryId valorizzato', () async {
      await fakeDb.collection('diary').doc('myId').set(_diaryDoc(userId: 'u1', isPublic: true));
      final result = await makeCtrl().fetchDiaryById('u1');
      expect(result!.first.diaryId, 'myId');
    });

    test('gestisce diari con challenges come lista', () async {
      await fakeDb.collection('diary').add(
            _diaryDoc(userId: 'u1', isPublic: true, challenges: ['c1', 'c2']),
          );
      final result = await makeCtrl().fetchDiaryById('u1');
      expect(result!.first.challenges, containsAll(['c1', 'c2']));
    });
  });
}
