import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
@GenerateMocks([PairingService])
import 'user_test.mocks.dart';


Map<String, dynamic> _userDoc({
  String uid = 'u1',
  String username = 'testuser',
  String name = 'Mario',
  String surname = 'Rossi',
  String email = 'mario@test.it',
  String birthdate = '1990-05-01T00:00:00.000',
  String photo = 'https://photo.url',
  String level = 'beginner',
  int advanced = 2,
  int intermediate = 3,
  List<String> followers = const [],
  List<String> following = const [],
  List<String> publicDiary = const [],
  List<String> privateDiary = const [],
}) =>
    {
      'Uid': uid,
      'Username': username,
      'Name': name,
      'Surname': surname,
      'Email': email,
      'Birthdate': birthdate,
      'Photo_profile': photo,
      'Level': level,
      'Advanced': advanced,
      'Intermediate': intermediate,
      'Followers': followers,
      'Following': following,
      'Public_diary': publicDiary,
      'Private_diary': privateDiary,
    };

Map<String, dynamic> _diaryDoc({
  String userId = 'u1',
  String trekkingName = 'Monte Rosa',
  String date = '2024-06-01',
  double duration = 3.5,
  List<String> friends = const [],
  List<String> challenges = const [],
  bool isPublic = true,
}) =>
    {
      'UserId': userId,
      'Trekking_name': trekkingName,
      'Date': date,
      'Duration': duration,
      'Friends': friends,
      'Challenges': challenges,
      'Is_public': isPublic,
    };


void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockPairingService mockPairing;

  UserController makeCtrl() => UserController(mockPairing, db: fakeDb);

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockPairing = MockPairingService();
    when(mockPairing.pairedUid).thenReturn(null);
  });

  group('uid getter', () {
    test('delega a pairingService.pairedUid', () {
      when(mockPairing.pairedUid).thenReturn('myUid');
      expect(makeCtrl().uid, 'myUid');
    });

    test('è null se pairedUid è null', () {
      expect(makeCtrl().uid, isNull);
    });
  });

  group('loadCurrentPairedUser', () {
    test('con uid null → currentUser null e notifica', () async {
      final ctrl = makeCtrl();
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadCurrentPairedUser();

      expect(ctrl.currentUser, isNull);
      expect(notified, isTrue);
    });

    test('con uid valido → carica utente da Firestore', () async {
      await fakeDb.collection('users').doc('u1').set(_userDoc());
      when(mockPairing.pairedUid).thenReturn('u1');

      final ctrl = makeCtrl();
      await ctrl.loadCurrentPairedUser();

      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.currentUser!.username, 'testuser');
      expect(ctrl.currentUser!.email, 'mario@test.it');
    });
  });

  group('loadUserCore', () {
    test('documento esistente → popola currentUser', () async {
      await fakeDb.collection('users').doc('u2').set(_userDoc(uid: 'u2', username: 'giulia'));
      final ctrl = makeCtrl();
      await ctrl.loadUserCore('u2');

      expect(ctrl.currentUser!.username, 'giulia');
      expect(ctrl.currentUser!.uid, 'u2');
    });

    test('documento NON esistente → currentUser rimane null', () async {
      await makeCtrl().loadUserCore('nonexistent');
    });

    test('notifica i listener', () async {
      await fakeDb.collection('users').doc('u3').set(_userDoc(uid: 'u3'));
      final ctrl = makeCtrl();
      int count = 0;
      ctrl.addListener(() => count++);
      await ctrl.loadUserCore('u3');
      expect(count, greaterThan(0));
    });

    test('level, advanced, intermediate letti correttamente', () async {
      await fakeDb.collection('users').doc('u4').set(
            _userDoc(uid: 'u4', level: 'expert', advanced: 10, intermediate: 5),
          );
      final ctrl = makeCtrl();
      await ctrl.loadUserCore('u4');

      expect(ctrl.currentUser!.level, 'expert');
      expect(ctrl.currentUser!.advanced, 10);
      expect(ctrl.currentUser!.intermediate, 5);
    });

    test('birthdate vuota → usa default 2000-01-01', () async {
      await fakeDb.collection('users').doc('u5').set(_userDoc(uid: 'u5', birthdate: ''));
      final ctrl = makeCtrl();
      await ctrl.loadUserCore('u5');
      expect(ctrl.currentUser!.birthdate, DateTime(2000, 1, 1));
    });
  });

  group('getUserById', () {
    test('restituisce Users se esiste', () async {
      await fakeDb.collection('users').doc('u6').set(_userDoc(uid: 'u6', username: 'luca'));
      final user = await makeCtrl().getUserById('u6');
      expect(user!.username, 'luca');
    });

    test('restituisce null se NON esiste', () async {
      expect(await makeCtrl().getUserById('ghost'), isNull);
    });
  });

  group('getFollowers / getFollowing', () {
    test('getFollowers restituisce lista corretta', () async {
      await fakeDb.collection('users').doc('f1').set(_userDoc(uid: 'f1', username: 'anna'));
      await fakeDb.collection('users').doc('main').set(_userDoc(uid: 'main', followers: ['f1']));
      final list = await makeCtrl().getFollowers('main');
      expect(list.length, 1);
      expect(list.first.username, 'anna');
    });

    test('getFollowers lista vuota → lista vuota', () async {
      await fakeDb.collection('users').doc('solo').set(_userDoc(uid: 'solo'));
      expect(await makeCtrl().getFollowers('solo'), isEmpty);
    });

    test('getFollowers ignora uid inesistenti', () async {
      await fakeDb.collection('users').doc('wg').set(_userDoc(uid: 'wg', followers: ['nonexistent']));
      expect(await makeCtrl().getFollowers('wg'), isEmpty);
    });

    test('getFollowing restituisce lista corretta', () async {
      await fakeDb.collection('users').doc('g1').set(_userDoc(uid: 'g1', username: 'bob'));
      await fakeDb.collection('users').doc('mainU').set(_userDoc(uid: 'mainU', following: ['g1']));
      final list = await makeCtrl().getFollowing('mainU');
      expect(list.length, 1);
      expect(list.first.username, 'bob');
    });

    test('getFollowing lista vuota → lista vuota', () async {
      await fakeDb.collection('users').doc('lonely').set(_userDoc(uid: 'lonely'));
      expect(await makeCtrl().getFollowing('lonely'), isEmpty);
    });
  });
  group('searchUsers', () {
    test('trova utenti per query esatta', () async {
      await fakeDb.collection('users').doc('u10').set(_userDoc(uid: 'u10', username: 'carlo'));
      await fakeDb.collection('users_index').doc('i10').set({'normalized': 'carlo', 'uid': 'u10'});
      final r = await makeCtrl().searchUsers('carlo');
      expect(r.length, 1);
      expect(r.first.username, 'carlo');
    });

    test('query senza risultati → lista vuota', () async {
      expect(await makeCtrl().searchUsers('zzznessuno'), isEmpty);
    });

    test('trimma e lowercasea la query', () async {
      await fakeDb.collection('users').doc('u11').set(_userDoc(uid: 'u11', username: 'elena'));
      await fakeDb.collection('users_index').doc('i11').set({'normalized': 'elena', 'uid': 'u11'});
      expect(await makeCtrl().searchUsers('  ELENA  '), hasLength(1));
    });
  });

  group('diary methods', () {
    test('getDiaryById → Diary se esiste', () async {
      await fakeDb.collection('diary').doc('d1').set(_diaryDoc());
      final d = await makeCtrl().getDiaryById('d1');
      expect(d!.trekkigName, 'Monte Rosa');
    });

    test('getDiaryById → null se NON esiste', () async {
      expect(await makeCtrl().getDiaryById('ghost'), isNull);
    });

    test('getPublicDiaries restituisce lista corretta', () async {
      await fakeDb.collection('diary').doc('pub1').set(_diaryDoc(isPublic: true));
      await fakeDb.collection('users').doc('uD').set(_userDoc(uid: 'uD', publicDiary: ['pub1']));
      final list = await makeCtrl().getPublicDiaries('uD');
      expect(list.length, 1);
      expect(list.first.isPublic, isTrue);
    });

    test('getPrivateDiaries restituisce lista corretta', () async {
      await fakeDb.collection('diary').doc('priv1').set(_diaryDoc(isPublic: false));
      await fakeDb.collection('users').doc('uP').set(_userDoc(uid: 'uP', privateDiary: ['priv1']));
      final list = await makeCtrl().getPrivateDiaries('uP');
      expect(list.length, 1);
      expect(list.first.isPublic, isFalse);
    });

    test('getPublicDiaries lista vuota → lista vuota', () async {
      await fakeDb.collection('users').doc('uE1').set(_userDoc(uid: 'uE1'));
      expect(await makeCtrl().getPublicDiaries('uE1'), isEmpty);
    });

    test('getPrivateDiaries lista vuota → lista vuota', () async {
      await fakeDb.collection('users').doc('uE2').set(_userDoc(uid: 'uE2'));
      expect(await makeCtrl().getPrivateDiaries('uE2'), isEmpty);
    });
  });

  group('getFollowerUids / getFollowingUids', () {
    test('getFollowerUids restituisce lista uid', () async {
      await fakeDb.collection('users').doc('uF').set(_userDoc(uid: 'uF', followers: ['a1', 'a2']));
      expect(await makeCtrl().getFollowerUids('uF'), containsAll(['a1', 'a2']));
    });

    test('getFollowingUids restituisce lista uid', () async {
      await fakeDb.collection('users').doc('uG').set(_userDoc(uid: 'uG', following: ['b1', 'b2', 'b3']));
      expect(await makeCtrl().getFollowingUids('uG'), hasLength(3));
    });

    test('getFollowerUids → lista vuota se campo assente', () async {
      await fakeDb.collection('users').doc('uNF').set(
            {'Username': 'x', 'Name': '', 'Surname': '', 'Email': '', 'Birthdate': '', 'Level': '', 'Advanced': 0, 'Intermediate': 0},
          );
      expect(await makeCtrl().getFollowerUids('uNF'), isEmpty);
    });

    test('getFollowingUids → lista vuota se campo assente', () async {
      await fakeDb.collection('users').doc('uNG').set(
            {'Username': 'x', 'Name': '', 'Surname': '', 'Email': '', 'Birthdate': '', 'Level': '', 'Advanced': 0, 'Intermediate': 0},
          );
      expect(await makeCtrl().getFollowingUids('uNG'), isEmpty);
    });
  });
}
