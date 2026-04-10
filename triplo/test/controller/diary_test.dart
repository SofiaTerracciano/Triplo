import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/service/authservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'diary_test.mocks.dart';

@GenerateMocks([
  AuthService,
  FirebaseFirestore,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>,
  QuerySnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
])
void main() {
  late DiaryController controller;
  late MockAuthService mockAuthService;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestore = MockFirebaseFirestore();

    when(mockAuthService.currentUid).thenReturn("test_uid");

    controller = DiaryController(
      mockAuthService,
      firestore: mockFirestore,
    );
  });

  test('updateDiary aggiorna correttamente i campi', () {
    final diary = Diary(
      diaryId: "1",
      userId: "u1",
      trekkigName: "test",
      date: "old",
      duration: 1,
      friends: [],
      photos: [],
      challenges: [],
      refreshmentPoint: "",
      mood: [],
      notes: "",
      isPublic: false,
    );

    final updated = controller.updateDiary(
      diary,
      true,
      "newDate",
      5.0,
      ["a"],
      ["p"],
      ["c"],
      "bar",
      ["happy"],
      "note",
    );

    expect(updated.isPublic, true);
    expect(updated.date, "newDate");
  });

  test('getDiaryById ritorna il diario corretto', () {
    final diary = Diary(
      diaryId: "123",
      userId: "u1",
      trekkigName: "",
      date: "",
      duration: 0,
      friends: [],
      photos: [],
      challenges: [],
      refreshmentPoint: "",
      mood: [],
      notes: "",
      isPublic: false,
    );

    controller.allDiaries.add(diary);

    final result = controller.getDiaryById("123");

    expect(result, isNotNull);
  });

  test('getDiaryById ritorna null se non trovato', () {
    final result = controller.getDiaryById("not_exist");

    expect(result, isNull);
  });

  test('fetchDiaryById ritorna lista di diari', () async {
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

    // 🔥 FIX: niente cast strani, tipi già corretti
    when(mockFirestore.collection('diary')).thenReturn(mockCollection);

    when(mockCollection.where('UserId', isEqualTo: anyNamed('isEqualTo')))
        .thenReturn(mockCollection);

    when(mockCollection.get())
        .thenAnswer((_) async => mockQuerySnapshot);

    when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

    when(mockDoc.data()).thenReturn({
      "UserId": "test_uid",
      "Trekking_name": "Trip",
      "Date": "2024",
      "Duration": 2,
      "Friends": [],
      "Photos": [],
      "Challenges": [],
      "Refreshment_point": "",
      "Mood": [],
      "Notes": "",
      "Is_public": true,
    });

    when(mockDoc.id).thenReturn("1");

    final result = await controller.fetchDiaryById("test_uid");

    expect(result, isNotNull);
    expect(result!.length, 1);
  });

  test('removeDiary rimuove il diario dalla lista locale', () async {
    final diary = Diary(
      diaryId: "1",
      userId: "u1",
      trekkigName: "",
      date: "",
      duration: 0,
      friends: [],
      photos: [],
      challenges: [],
      refreshmentPoint: "",
      mood: [],
      notes: "",
      isPublic: true,
    );

    controller.allDiaries.add(diary);

    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

    // 🔥 FIX: tutti i when fuori, puliti
    when(mockFirestore.collection('diary')).thenReturn(mockCollection);
    when(mockCollection.doc("1")).thenReturn(mockDocRef);
    when(mockDocRef.delete()).thenAnswer((_) async {});
    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocRef);
    when(mockDocRef.update(any)).thenAnswer((_) async {});

    await controller.removeDiary("1");

    expect(controller.allDiaries.isEmpty, true);
  });
}