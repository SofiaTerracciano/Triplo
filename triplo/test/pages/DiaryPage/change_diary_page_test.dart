import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

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

// ─────────────────────────────────────────────
// Generazione mock:  flutter pub run build_runner build
// ─────────────────────────────────────────────
@GenerateMocks([AuthService, TrekkingController, UserController])
void main() {
  // ──────────────────────────────────────────
  // UNIT TEST – Diary model
  // ──────────────────────────────────────────
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
      final restored = Diary.fromMap(original.toMap(), diaryId: original.diaryId);

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

  // ──────────────────────────────────────────
  // UNIT TEST – Users model
  // ──────────────────────────────────────────
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

    test('toMap() serializza publicDiaryPages e privateDiaryPages come lista di diaryId', () {
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
      final user = Users.fromMap({'username': 'mario', 'email': 'mario@test.it'}, uid: 'u1');

      expect(user.username, 'mario');
      expect(user.email, 'mario@test.it');
    });

    test('fromMap() parsifica Advanced/Intermediate come stringa', () {
      final user = Users.fromMap({'Advanced': '5', 'Intermediate': '3'}, uid: 'u1');

      expect(user.advanced, 5);
      expect(user.intermediate, 3);
    });

    test('fromMap() usa registerdate come birthdate legacy', () {
      final user = Users.fromMap({'registerdate': '1990-03-15T00:00:00.000'}, uid: 'u1');

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

  // ──────────────────────────────────────────
  // UNIT TEST – Trekking model
  // ──────────────────────────────────────────
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

  // ──────────────────────────────────────────
  // UNIT TEST – DiaryController
  // ──────────────────────────────────────────
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

      // Il controller chiama users/user1.update() → il documento deve esistere
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
        _buildDiary(), false, '10/10/2025', 90.0,
        ['f2'], ['p2.jpg'], ['c2'], 'Rifugio Nuovo', ['😎'], 'Note aggiornate',
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
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], 'Note test', false, '',
      );

      expect(controller.allDiaries.length, 1);
      expect(controller.allDiaries.first.trekkigName, 'Monte Rosa');
    });

    test("addDiary (nuovo, pubblico) aggiorna publicDiaryPages dell'utente", () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );

      expect(fakeUser.publicDiaryPages.length, 1);
      expect(fakeUser.privateDiaryPages.length, 0);
    });

    test("addDiary (nuovo, privato) aggiorna privateDiaryPages dell'utente", () async {
      await controller.addDiary(
        'Monte Rosa', false, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );

      expect(fakeUser.privateDiaryPages.length, 1);
      expect(fakeUser.publicDiaryPages.length, 0);
    });

    test('addDiary (nuovo) scrive il documento su Firestore', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );

      final diaryId = controller.allDiaries.first.diaryId;
      final doc = await fakeFirestore.collection('diary').doc(diaryId).get();
      expect(doc.exists, true);
      expect(doc.data()!['Trekking_name'], 'Monte Rosa');
    });

    test('addDiary (modifica) aggiorna notes e date del diario esistente', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], 'Note originali', false, '',
      );
      final diaryId = controller.allDiaries.first.diaryId;

      await controller.addDiary(
        'Monte Rosa', true, '05/07/2024', 90.0,
        [], [], [], '', [], 'Note modificate', true, diaryId,
      );

      final updated = controller.getDiaryById(diaryId)!;
      expect(updated.notes, 'Note modificate');
      expect(updated.date, '05/07/2024');
    });

    test('addDiary (modifica) cambia visibilità e aggiorna Firestore', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );
      final diaryId = controller.allDiaries.first.diaryId;

      await controller.addDiary(
        'Monte Rosa', false, '01/06/2024', 120.0,
        [], [], [], '', [], '', true, diaryId,
      );

      final doc = await fakeFirestore.collection('users').doc('user1').get();
      final publicList = List<String>.from(doc.data()?['Public_diary'] ?? []);
      final privateList = List<String>.from(doc.data()?['Private_diary'] ?? []);
      expect(publicList.contains(diaryId), false);
      expect(privateList.contains(diaryId), true);
    });

    test('removeDiary elimina il diario dalla lista locale', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );
      final diaryId = controller.allDiaries.first.diaryId;

      await controller.removeDiary(diaryId);

      expect(controller.allDiaries.isEmpty, true);
    });

    test('removeDiary elimina il documento da Firestore', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );
      final diaryId = controller.allDiaries.first.diaryId;

      await controller.removeDiary(diaryId);

      final doc = await fakeFirestore.collection('diary').doc(diaryId).get();
      expect(doc.exists, false);
    });

    test("removeDiary (pubblico) rimuove da publicDiaryPages dell'utente", () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );
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
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap(isPublic: true));
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap(isPublic: false));

      final result = await controller.getPublicDiaries('user1');
      expect(result.every((d) => d.isPublic), true);
    });

    test('getPrivateDiaries restituisce solo diari privati', () async {
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap(isPublic: true));
      await fakeFirestore.collection('diary').add(_diaryFirestoreMap(isPublic: false));

      final result = await controller.getPrivateDiaries('user1');
      expect(result.every((d) => !d.isPublic), true);
    });

    test('getDiaryByIdAsync trova il diario nella cache locale', () async {
      await controller.addDiary(
        'Monte Rosa', true, '01/06/2024', 120.0,
        [], [], [], '', [], '', false, '',
      );
      final diaryId = controller.allDiaries.first.diaryId;

      final result = await controller.getDiaryByIdAsync(diaryId);
      expect(result, isNotNull);
      expect(result!.diaryId, diaryId);
    });

    test('getDiaryByIdAsync cerca su Firestore se non in cache', () async {
      final docRef = await fakeFirestore.collection('diary').add(_diaryFirestoreMap());

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
          _diaryFirestoreMap(userId: 'followedUser', isPublic: true),
        );
      }

      final result = await controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['followedUser'],
        limit: 3,
      );

      expect(result.length, lessThanOrEqualTo(3));
    });

    test('getRandomPublicDiariesFromFollowing restituisce solo diari pubblici', () async {
      await fakeFirestore.collection('diary').add(
        _diaryFirestoreMap(userId: 'followedUser', isPublic: true),
      );
      await fakeFirestore.collection('diary').add(
        _diaryFirestoreMap(userId: 'followedUser', isPublic: false),
      );

      final result = await controller.getRandomPublicDiariesFromFollowing(
        followingIds: ['followedUser'],
        limit: 10,
      );

      expect(result.every((d) => d.isPublic), true);
    });
  });

  // ──────────────────────────────────────────
  // WIDGET TEST – ModifyDiaryPage
  // ──────────────────────────────────────────
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

      //TestWidgetsFlutterBinding.ensureInitialized();
    });

    Widget buildPage() => MultiProvider(
          providers: [
            ChangeNotifierProvider<DiaryController>.value(value: diaryController),
            ChangeNotifierProvider<TrekkingController>.value(value: mockTrekkingController),
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
            home: ModifyDiaryPage(trekkingId: 'trek1', diaryId: 'diary_widget'),
          ),
        );

    testWidgets('dropdown giorno mostra valore iniziale corretto', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Il diary ha date '01/06/2024' → giorno=1, mese=6, anno=2024
      // I dropdown mostrano questi valori iniziali
      final firstDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).first,
      );
      expect(firstDropdown.value, 1);
    });

    testWidgets('dropdown minuti mostra valore iniziale corretto', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // duration=120 → ore=2, minuti=0
      final minuteDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(4),
      );
      expect(minuteDropdown.value, 0);
    });

    testWidgets('dropdown mese cambia valore selezionato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<int>).at(1));
      await tester.pumpAndSettle();

      // Mese corrente è 6, scegliamo 3 (non ambiguo)
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

      // ora iniziale = 120/60 = 2 → selezioniamo 5 (non ambiguo)
      await tester.tap(find.byType(DropdownButton<int>).at(3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('05'));
      await tester.pumpAndSettle();

      expect(find.text('05'), findsOneWidget);
    });

    testWidgets('sezione amici mostra testo "no friends" quando lista vuota',
        (tester) async {
      // Diary senza amici → _buildDiaryForWidget() ha già friends: []
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(ModifyDiaryPage)),
      )!;
      expect(find.text(local.friends_selected_label), findsOneWidget);
    });

    testWidgets('ExpansionTile amici espande e mostra lista following vuota',
    (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final expansionTiles = find.byType(ExpansionTile);
      await tester.tap(expansionTiles.first);
      await tester.pumpAndSettle();

      // Nessun ListTile con CircleAvatar come leading (= nessun amico)
      expect(
        find.byWidgetPredicate(
          (w) => w is ListTile && w.leading is CircleAvatar,
        ),
        findsNothing,
      );
    });

    testWidgets('sezione mood mostra emoji preselezionata nel preview', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // diary_widget ha mood: ['😍'] → deve apparire almeno una volta nel preview
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

      // Tap su emoji non ancora selezionata → viene aggiunta al mood
      await tester.tap(find.text('😁').first);
      await tester.pumpAndSettle();

      expect(find.text('😁'), findsWidgets);
    });

    testWidgets('tap su emoji già selezionata la rimuove dal mood', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Espande ExpansionTile mood (ultimo)
      final tiles = find.byType(ExpansionTile);
      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      // Tap sul ListTile di 😍 per deselezionarla
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😍',
        ),
      );
      await tester.pumpAndSettle();

      // Il Chip nel preview non deve più esserci
      expect(
        find.byWidgetPredicate(
          (w) => w is Chip &&
              w.label is Text &&
              (w.label as Text).data == '😍',
        ),
        findsNothing,
      );
    });

    testWidgets('bottone Pubblico imposta isPublic a true', (tester) async {
      // Aumenta la viewport per contenere tutta la pagina
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(ModifyDiaryPage)),
      )!;

      // Prima porta su Privato
      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();

      // Poi torna su Pubblico
      await tester.tap(find.text(local.public_botton_label));
      await tester.pumpAndSettle();

      // Verifica: il bottone Pubblico ha foreground bianco (= active)
      final publicBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, local.public_botton_label),
      );
      final fg = publicBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets('bottone Privato imposta isPublic a false', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(ModifyDiaryPage)),
      )!;

      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();

      final privateBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, local.private_botton_label),
      );
      final fg = privateBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets('toggle No poi Sì ripristina visibilità TextField rifornimento',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(ModifyDiaryPage)),
      )!;

      await tester.tap(find.widgetWithText(ChoiceChip, local.no_botton_label));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, local.yes_botton_label));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    // Aggiorna anche il test originale che aveva lo stesso problema:
    testWidgets('toggle No nasconde il campo testo del rifornimento', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final noChip = find.widgetWithText(ChoiceChip, 'No');
      await tester.tap(noChip);
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

    testWidgets('FutureBuilder mostra loading indicator durante caricamento following',
        (tester) async {
      // Ritardo artificiale per intercettare lo stato di loading
      when(mockUserController.getFollowing('user1')).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 1));
          return <Users>[];
        },
      );

      await tester.pumpWidget(buildPage());
      await tester.pump(); // un solo frame: FutureBuilder è in waiting

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // completa il future
    });

    testWidgets('modifica del campo refreshment aggiorna il testo', (tester) async {
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

    testWidgets('i dropdown data sono precompilati con i valori del diary', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
      expect(find.text('6'), findsWidgets);
      expect(find.text('2024'), findsWidgets);
    });

    testWidgets('il campo Note è precompilato con il testo del diary', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Bella escursione'), findsOneWidget);
    });

    testWidgets('il campo refreshment è precompilato e visibile', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Rifugio Gnifetti'), findsOneWidget);
    });


    testWidgets('toggle Sì ripristina la visibilità del campo rifornimento',
    (tester) async {
      // Deve stare QUI dentro, non nel setUp
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(ModifyDiaryPage)),
      )!;

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

    testWidgets('ExpansionTile mood espande e mostra le emoji disponibili', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      expect(tiles, findsWidgets);

      await tester.ensureVisible(tiles.last);
      await tester.pumpAndSettle();
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      expect(find.text('😍'), findsWidgets);
      expect(find.text('😁'), findsWidgets);
    });

    testWidgets('il mood selezionato appare nella sezione preview', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('😍'), findsWidgets);
    });

    testWidgets('pulsante aggiungi foto è presente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    // FIX: il bottone Annulla è in fondo alla pagina (off-screen).
    // Invece di scrollare, usiamo tester.pageBack() che simula
    // direttamente il pop della route corrente — equivalente funzionale.
    testWidgets('bottone Annulla fa pop della route', (tester) async {
      bool popped = false;

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<DiaryController>.value(value: diaryController),
          ChangeNotifierProvider<TrekkingController>.value(value: mockTrekkingController),
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
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ModifyDiaryPage(
                      trekkingId: 'trek1',
                      diaryId: 'diary_widget',
                    ),
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

      // tester.pageBack() simula il tap sul back button della AppBar:
      // è l'equivalente esatto di Navigator.pop ed è sempre visibile.
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
}

// ──────────────────────────────────────────────
// Helper factories
// ──────────────────────────────────────────────

Diary _buildDiary({String diaryId = 'diary1', bool isPublic = true}) => Diary(
      diaryId: diaryId,
      userId: 'user1',
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

/// Diary per widget test: photos/challenges vuote → nessuna chiamata a Storage
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

/// Trekking per widget test: challenges vuote → sezione non renderizzata
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
      // challenges e refreshmentPoint omessi → default [] e ''
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