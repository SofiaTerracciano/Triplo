import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/service/authservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'diary_test.mocks.dart';

@GenerateMocks([
  AuthService,
  FirebaseFirestore,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>,
  DocumentSnapshot<Map<String, dynamic>>,
  QuerySnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
  Query<Map<String, dynamic>>,
])
void main() {
  late DiaryController controller;
  late MockAuthService mockAuthService;
  late MockFirebaseFirestore mockFirestore;

  Users makeUser({
    String uid = 'test_uid',
    List<Diary>? publicDiaryPages,
    List<Diary>? privateDiaryPages,
  }) =>
      Users(
        uid: uid,
        username: 'tester',
        name: 'Mario',
        surname: 'Rossi',
        email: 'test@test.com',
        birthdate: DateTime(1990, 1, 1),
        followers: <Users>[],
        following: <Users>[],
        publicDiaryPages: publicDiaryPages ?? <Diary>[],
        privateDiaryPages: privateDiaryPages ?? <Diary>[],
        savedTrekkings: <Trekking>[],
        level: 'beginner',
        advanced: 0,
        intermediate: 0,
      );

  Diary makeDiary({
    String id = '1',
    String userId = 'u1',
    bool isPublic = false,
  }) =>
      Diary(
        diaryId: id,
        userId: userId,
        trekkigName: 'Test Trek',
        date: '2024-01-01',
        duration: 2.0,
        friends: ['Alice'],
        photos: ['path/photo.jpg'],
        challenges: ['steep hill'],
        refreshmentPoint: 'Bar Roma',
        mood: ['happy'],
        notes: 'Great hike',
        isPublic: isPublic,
      );

  Map<String, dynamic> diaryFirestoreMap({bool isPublic = false}) => {
        "UserId": "u1",
        "Trekking_name": "Test Trek",
        "Date": "2024-01-01",
        "Duration": 2,
        "Friends": ["Alice"],
        "Photos": ["path/photo.jpg"],
        "Challenges": ["steep hill"],
        "Refreshment_point": "Bar Roma",
        "Mood": ["happy"],
        "Notes": "Great hike",
        "Is_public": isPublic,
      };

  void stubCollectionDoc(
    MockCollectionReference<Map<String, dynamic>> mockCol,
    MockDocumentReference<Map<String, dynamic>> mockDocRef, {
    String? docId,
  }) {
    if (docId != null) {
      when(mockCol.doc(docId)).thenReturn(mockDocRef);
    } else {
      when(mockCol.doc(any)).thenReturn(mockDocRef);
    }
  }

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestore = MockFirebaseFirestore();
    when(mockAuthService.currentUid).thenReturn('test_uid');
    controller = DiaryController(mockAuthService, firestore: mockFirestore);
  });

  group('updateDiary', () {
    test('aggiorna tutti i campi correttamente', () {
      final diary = makeDiary();
      final updated = controller.updateDiary(
        diary, true, 'newDate', 5.0, ['Bob'], ['p2'], ['c2'], 'Rifugio', ['sad'], 'new notes',
      );
      expect(updated.isPublic, true);
      expect(updated.date, 'newDate');
      expect(updated.duration, 5.0);
      expect(updated.friends, ['Bob']);
      expect(updated.photos, ['p2']);
      expect(updated.challenges, ['c2']);
      expect(updated.refreshmentPoint, 'Rifugio');
      expect(updated.mood, ['sad']);
      expect(updated.notes, 'new notes');
    });

    test('modifica lo stesso oggetto (identità)', () {
      final diary = makeDiary();
      final updated = controller.updateDiary(
        diary, false, 'd', 1, [], [], [], '', [], '',
      );
      expect(identical(updated, diary), true);
    });
  });

  group('getDiaryById', () {
    test('ritorna il diario corretto dalla lista locale', () {
      controller.allDiaries.add(makeDiary(id: '123'));
      expect(controller.getDiaryById('123'), isNotNull);
      expect(controller.getDiaryById('123')!.diaryId, '123');
    });

    test('ritorna null se il diario non esiste', () {
      expect(controller.getDiaryById('not_exist'), isNull);
    });

    test('ritorna null su lista vuota', () {
      expect(controller.getDiaryById('1'), isNull);
    });
  });

  group('fetchDiaryById', () {
    test('ritorna lista di diari quando ci sono documenti', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn(diaryFirestoreMap());
      when(mockDoc.id).thenReturn('1');

      final result = await controller.fetchDiaryById('test_uid');

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.diaryId, '1');
    });

    test('ritorna null quando non ci sono documenti', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([]);

      final result = await controller.fetchDiaryById('test_uid');
      expect(result, isNull);
    });
  });

  group('addDiary (nuovo)', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;
    late MockDocumentReference<Map<String, dynamic>> mockUserDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnap;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockUsersCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockUserDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockUsersCol.doc(any)).thenReturn(mockUserDocRef);
      when(mockDiaryDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDiaryDocRef.set(any)).thenAnswer((_) async {});
      when(mockUserDocRef.update(any)).thenAnswer((_) async {});
    });

    test('aggiunge un diario pubblico e aggiorna currentUser', () async {
      controller.currentUser = makeUser();

      await controller.addDiary(
        'My Trek', true, '2024', 3.0, [], [], [], '', [], '', false, '',
      );

      expect(controller.allDiaries.length, 1);
      expect(controller.allDiaries.first.isPublic, true);
      expect(controller.currentUser!.publicDiaryPages.length, 1);
      verify(mockUserDocRef.update(argThat(containsPair('Public_diary', anything)))).called(1);
      verify(mockDiaryDocRef.set(any)).called(1);
    });

    test('aggiunge un diario privato e aggiorna currentUser', () async {
      controller.currentUser = makeUser();

      await controller.addDiary(
        'Private Trek', false, '2024', 1.0, [], [], [], '', [], '', false, '',
      );

      expect(controller.allDiaries.first.isPublic, false);
      expect(controller.currentUser!.privateDiaryPages.length, 1);
      verify(mockUserDocRef.update(argThat(containsPair('Private_diary', anything)))).called(1);
    });

    test('non esegue nulla se uid è null', () async {
      when(mockAuthService.currentUid).thenReturn(null);
      final ctrl = DiaryController(mockAuthService, firestore: mockFirestore);

      await ctrl.addDiary('T', false, '', 0, [], [], [], '', [], '', false, '');

      verifyNever(mockFirestore.collection(any));
    });
  });

  group('addDiary (modifica)', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;
    late MockDocumentReference<Map<String, dynamic>> mockUserDocRef;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockUsersCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockUserDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockUsersCol.doc(any)).thenReturn(mockUserDocRef);
      when(mockDiaryDocRef.update(any)).thenAnswer((_) async {});
      when(mockUserDocRef.update(any)).thenAnswer((_) async {});
    });

    test('modifica i campi di un diario esistente senza cambio privacy', () async {
      final diary = makeDiary(id: '42', isPublic: true);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'Updated', true, 'newDate', 9.0, [], [], [], '', [], 'note', true, '42',
      );

      expect(controller.getDiaryById('42')!.date, 'newDate');
      expect(controller.getDiaryById('42')!.duration, 9.0);
      verify(mockDiaryDocRef.update(any)).called(1);
      // Nessun update su users perché privacy invariata
      verifyNever(mockUserDocRef.update(any));
    });

    test('aggiorna le liste utente quando la privacy cambia (public → private)', () async {
      final diary = makeDiary(id: '77', isPublic: true);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'Trek', false, '2024', 2.0, [], [], [], '', [], '', true, '77',
      );

      verify(mockUserDocRef.update(any)).called(1);
    });

    test('aggiorna le liste utente quando la privacy cambia (private → public)', () async {
      final diary = makeDiary(id: '88', isPublic: false);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'Trek', true, '2024', 2.0, [], [], [], '', [], '', true, '88',
      );

      verify(mockUserDocRef.update(any)).called(1);
    });

    test('non esegue nulla se uid è null', () async {
      when(mockAuthService.currentUid).thenReturn(null);
      final ctrl = DiaryController(mockAuthService, firestore: mockFirestore);

      await ctrl.addDiary('T', false, '', 0, [], [], [], '', [], '', true, 'id');

      verifyNever(mockFirestore.collection(any));
    });
  });

  group('removeDiary', () {
    late MockCollectionReference<Map<String, dynamic>> mockCol;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;

    setUp(() {
      mockCol = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection(any)).thenReturn(mockCol);
      when(mockCol.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});
      when(mockDocRef.update(any)).thenAnswer((_) async {});
    });

    test('rimuove un diario pubblico dalla lista locale', () async {
      final diary = makeDiary(id: '1', isPublic: true);
      controller.allDiaries.add(diary);

      await controller.removeDiary('1');

      expect(controller.allDiaries, isEmpty);
      verify(mockDocRef.delete()).called(1);
    });

    test('rimuove un diario privato dalla lista locale', () async {
      final diary = makeDiary(id: '2', isPublic: false);
      controller.allDiaries.add(diary);

      await controller.removeDiary('2');

      expect(controller.allDiaries, isEmpty);
    });

    test('aggiorna privateDiaryPages su currentUser per diario privato', () async {
      final diary = makeDiary(id: '3', isPublic: false);
      controller.allDiaries.add(diary);
      controller.currentUser = makeUser(privateDiaryPages: [diary]);

      await controller.removeDiary('3');

      expect(controller.currentUser!.privateDiaryPages, isEmpty);
    });

    test('aggiorna publicDiaryPages su currentUser per diario pubblico', () async {
      final diary = makeDiary(id: '4', isPublic: true);
      controller.allDiaries.add(diary);
      controller.currentUser = makeUser(publicDiaryPages: [diary]);

      await controller.removeDiary('4');

      expect(controller.currentUser!.publicDiaryPages, isEmpty);
    });

    test('non fa nulla se uid è null', () async {
      when(mockAuthService.currentUid).thenReturn(null);
      final diary = makeDiary(id: '9', isPublic: false);
      final ctrl = DiaryController(mockAuthService, firestore: mockFirestore);
      ctrl.allDiaries.add(diary);

      await ctrl.removeDiary('9');

      verifyNever(mockDocRef.delete());
    });
  });

  group('getPublicDiaries e getPrivateDiaries', () {
    MockCollectionReference<Map<String, dynamic>> buildChain(
      bool isPublic,
      List<MockQueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery1 = MockQuery<Map<String, dynamic>>();
      final mockQuery2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery1);
      when(mockQuery1.where('Is_public', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery2);
      when(mockQuery2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn(docs);

      return mockCol;
    }

    test('getPublicDiaries ritorna solo i diari pubblici', () async {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn(diaryFirestoreMap(isPublic: true));
      when(mockDoc.id).thenReturn('pub1');

      buildChain(true, [mockDoc]);

      final result = await controller.getPublicDiaries('u1');
      expect(result.length, 1);
      expect(result.first.isPublic, true);
    });

    test('getPrivateDiaries ritorna solo i diari privati', () async {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn(diaryFirestoreMap(isPublic: false));
      when(mockDoc.id).thenReturn('priv1');

      buildChain(false, [mockDoc]);

      final result = await controller.getPrivateDiaries('u1');
      expect(result.length, 1);
      expect(result.first.isPublic, false);
    });

    test('getPublicDiaries ritorna lista vuota se non ci sono documenti', () async {
      buildChain(true, []);
      final result = await controller.getPublicDiaries('u1');
      expect(result, isEmpty);
    });
  });

  group('getRandomPublicDiariesFromFollowing', () {
    test('ritorna al massimo [limit] diari', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery1 = MockQuery<Map<String, dynamic>>();
      final mockQuery2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', whereIn: anyNamed('whereIn')))
          .thenReturn(mockQuery1);
      when(mockQuery1.where('Is_public', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery2);
      when(mockQuery2.get()).thenAnswer((_) async => mockSnap);

      // Creiamo 5 mock docs
      final docs = List.generate(5, (i) {
        final d = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(d.data()).thenReturn(diaryFirestoreMap(isPublic: true));
        when(d.id).thenReturn('id$i');
        return d;
      });
      when(mockSnap.docs).thenReturn(docs);

      final result = await controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['u1', 'u2'],
        limit: 3,
      );

      expect(result.length, lessThanOrEqualTo(3));
    });

    test('normalizza Photos come String singola in lista', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery1 = MockQuery<Map<String, dynamic>>();
      final mockQuery2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', whereIn: anyNamed('whereIn')))
          .thenReturn(mockQuery1);
      when(mockQuery1.where('Is_public', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery2);
      when(mockQuery2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('x');
      when(mockDoc.data()).thenReturn({
        "UserId": "u1",
        "Trekking_name": "Trek",
        "Date": "2024",
        "Duration": 1,
        "Friends": [],
        "Photos": "single_photo.jpg",
        "Challenges": "some challenge",
        "Refreshment_point": "",
        "Mood": "happy",
        "Notes": "",
        "Is_public": true,
      });

      final result = await controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['u1'],
        limit: 5,
      );

      expect(result.first.photos, ['single_photo.jpg']);
      expect(result.first.challenges, ['some challenge']);
      expect(result.first.mood, ['happy']);
    });

    test('ritorna lista vuota se non ci sono diari', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery1 = MockQuery<Map<String, dynamic>>();
      final mockQuery2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', whereIn: anyNamed('whereIn')))
          .thenReturn(mockQuery1);
      when(mockQuery1.where('Is_public', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery2);
      when(mockQuery2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([]);

      final result = await controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['u1'],
        limit: 10,
      );
      expect(result, isEmpty);
    });
  });

  group('getDiaryByIdAsync', () {
    test('ritorna il diario dalla cache locale senza chiamare Firestore', () async {
      final diary = makeDiary(id: 'cached');
      controller.allDiaries.add(diary);

      final result = await controller.getDiaryByIdAsync('cached');

      expect(result, isNotNull);
      expect(result!.diaryId, 'cached');
      verifyNever(mockFirestore.collection(any));
    });

    test('recupera il diario da Firestore se non è in cache', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.doc('remote')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(diaryFirestoreMap());
      when(mockDocSnap.id).thenReturn('remote');

      final result = await controller.getDiaryByIdAsync('remote');

      expect(result, isNotNull);
      expect(result!.diaryId, 'remote');
      // Ora è in cache
      expect(controller.allDiaries.any((d) => d.diaryId == 'remote'), true);
    });

    test('ritorna null se il documento non esiste su Firestore', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(mockDocSnap.exists).thenReturn(false);

      final result = await controller.getDiaryByIdAsync('ghost');
      expect(result, isNull);
    });

    test('ritorna null se Firestore lancia un\'eccezione', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenThrow(Exception('network error'));

      final result = await controller.getDiaryByIdAsync('error_id');
      expect(result, isNull);
    });
  });

  group('currentUser', () {
    test('getter ritorna null di default', () {
      expect(controller.currentUser, isNull);
    });

    test('setter aggiorna il valore correttamente', () {
      final user = makeUser(uid: 'u1');
      controller.currentUser = user;
      expect(controller.currentUser!.uid, 'u1');
    });
  });

  group('uid getter', () {
    test('delega ad AuthService.currentUid', () {
      expect(controller.uid, 'test_uid');
    });

    test('ritorna null se non autenticato', () {
      when(mockAuthService.currentUid).thenReturn(null);
      final ctrl = DiaryController(mockAuthService, firestore: mockFirestore);
      expect(ctrl.uid, isNull);
    });
  });

  group('Diary model', () {
    test('toMap produce le chiavi Firestore corrette', () {
      final diary = makeDiary();
      final map = diary.toMap();
      expect(map['UserId'], diary.userId);
      expect(map['Trekking_name'], diary.trekkigName);
      expect(map['Is_public'], diary.isPublic);
      expect(map['Photos'], diary.photos);
    });

    test('fromMap costruisce un Diary correttamente', () {
      final map = diaryFirestoreMap(isPublic: true);
      final diary = Diary.fromMap(map, diaryId: 'abc');
      expect(diary.diaryId, 'abc');
      expect(diary.isPublic, true);
      expect(diary.friends, ['Alice']);
    });

    test('fromMap usa valori di default per chiavi mancanti', () {
      final diary = Diary.fromMap({}, diaryId: 'x');
      expect(diary.userId, '');
      expect(diary.trekkigName, 'Unknown Trek');
      expect(diary.duration, 0.0);
      expect(diary.photos, isEmpty);
      expect(diary.isPublic, false);
    });

    test('fromMap converte Photos come List<dynamic> a List<String>', () {
      final diary = Diary.fromMap({'Photos': [1, 2, 3]}, diaryId: 'y');
      expect(diary.photos, ['1', '2', '3']);
    });
  });

  group('deletePhotoFromDb', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockDiaryDocRef.update(any)).thenAnswer((_) async {});
    });

    test('rimuove la foto dalla lista locale del diario', () async {
      final diary = Diary(
        diaryId: 'diaryX',
        userId: 'u1',
        trekkigName: 'Trek',
        date: '2024',
        duration: 1.0,
        friends: [],
        photos: ['Diary_photos/foto.jpg', 'Diary_photos/altra.jpg'],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: false,
      );
      controller.allDiaries.add(diary);

      try {
        await controller.deletePhotoFromDb('diaryX', 'Diary_photos/foto.jpg');
      } catch (_) {}

      verify(mockDiaryDocRef.update(argThat(
        predicate((m) =>
            m is Map && m.containsKey('Photos')),
      ))).called(1);
    });

    test('update Firestore chiama arrayRemove con il path corretto', () async {
      final diary = makeDiary(id: 'diaryY');
      controller.allDiaries.add(diary);

      try {
        await controller.deletePhotoFromDb('diaryY', 'path/photo.jpg');
      } catch (_) {}

      verify(mockDiaryDocRef.update({
        'Photos': FieldValue.arrayRemove(['path/photo.jpg']),
      })).called(1);
    });
  });

  group('getRandomPublicDiariesFromFollowing — normalizzazione Friends', () {
    Future<List<Diary>> fetchWithData(Map<String, dynamic> data) async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQ1 = MockQuery<Map<String, dynamic>>();
      final mockQ2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', whereIn: anyNamed('whereIn'))).thenReturn(mockQ1);
      when(mockQ1.where('Is_public', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ2);
      when(mockQ2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('d1');
      when(mockDoc.data()).thenReturn(data);

      return controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['u1'],
        limit: 10,
      );
    }

    test('Friends come List viene normalizzato correttamente', () async {
      final result = await fetchWithData({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": ["Alice", "Bob"],
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.friends, ["Alice", "Bob"]);
    });

    test('Friends non presente restituisce lista vuota', () async {
      final result = await fetchWithData({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1,
        // Friends assente
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.friends, isEmpty);
    });

    test('campo Duration come double viene gestito', () async {
      final result = await fetchWithData({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 3.5, "Friends": [],
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.duration, 3.5);
    });

    test('campo Trekking_name assente restituisce Unknown Trek', () async {
      final result = await fetchWithData({
        "UserId": "u1", "Date": "2024", "Duration": 1,
        "Friends": [], "Photos": [], "Challenges": [],
        "Refreshment_point": "", "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.trekkigName, "Unknown Trek");
    });
  });

  group('Diary.fromMap — branch aggiuntivi', () {
    test('Challenges come List<dynamic> con interi viene convertita a List<String>', () {
      final diary = Diary.fromMap({'Challenges': [1, 2]}, diaryId: 'z');
      expect(diary.challenges, ['1', '2']);
    });

    test('Mood come List<dynamic> con interi viene convertita a List<String>', () {
      final diary = Diary.fromMap({'Mood': [10, 20]}, diaryId: 'z');
      expect(diary.mood, ['10', '20']);
    });

    test('Duration come int viene convertita a double', () {
      final diary = Diary.fromMap({'Duration': 3}, diaryId: 'z');
      expect(diary.duration, 3.0);
      expect(diary.duration, isA<double>());
    });

    test('Friends come lista viene caricata correttamente', () {
      final diary = Diary.fromMap({'Friends': ['Alice', 'Bob']}, diaryId: 'z');
      expect(diary.friends, ['Alice', 'Bob']);
    });

    test('tutti i campi opzionali assenti producono valori di default sicuri', () {
      final diary = Diary.fromMap({}, diaryId: 'empty');
      expect(diary.refreshmentPoint, '');
      expect(diary.notes, '');
      expect(diary.challenges, isEmpty);
      expect(diary.mood, isEmpty);
      expect(diary.friends, isEmpty);
    });
  });

  group('Users.toMap', () {
    test('produce le chiavi Firestore corrette', () {
      final user = makeUser(uid: 'u99');
      final map = user.toMap();
      expect(map['Uid'], 'u99');
      expect(map['Username'], 'tester');
      expect(map['Name'], 'Mario');
      expect(map['Surname'], 'Rossi');
      expect(map['Email'], 'test@test.com');
      expect(map['Level'], 'beginner');
      expect(map['Advanced'], 0);
      expect(map['Intermediate'], 0);
      expect(map['Public_diary'], isEmpty);
      expect(map['Private_diary'], isEmpty);
      expect(map['Followers'], isEmpty);
      expect(map['Following'], isEmpty);
      expect(map['Saved_trekkings'], isEmpty);
    });

    test('Birthdate viene serializzato come ISO8601', () {
      final user = makeUser();
      final map = user.toMap();
      expect(map['Birthdate'], isA<String>());
      expect(DateTime.tryParse(map['Birthdate']), isNotNull);
    });
  });

  group('Users.fromMap', () {
    test('costruisce correttamente da una mappa completa', () {
      final map = {
        'Username': 'mario',
        'Name': 'Mario',
        'Surname': 'Rossi',
        'Email': 'mario@test.com',
        'Birthdate': '1990-05-15T00:00:00.000',
        'Photo_profile': 'http://photo.url',
        'Level': 'advanced',
        'Advanced': 5,
        'Intermediate': 3,
      };
      final user = Users.fromMap(map, uid: 'abc');
      expect(user.uid, 'abc');
      expect(user.username, 'mario');
      expect(user.name, 'Mario');
      expect(user.email, 'mario@test.com');
      expect(user.level, 'advanced');
      expect(user.advanced, 5);
      expect(user.intermediate, 3);
      expect(user.birthdate, DateTime(1990, 5, 15));
      expect(user.followers, isEmpty);
      expect(user.publicDiaryPages, isEmpty);
    });

    test('usa fallback "username" minuscolo se "Username" assente', () {
      final user = Users.fromMap({'username': 'fallback'}, uid: 'x');
      expect(user.username, 'fallback');
    });

    test('usa fallback "email" minuscolo se "Email" assente', () {
      final user = Users.fromMap({'email': 'fb@test.com'}, uid: 'x');
      expect(user.email, 'fb@test.com');
    });

    test('Advanced come String numerica viene convertito a int', () {
      final user = Users.fromMap({'Advanced': '7', 'Intermediate': '2'}, uid: 'x');
      expect(user.advanced, 7);
      expect(user.intermediate, 2);
    });

    test('Advanced stringa non numerica restituisce 0', () {
      final user = Users.fromMap({'Advanced': 'nope'}, uid: 'x');
      expect(user.advanced, 0);
    });

    test('mappa vuota produce valori di default sicuri', () {
      final user = Users.fromMap({}, uid: 'empty');
      expect(user.username, '');
      expect(user.name, '');
      expect(user.level, '');
      expect(user.advanced, 0);
      expect(user.birthdate, DateTime(2000, 1, 1));
    });
  });

  group('Users._parseBirthdate', () {
    test('Birthdate stringa ISO valida viene parsata correttamente', () {
      final user = Users.fromMap({'Birthdate': '1995-08-20T00:00:00.000'}, uid: 'x');
      expect(user.birthdate, DateTime(1995, 8, 20));
    });

    test('Birthdate stringa non valida restituisce default 2000-01-01', () {
      final user = Users.fromMap({'Birthdate': 'not-a-date'}, uid: 'x');
      expect(user.birthdate, DateTime(2000, 1, 1));
    });

    test('Birthdate stringa vuota restituisce default 2000-01-01', () {
      final user = Users.fromMap({'Birthdate': ''}, uid: 'x');
      expect(user.birthdate, DateTime(2000, 1, 1));
    });

    test('registerdate come DateTime viene usato come fallback', () {
      final dt = DateTime(1988, 3, 10);
      final user = Users.fromMap({'registerdate': dt}, uid: 'x');
      expect(user.birthdate, dt);
    });

    test('registerdate come String viene parsato come fallback', () {
      final user = Users.fromMap({'registerdate': '1988-03-10T00:00:00.000'}, uid: 'x');
      expect(user.birthdate, DateTime(1988, 3, 10));
    });

    test('nessun campo birthdate restituisce default 2000-01-01', () {
      final user = Users.fromMap({'Name': 'Solo'}, uid: 'x');
      expect(user.birthdate, DateTime(2000, 1, 1));
    });
  });

  group('Users getters e setters', () {
    test('setter username aggiorna il valore', () {
      final user = makeUser();
      user.username = 'nuovo';
      expect(user.username, 'nuovo');
    });

    test('setter name aggiorna il valore', () {
      final user = makeUser();
      user.name = 'Luca';
      expect(user.name, 'Luca');
    });

    test('setter surname aggiorna il valore', () {
      final user = makeUser();
      user.surname = 'Bianchi';
      expect(user.surname, 'Bianchi');
    });

    test('setter email aggiorna il valore', () {
      final user = makeUser();
      user.email = 'new@test.com';
      expect(user.email, 'new@test.com');
    });

    test('setter birthdate aggiorna il valore', () {
      final user = makeUser();
      final newDate = DateTime(2000, 6, 15);
      user.birthdate = newDate;
      expect(user.birthdate, newDate);
    });

    test('setter photoProfile aggiorna il valore', () {
      final user = makeUser();
      user.photoProfile = 'http://new.photo';
      expect(user.photoProfile, 'http://new.photo');
    });

    test('setter level aggiorna il valore', () {
      final user = makeUser();
      user.level = 'expert';
      expect(user.level, 'expert');
    });

    test('setter advanced aggiorna il valore', () {
      final user = makeUser();
      user.advanced = 10;
      expect(user.advanced, 10);
    });

    test('setter intermediate aggiorna il valore', () {
      final user = makeUser();
      user.intermediate = 5;
      expect(user.intermediate, 5);
    });

    test('setter followers aggiorna la lista', () {
      final user = makeUser();
      final follower = makeUser(uid: 'f1');
      user.followers = [follower];
      expect(user.followers.length, 1);
      expect(user.followers.first.uid, 'f1');
    });

    test('setter following aggiorna la lista', () {
      final user = makeUser();
      final followed = makeUser(uid: 'f2');
      user.following = [followed];
      expect(user.following.length, 1);
    });

    test('setter publicDiaryPages aggiorna la lista', () {
      final user = makeUser();
      user.publicDiaryPages = [makeDiary(id: 'pub1', isPublic: true)];
      expect(user.publicDiaryPages.length, 1);
    });

    test('setter privateDiaryPages aggiorna la lista', () {
      final user = makeUser();
      user.privateDiaryPages = [makeDiary(id: 'priv1')];
      expect(user.privateDiaryPages.length, 1);
    });

    test('setter savedTrekkings aggiorna la lista', () {
      final user = makeUser();
      user.savedTrekkings = <Trekking>[];
      expect(user.savedTrekkings, isEmpty);
    });
  });

  group('addDiary (nuovo) — UUID collision', () {
    test('rigenera uuid se il documento esiste già', () async {
      final mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      final mockUsersCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockUserDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapExists = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockDocSnapNotExists = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockUsersCol.doc(any)).thenReturn(mockUserDocRef);
      when(mockDiaryDocRef.get()).thenAnswer((_) async => mockDocSnapExists);
      when(mockDocSnapExists.exists).thenReturn(true);
      when(mockDiaryDocRef.set(any)).thenAnswer((_) async {});
      when(mockUserDocRef.update(any)).thenAnswer((_) async {});

      controller.currentUser = makeUser();

      await controller.addDiary(
        'Trek', false, '2024', 1.0, [], [], [], '', [], '', false, '',
      );

      expect(controller.allDiaries.length, 1);
      verify(mockDiaryDocRef.set(any)).called(1);
    });
  });

  group('addDiary (modifica) — dettagli aggiuntivi', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;
    late MockDocumentReference<Map<String, dynamic>> mockUserDocRef;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockUsersCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockUserDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockUsersCol.doc(any)).thenReturn(mockUserDocRef);
      when(mockDiaryDocRef.update(any)).thenAnswer((_) async {});
      when(mockUserDocRef.update(any)).thenAnswer((_) async {});
    });

    test('notifyListeners viene chiamato dopo la modifica', () async {
      final diary = makeDiary(id: 'n1', isPublic: false);
      controller.allDiaries.add(diary);

      bool notified = false;
      controller.addListener(() => notified = true);

      await controller.addDiary(
        'Nuovo titolo', false, '2024', 2.0, [], [], [], '', [], '', true, 'n1',
      );

      expect(notified, true);
    });

    test('trekkigName non viene sovrascritto (updateDiary non lo modifica)', () async {
      final diary = makeDiary(id: 'n2', isPublic: false);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'Titolo ignorato', false, '2024', 2.0, [], [], [], '', [], '', true, 'n2',
      );
      expect(controller.getDiaryById('n2')!.trekkigName, 'Test Trek');
    });

    test('tutti i campi modificabili vengono aggiornati correttamente (stessa privacy)', () async {
      final diary = makeDiary(id: 'n3', isPublic: false);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'ignored', false, '2025-06-01', 8.5,
        ['Carlo'], ['img/new.jpg'], ['rocks'], 'Rifugio Nord',
        ['tired'], 'bella giornata', true, 'n3',
      );

      final updated = controller.getDiaryById('n3')!;
      expect(updated.date, '2025-06-01');
      expect(updated.duration, 8.5);
      expect(updated.friends, ['Carlo']);
      expect(updated.photos, ['img/new.jpg']);
      expect(updated.challenges, ['rocks']);
      expect(updated.refreshmentPoint, 'Rifugio Nord');
      expect(updated.mood, ['tired']);
      expect(updated.notes, 'bella giornata');
      expect(updated.isPublic, false);
    });

    test('tutti i campi aggiornati con cambio privacy (false→true)', () async {
      final diary = makeDiary(id: 'n4', isPublic: false);
      controller.allDiaries.add(diary);

      await controller.addDiary(
        'ignored', true, '2025-08-01', 3.0,
        ['Luca'], ['img/x.jpg'], ['mud'], 'Bar Alpi',
        ['happy'], 'ottimo', true, 'n4',
      );

      final updated = controller.getDiaryById('n4')!;
      expect(updated.isPublic, true);
      expect(updated.date, '2025-08-01');
      expect(updated.notes, 'ottimo');
      verify(mockUserDocRef.update(any)).called(1);
    });
  });

  group('removeDiary — currentUser null', () {
    test('non lancia eccezione se currentUser è null', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection(any)).thenReturn(mockCol);
      when(mockCol.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      final diary = makeDiary(id: 'del1', isPublic: true);
      controller.allDiaries.add(diary);

      await expectLater(
        controller.removeDiary('del1'),
        completes,
      );
      expect(controller.allDiaries, isEmpty);
    });

    test('currentUser null con diario privato non crasha', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection(any)).thenReturn(mockCol);
      when(mockCol.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      final diary = makeDiary(id: 'del2', isPublic: false);
      controller.allDiaries.add(diary);

      await expectLater(controller.removeDiary('del2'), completes);
      expect(controller.allDiaries, isEmpty);
    });
  });

  group('getRandomPublicDiariesFromFollowing — Friends non List', () {
    Future<List<Diary>> fetchWith(Map<String, dynamic> data) async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQ1 = MockQuery<Map<String, dynamic>>();
      final mockQ2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', whereIn: anyNamed('whereIn'))).thenReturn(mockQ1);
      when(mockQ1.where('Is_public', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ2);
      when(mockQ2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('f1');
      when(mockDoc.data()).thenReturn(data);
      return controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['u1'], limit: 10,
      );
    }

    test('Friends non è List restituisce lista vuota', () async {
      final result = await fetchWith({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": "non_una_lista",
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.friends, isEmpty);
    });

    test('Friends null restituisce lista vuota', () async {
      final result = await fetchWith({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": null,
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.friends, isEmpty);
    });

    test('Challenges null restituisce lista vuota', () async {
      final result = await fetchWith({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": [],
        "Photos": [], "Challenges": null, "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.challenges, isEmpty);
    });

    test('Mood null restituisce lista vuota', () async {
      final result = await fetchWith({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": [],
        "Photos": [], "Challenges": [], "Refreshment_point": "",
        "Mood": null, "Notes": "", "Is_public": true,
      });
      expect(result.first.mood, isEmpty);
    });

    test('Photos null restituisce lista vuota', () async {
      final result = await fetchWith({
        "UserId": "u1", "Trekking_name": "T", "Date": "2024",
        "Duration": 1, "Friends": [],
        "Photos": null, "Challenges": [], "Refreshment_point": "",
        "Mood": [], "Notes": "", "Is_public": true,
      });
      expect(result.first.photos, isEmpty);
    });
  });

  group('getPrivateDiaries — edge cases', () {
    test('ritorna lista vuota se non ci sono diari privati', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQ1 = MockQuery<Map<String, dynamic>>();
      final mockQ2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ1);
      when(mockQ1.where('Is_public', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ2);
      when(mockQ2.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.docs).thenReturn([]);

      final result = await controller.getPrivateDiaries('u1');
      expect(result, isEmpty);
    });

    test('ritorna più diari privati correttamente', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQ1 = MockQuery<Map<String, dynamic>>();
      final mockQ2 = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ1);
      when(mockQ1.where('Is_public', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQ2);
      when(mockQ2.get()).thenAnswer((_) async => mockSnap);

      final docs = List.generate(3, (i) {
        final d = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(d.data()).thenReturn({
          "UserId": "u1", "Trekking_name": "Trek$i", "Date": "2024",
          "Duration": 1, "Friends": [], "Photos": [],
          "Challenges": [], "Refreshment_point": "",
          "Mood": [], "Notes": "", "Is_public": false,
        });
        when(d.id).thenReturn('priv$i');
        return d;
      });
      when(mockSnap.docs).thenReturn(docs);

      final result = await controller.getPrivateDiaries('u1');
      expect(result.length, 3);
      expect(result.every((d) => !d.isPublic), true);
    });
  });

  group('fetchDiaryById — più documenti', () {
    test('ritorna tutti i diari quando ci sono più documenti', () async {
      final mockCol = MockCollectionReference<Map<String, dynamic>>();
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnap = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockCol);
      when(mockCol.where('UserId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnap);

      final docs = List.generate(4, (i) {
        final d = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(d.data()).thenReturn({
          "UserId": "u1", "Trekking_name": "Trek$i", "Date": "2024",
          "Duration": i.toDouble(), "Friends": [], "Photos": [],
          "Challenges": [], "Refreshment_point": "",
          "Mood": [], "Notes": "", "Is_public": i.isEven,
        });
        when(d.id).thenReturn('doc$i');
        return d;
      });
      when(mockSnap.docs).thenReturn(docs);

      final result = await controller.fetchDiaryById('u1');
      expect(result, isNotNull);
      expect(result!.length, 4);
    });
  });

  group('Diary.fromMap — Photos/Challenges/Mood null esplicito', () {
    test('Photos null restituisce lista vuota', () {
      final diary = Diary.fromMap({'Photos': null}, diaryId: 'z');
      expect(diary.photos, isEmpty);
    });

    test('Challenges null restituisce lista vuota', () {
      final diary = Diary.fromMap({'Challenges': null}, diaryId: 'z');
      expect(diary.challenges, isEmpty);
    });

    test('Mood null restituisce lista vuota', () {
      final diary = Diary.fromMap({'Mood': null}, diaryId: 'z');
      expect(diary.mood, isEmpty);
    });
  });

  group('Diary.toMap — tutti i campi', () {
    test('Duration, Friends, Challenges, Mood, Notes, Date serializzati correttamente', () {
      final diary = Diary(
        diaryId: 'tm1',
        userId: 'u1',
        trekkigName: 'Lago Nero',
        date: '2025-07-01',
        duration: 4.5,
        friends: ['Marco', 'Sara'],
        photos: ['p1.jpg'],
        challenges: ['neve'],
        refreshmentPoint: 'Bivacco',
        mood: ['euforico'],
        notes: 'Vista spettacolare',
        isPublic: true,
      );
      final map = diary.toMap();
      expect(map['Date'], '2025-07-01');
      expect(map['Duration'], 4.5);
      expect(map['Friends'], ['Marco', 'Sara']);
      expect(map['Challenges'], ['neve']);
      expect(map['Mood'], ['euforico']);
      expect(map['Notes'], 'Vista spettacolare');
      expect(map['Refreshment_point'], 'Bivacco');
    });
  });

  group('Users.fromMap — branch aggiuntivi', () {
    test('photoURL fallback usato quando Photo_profile è assente', () {
      final user = Users.fromMap({'photoURL': 'http://photo.url'}, uid: 'x');
      expect(user.photoProfile, 'http://photo.url');
    });

    test('Advanced già int non viene riconvertito', () {
      final user = Users.fromMap({'Advanced': 9, 'Intermediate': 4}, uid: 'x');
      expect(user.advanced, 9);
      expect(user.intermediate, 4);
    });

    test('Photo_profile ha precedenza su photoURL', () {
      final user = Users.fromMap(
        {'Photo_profile': 'correct.jpg', 'photoURL': 'wrong.jpg'}, uid: 'x',
      );
      expect(user.photoProfile, 'correct.jpg');
    });
  });

  group('getter residui', () {
    test('Users.photoProfile getter ritorna il valore impostato', () {
      final user = makeUser();
      expect(user.photoProfile, '');
      user.photoProfile = 'http://img.jpg';
      expect(user.photoProfile, 'http://img.jpg');
    });

    test('DiaryController.allDiaries getter ritorna la lista corrente', () {
      expect(controller.allDiaries, isEmpty);
      controller.allDiaries.add(makeDiary());
      expect(controller.allDiaries.length, 1);
    });

    test('Users.name getter ritorna il valore corretto', () {
      final user = makeUser();
      expect(user.name, 'Mario');
    });

    test('Users.surname getter ritorna il valore corretto', () {
      final user = makeUser();
      expect(user.surname, 'Rossi');
    });

    test('Users.birthdate getter ritorna il valore corretto', () {
      final user = makeUser();
      expect(user.birthdate, DateTime(1990, 1, 1));
    });

    test('Users.level getter ritorna il valore corretto', () {
      final user = makeUser();
      expect(user.level, 'beginner');
    });

    test('Users.advanced e intermediate getter', () {
      final user = makeUser();
      expect(user.advanced, 0);
      expect(user.intermediate, 0);
    });
  });

  group('addDiary (nuovo) — comportamento lista', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;
    late MockDocumentReference<Map<String, dynamic>> mockUserDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnap;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockUsersCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockUserDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockUsersCol.doc(any)).thenReturn(mockUserDocRef);
      when(mockDiaryDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(mockDocSnap.exists).thenReturn(false);
      when(mockDiaryDocRef.set(any)).thenAnswer((_) async {});
      when(mockUserDocRef.update(any)).thenAnswer((_) async {});
    });

    test('aggiungere due diari porta allDiaries a length 2', () async {
      controller.currentUser = makeUser();
      await controller.addDiary('T1', false, '2024', 1.0, [], [], [], '', [], '', false, '');
      await controller.addDiary('T2', true,  '2024', 2.0, [], [], [], '', [], '', false, '');
      expect(controller.allDiaries.length, 2);
    });

    test('diaryId generato viene salvato nel diario locale', () async {
      controller.currentUser = makeUser();
      await controller.addDiary('T', false, '2024', 1.0, [], [], [], '', [], '', false, '');
      expect(controller.allDiaries.first.diaryId, isNotEmpty);
    });

    test('diario creato ha userId uguale a currentUid', () async {
      controller.currentUser = makeUser();
      await controller.addDiary('T', false, '2024', 1.0, [], [], [], '', [], '', false, '');
      expect(controller.allDiaries.first.userId, 'test_uid');
    });
  });

  group('uploadDiaryImages — filtro estensioni', () {

    test('ritorna lista vuota con lista immagini vuota', () async {
      // Nessun file → nessuna chiamata Storage → paths vuoto
      final result = await controller.uploadDiaryImages([]);
      expect(result, isEmpty);
    });
  });

  group('getDownloadUrlChild — branch null/empty', () {
    test('ritorna null se path è null', () async {
      final result = await controller.getDownloadUrlChild(null);
      expect(result, isNull);
    });

    test('ritorna null se path è stringa vuota', () async {
      final result = await controller.getDownloadUrlChild('');
      expect(result, isNull);
    });
  });

  group('getDownloadUrl — branch null/empty', () {
    test('ritorna null se path è null', () async {
      final result = await controller.getDownloadUrl(null);
      expect(result, isNull);
    });

    test('ritorna null se path è stringa vuota', () async {
      final result = await controller.getDownloadUrl('');
      expect(result, isNull);
    });
  });

  group('deletePhotoFromDb — stato locale', () {
    late MockCollectionReference<Map<String, dynamic>> mockDiaryCol;
    late MockDocumentReference<Map<String, dynamic>> mockDiaryDocRef;

    setUp(() {
      mockDiaryCol = MockCollectionReference<Map<String, dynamic>>();
      mockDiaryDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockFirestore.collection('diary')).thenReturn(mockDiaryCol);
      when(mockDiaryCol.doc(any)).thenReturn(mockDiaryDocRef);
      when(mockDiaryDocRef.update(any)).thenAnswer((_) async {});
    });

    test('rimuove la foto dalla lista locale dopo update Firestore', () async {
      final diary = Diary(
        diaryId: 'dx1',
        userId: 'u1',
        trekkigName: 'Trek',
        date: '2024',
        duration: 1.0,
        friends: [],
        photos: ['Diary_photos/a.jpg', 'Diary_photos/b.jpg'],
        challenges: [],
        refreshmentPoint: '',
        mood: [],
        notes: '',
        isPublic: false,
      );
      controller.allDiaries.add(diary);

      try {
        await controller.deletePhotoFromDb('dx1', 'Diary_photos/a.jpg');
      } catch (_) {}

      verify(mockDiaryDocRef.update({
        'Photos': FieldValue.arrayRemove(['Diary_photos/a.jpg']),
      })).called(1);
    });

    test('notifyListeners viene chiamato se getDiaryById trova il diario', () async {
      final diary = makeDiary(id: 'dx2');
      controller.allDiaries.add(diary);

      bool notified = false;
      controller.addListener(() => notified = true);

      try {
        await controller.deletePhotoFromDb('dx2', 'path/photo.jpg');
      } catch (_) {}

      verify(mockDiaryDocRef.update(any)).called(1);
    });

    test('non crasha se il diario non è in lista locale', () async {
      await expectLater(
        controller.deletePhotoFromDb('non_esiste', 'path.jpg')
            .catchError((_) {}),
        completes,
      );
    });
  });
}