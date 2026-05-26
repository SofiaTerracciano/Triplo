import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/service/authservice.dart';
import 'user_test.mocks.dart';

@GenerateMocks([AuthService])


Map<String, dynamic> fakeUserDoc({
  String username = 'mario_rossi',
  String name = 'Mario',
  String surname = 'Rossi',
  String email = 'mario@example.com',
  String birthdate = '1990-06-15T00:00:00.000',
  String photoProfile = 'https://example.com/photo.jpg',
  String level = 'Beginner',
  int advanced = 0,
  int intermediate = 0,
  List<String> followers = const [],
  List<String> following = const [],
}) {
  return {
    'Username': username,
    'Name': name,
    'Surname': surname,
    'Email': email,
    'Birthdate': birthdate,
    'Photo_profile': photoProfile,
    'Level': level,
    'Advanced': advanced,
    'Intermediate': intermediate,
    'Followers': followers,
    'Following': following,
    'Public_diary': [],
    'Private_diary': [],
    'Saved_trekkings': [],
  };
}

Future<Users> seedUser(
  FakeFirebaseFirestore db, {
  String uid = 'uid_1',
  Map<String, dynamic>? data,
}) async {
  final doc = data ?? fakeUserDoc();
  await db.collection('users').doc(uid).set(doc);
  return Users.fromMap(doc, uid: uid);
}

void main() {
  late MockAuthService mockAuth;
  late FakeFirebaseFirestore fakeDb;

  Future<UserController> buildController({
    String? currentUid,
    Users? currentUser,
  }) async {
    when(mockAuth.currentUid).thenReturn(currentUid);
    when(mockAuth.currentUser).thenReturn(currentUser);

    final ctrl = UserController.withDb(mockAuth, fakeDb); 
    await Future.delayed(Duration.zero);
    return ctrl;
  }

  setUp(() {
    mockAuth = MockAuthService();
    fakeDb = FakeFirebaseFirestore();

    when(mockAuth.currentUid).thenReturn(null);
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.isGoogleUser).thenReturn(false);
    when(mockAuth.isPasswordUser).thenReturn(true);
    when(mockAuth.currentPhotoUrl).thenReturn(null);
  });

  group('_init()', () {
    test('isLoading is false after construction when no user is logged in',
        () async {
      final ctrl = await buildController(currentUid: null);
      expect(ctrl.isLoading, isFalse);
    });

    test('loads currentUser when uid is present at construction', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      final ctrl = await buildController(currentUid: 'uid_1');

      expect(ctrl.isLoading, isFalse);
      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.currentUser!.uid, 'uid_1');
    });

    test('currentUser is null when uid is absent at construction', () async {
      final ctrl = await buildController(currentUid: null);
      expect(ctrl.currentUser, isNull);
    });
  });

  group('register()', () {
    test('calls authService.register and sets currentUser', () async {
      final user = await seedUser(fakeDb);
      when(mockAuth.register(any, any)).thenAnswer((_) async {
        when(mockAuth.currentUser).thenReturn(user);
      });

      final ctrl = await buildController();
      await ctrl.register('mario@example.com', 'password123');

      verify(mockAuth.register('mario@example.com', 'password123')).called(1);
      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.currentUser!.uid, 'uid_1');
      expect(ctrl.isLoading, isFalse);
    });

    test('isLoading is false even when register throws', () async {
      when(mockAuth.register(any, any)).thenThrow(Exception('auth error'));

      final ctrl = await buildController();
      expect(() => ctrl.register('a@b.com', 'pass'), throwsException);
      await Future.delayed(Duration.zero);
      expect(ctrl.isLoading, isFalse);
    });
  });

  group('login()', () {
    test('calls authService.login and sets currentUser', () async {
      final user = await seedUser(fakeDb);
      when(mockAuth.login(any, any)).thenAnswer((_) async {
        when(mockAuth.currentUser).thenReturn(user);
      });

      final ctrl = await buildController();
      await ctrl.login('mario@example.com', 'password123');

      verify(mockAuth.login('mario@example.com', 'password123')).called(1);
      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.isLoading, isFalse);
    });

    test('isLoading is false even when login throws', () async {
      when(mockAuth.login(any, any)).thenThrow(Exception('wrong password'));

      final ctrl = await buildController();
      expect(() => ctrl.login('a@b.com', 'bad'), throwsException);
      await Future.delayed(Duration.zero);
      expect(ctrl.isLoading, isFalse);
    });
  });

  group('loginWithGoogle()', () {
    test('calls authService.loginWithGoogle and sets currentUser', () async {
      final user = await seedUser(fakeDb);
      when(mockAuth.loginWithGoogle()).thenAnswer((_) async {
        when(mockAuth.currentUser).thenReturn(user);
      });

      final ctrl = await buildController();
      await ctrl.loginWithGoogle();

      verify(mockAuth.loginWithGoogle()).called(1);
      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.isLoading, isFalse);
    });

    test('rethrows exception from authService', () async {
      when(mockAuth.loginWithGoogle()).thenThrow(Exception('google error'));

      final ctrl = await buildController();
      await expectLater(
        () => ctrl.loginWithGoogle(),
        throwsException,
      );
    });
  });

  group('logout()', () {
    test('calls authService.logout and clears currentUser', () async {
      final user = await seedUser(fakeDb);
      when(mockAuth.logout()).thenAnswer((_) async {});
      when(mockAuth.currentUser).thenReturn(user);

      final ctrl = await buildController(currentUid: 'uid_1', currentUser: user);
      await ctrl.logout();

      verify(mockAuth.logout()).called(1);
      expect(ctrl.currentUser, isNull);
      expect(ctrl.isLoading, isFalse);
    });
  });

  group('loadUserCore()', () {
    test('populates _currentUser from Firestore', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      final ctrl = await buildController();

      await ctrl.loadUserCore('uid_1');

      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.currentUser!.uid, 'uid_1');
      expect(ctrl.currentUser!.username, 'mario_rossi');
    });

    test('does nothing when document does not exist', () async {
      final ctrl = await buildController();
      await ctrl.loadUserCore('uid_nonexistent');
      expect(ctrl.currentUser, isNull);
    });

    test('parses level, advanced, intermediate from Firestore', () async {
      await seedUser(fakeDb,
          uid: 'uid_1',
          data: fakeUserDoc(level: 'Advanced', advanced: 6, intermediate: 3));
      final ctrl = await buildController();
      await ctrl.loadUserCore('uid_1');

      expect(ctrl.currentUser!.level, 'Advanced');
      expect(ctrl.currentUser!.advanced, 6);
      expect(ctrl.currentUser!.intermediate, 3);
    });
  });

  group('getUserById()', () {
    test('returns Users when document exists', () async {
      await seedUser(fakeDb, uid: 'uid_2');
      final ctrl = await buildController();

      final user = await ctrl.getUserById('uid_2');
      expect(user, isNotNull);
      expect(user!.uid, 'uid_2');
    });

    test('returns null when document does not exist', () async {
      final ctrl = await buildController();
      final user = await ctrl.getUserById('nonexistent');
      expect(user, isNull);
    });
  });

  group('getFollowers()', () {
    test('returns list of follower Users', () async {
      await seedUser(fakeDb, uid: 'uid_A');
      await seedUser(fakeDb, uid: 'uid_B');
      await fakeDb.collection('users').doc('uid_A').update({
        'Followers': ['uid_B'],
      });

      final ctrl = await buildController();
      final followers = await ctrl.getFollowers('uid_A');

      expect(followers.length, 1);
      expect(followers.first.uid, 'uid_B');
    });

    test('returns empty list when no followers', () async {
      await seedUser(fakeDb, uid: 'uid_A');
      final ctrl = await buildController();
      final followers = await ctrl.getFollowers('uid_A');
      expect(followers, isEmpty);
    });
  });

  group('getFollowing()', () {
    test('returns list of following Users', () async {
      await seedUser(fakeDb, uid: 'uid_A');
      await seedUser(fakeDb, uid: 'uid_C');
      await fakeDb.collection('users').doc('uid_A').update({
        'Following': ['uid_C'],
      });

      final ctrl = await buildController();
      final following = await ctrl.getFollowing('uid_A');

      expect(following.length, 1);
      expect(following.first.uid, 'uid_C');
    });
  });

  group('getFollowingIds()', () {
    test('returns list of UIDs', () async {
      await seedUser(fakeDb, uid: 'uid_A');
      await fakeDb.collection('users').doc('uid_A').update({
        'Following': ['uid_X', 'uid_Y'],
      });

      final ctrl = await buildController();
      final ids = await ctrl.getFollowingIds('uid_A');
      expect(ids, ['uid_X', 'uid_Y']);
    });

    test('returns empty list when following is absent', () async {
      await seedUser(fakeDb, uid: 'uid_A');
      final ctrl = await buildController();
      final ids = await ctrl.getFollowingIds('uid_A');
      expect(ids, isEmpty);
    });
  });

  group('updateUsername()', () {
    test('updates Firestore and local user', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      await fakeDb.collection('users_index').doc('uid_1').set({
        'uid': 'uid_1',
        'username': 'mario_rossi',
        'normalized': 'mario_rossi',
      });
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      await ctrl.updateUsername('nuovo_username');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Username'], 'nuovo_username');
      expect(ctrl.currentUser!.username, 'nuovo_username');
    });

    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.updateUsername('new_name');
    });
  });

  group('updateName()', () {
    test('updates Firestore and local user', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      await ctrl.updateName('Luigi');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Name'], 'Luigi');
      expect(ctrl.currentUser!.name, 'Luigi');
    });

    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.updateName('Luigi');
    });
  });

  group('updateSurname()', () {
    test('updates Firestore and local user', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      await ctrl.updateSurname('Verdi');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Surname'], 'Verdi');
      expect(ctrl.currentUser!.surname, 'Verdi');
    });
  });

  group('updateBirthdate()', () {
    test('updates Firestore and local user', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      final newDate = DateTime(2000, 5, 20);
      await ctrl.updateBirthdate(newDate);

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Birthdate'], newDate.toIso8601String());
      expect(ctrl.currentUser!.birthdate, newDate);
    });
  });

  group('updateUserLevel()', () {
    Future<UserController> ctrlWithUser({
      int advanced = 0,
      int intermediate = 0,
      String level = 'Beginner',
    }) async {
      await fakeDb.collection('users').doc('uid_1').set(
            fakeUserDoc(advanced: advanced, intermediate: intermediate, level: level),
          );
      when(mockAuth.currentUid).thenReturn('uid_1');
      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      return ctrl;
    }

    test('increments intermediate counter on "Intermediate" difficulty',
        () async {
      final ctrl = await ctrlWithUser(intermediate: 2);
      await ctrl.updateUserLevel('intermediate');
      expect(ctrl.currentUser!.intermediate, 3);
    });

    test('increments advanced counter on "Advanced" difficulty', () async {
      final ctrl = await ctrlWithUser(advanced: 2);
      await ctrl.updateUserLevel('advanced');
      expect(ctrl.currentUser!.advanced, 3);
    });

    test('level becomes "Intermediate" at 5 intermediate completions',
        () async {
      final ctrl = await ctrlWithUser(intermediate: 4);
      await ctrl.updateUserLevel('intermediate');
      expect(ctrl.currentUser!.level, 'Intermediate');
    });

    test('level becomes "Advanced" at 5 advanced completions', () async {
      final ctrl = await ctrlWithUser(advanced: 4);
      await ctrl.updateUserLevel('advanced');
      expect(ctrl.currentUser!.level, 'Advanced');
    });

    test('Advanced takes priority over Intermediate for level assignment',
        () async {
      final ctrl = await ctrlWithUser(advanced: 4, intermediate: 5);
      await ctrl.updateUserLevel('advanced');
      expect(ctrl.currentUser!.level, 'Advanced');
    });

    test('level stays "Beginner" below thresholds', () async {
      final ctrl = await ctrlWithUser(advanced: 1, intermediate: 1);
      await ctrl.updateUserLevel('intermediate');
      expect(ctrl.currentUser!.level, 'Beginner');
    });

    test('persists updated values in Firestore', () async {
      final ctrl = await ctrlWithUser(intermediate: 4);
      await ctrl.updateUserLevel('intermediate');

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Intermediate'], 5);
      expect(snap.data()!['Level'], 'Intermediate');
    });

    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.updateUserLevel('advanced'); 
    });
  });

  group('isFollowing()', () {
    test('returns true when target is in following list', () async {
      await seedUser(fakeDb, uid: 'uid_1',
          data: fakeUserDoc(following: ['uid_2']));
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      expect(await ctrl.isFollowing('uid_2'), isTrue);
    });

    test('returns false when target is not in following list', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      expect(await ctrl.isFollowing('uid_2'), isFalse);
    });

    test('returns false when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      expect(await ctrl.isFollowing('uid_2'), isFalse);
    });
  });

  group('followUser()', () {
    test('adds targetUid to following and myUid to followers', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      await seedUser(fakeDb, uid: 'uid_2');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      final result = await ctrl.followUser('uid_2');

      expect(result, isTrue);

      final mySnap = await fakeDb.collection('users').doc('uid_1').get();
      final targetSnap = await fakeDb.collection('users').doc('uid_2').get();

      expect(mySnap.data()!['Following'], contains('uid_2'));
      expect(targetSnap.data()!['Followers'], contains('uid_1'));
    });

    test('returns false and does nothing when following self', () async {
      when(mockAuth.currentUid).thenReturn('uid_1');
      final ctrl = await buildController(currentUid: 'uid_1');
      final result = await ctrl.followUser('uid_1');
      expect(result, isFalse);
    });

    test('returns false when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      expect(await ctrl.followUser('uid_2'), isFalse);
    });
  });

  group('unfollowUser()', () {
    test('removes targetUid from following and myUid from followers',
        () async {
      await fakeDb.collection('users').doc('uid_1').set(
            fakeUserDoc(following: ['uid_2']),
          );
      await fakeDb.collection('users').doc('uid_2').set(
            fakeUserDoc(followers: ['uid_1']),
          );
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.unfollowUser('uid_2');

      final mySnap = await fakeDb.collection('users').doc('uid_1').get();
      final targetSnap = await fakeDb.collection('users').doc('uid_2').get();

      expect(mySnap.data()!['Following'], isNot(contains('uid_2')));
      expect(targetSnap.data()!['Followers'], isNot(contains('uid_1')));
    });

    test('does nothing when unfollowing self', () async {
      when(mockAuth.currentUid).thenReturn('uid_1');
      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.unfollowUser('uid_1'); 
    });

    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.unfollowUser('uid_2'); 
    });
  });

  group('tryAutoLogin()', () {
    test('loads user when uid is present', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.tryAutoLogin();

      expect(ctrl.currentUser, isNotNull);
      expect(ctrl.isLoading, isFalse);
    });

    test('clears currentUser when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.tryAutoLogin();

      expect(ctrl.currentUser, isNull);
      expect(ctrl.isLoading, isFalse);
    });
  });

  group('sendPasswordReset()', () {
    test('delegates to authService', () async {
      when(mockAuth.sendPasswordReset(any)).thenAnswer((_) async {});
      final ctrl = await buildController();
      await ctrl.sendPasswordReset('mario@example.com');
      verify(mockAuth.sendPasswordReset('mario@example.com')).called(1);
    });
  });

  group('requestPasswordReset()', () {
    test('delegates to authService', () async {
      when(mockAuth.requestPasswordReset()).thenAnswer((_) async {});
      final ctrl = await buildController();
      await ctrl.requestPasswordReset();
      verify(mockAuth.requestPasswordReset()).called(1);
    });
  });

  group('provider flags', () {
    test('isGoogleUser delegates to authService', () async {
      when(mockAuth.isGoogleUser).thenReturn(true);
      final ctrl = await buildController();
      expect(ctrl.isGoogleUser, isTrue);
    });

    test('isPasswordUser delegates to authService', () async {
      when(mockAuth.isPasswordUser).thenReturn(false);
      final ctrl = await buildController();
      expect(ctrl.isPasswordUser, isFalse);
    });
  });

  group('restoreGoogleProfilePhoto()', () {
    test('updates Firestore and local user with Google photo URL', () async {
      await seedUser(fakeDb, uid: 'uid_1');
      when(mockAuth.currentUid).thenReturn('uid_1');
      when(mockAuth.currentPhotoUrl).thenReturn('https://google.com/photo.jpg');

      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.loadUserCore('uid_1');
      await ctrl.restoreGoogleProfilePhoto();

      final snap = await fakeDb.collection('users').doc('uid_1').get();
      expect(snap.data()!['Photo_profile'], 'https://google.com/photo.jpg');
      expect(ctrl.currentUser!.photoProfile, 'https://google.com/photo.jpg');
    });

    test('does nothing when photoUrl is empty', () async {
      when(mockAuth.currentUid).thenReturn('uid_1');
      when(mockAuth.currentPhotoUrl).thenReturn('');
      final ctrl = await buildController(currentUid: 'uid_1');
      await ctrl.restoreGoogleProfilePhoto(); 
    });

    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.restoreGoogleProfilePhoto(); 
    });
  });

  group('extractWatchPair()', () {
    test('delegates to authService and returns the pair', () async {
      when(mockAuth.extractWatchPair(any))
          .thenReturn((watchId: 'watch_1', token: 'tok_abc'));

      final ctrl = await buildController();
      final pair = ctrl.extractWatchPair('raw_string');

      expect(pair.watchId, 'watch_1');
      expect(pair.token, 'tok_abc');
      verify(mockAuth.extractWatchPair('raw_string')).called(1);
    });
  });

  group('changeEmail()', () {
    test('delegates to authService', () async {
      when(mockAuth.changeEmail(newEmail: anyNamed('newEmail'),
              currentPassword: anyNamed('currentPassword')))
          .thenAnswer((_) async {});

      final ctrl = await buildController();
      await ctrl.changeEmail(
          newEmail: 'new@example.com', currentPassword: 'secret');

      verify(mockAuth.changeEmail(
              newEmail: 'new@example.com', currentPassword: 'secret'))
          .called(1);
    });
  });

  group('refreshEmailFromAuth()', () {
    test('calls authService and syncs currentUser', () async {
      final user = await seedUser(fakeDb);
      when(mockAuth.refreshEmailFromAuth()).thenAnswer((_) async {
        when(mockAuth.currentUser).thenReturn(user);
      });

      final ctrl = await buildController();
      await ctrl.refreshEmailFromAuth();

      verify(mockAuth.refreshEmailFromAuth()).called(1);
      expect(ctrl.currentUser, isNotNull);
    });
  });

  group('searchUsers()', () {
    test('returns matching users from users_index', () async {
      // Semina un documento nell'indice di ricerca
      await fakeDb.collection('users_index').doc('uid_1').set({
        'uid': 'uid_1',
        'username': 'mario_rossi',
        'normalized': 'mario_rossi',
      });
      await seedUser(fakeDb, uid: 'uid_1');

      final ctrl = await buildController();
      final results = await ctrl.searchUsers('mario');

      expect(results, isNotEmpty);
      expect(results.first.uid, 'uid_1');
    });

    test('returns empty list when no match in users_index', () async {
      final ctrl = await buildController();
      final results = await ctrl.searchUsers('zzznomatch');
      expect(results, isEmpty);
    });

    test('skips index entries whose user document does not exist', () async {
      // Indice punta a un uid che non esiste nella collection users
      await fakeDb.collection('users_index').doc('ghost').set({
        'uid': 'uid_ghost',
        'username': 'ghost',
        'normalized': 'ghost',
      });

      final ctrl = await buildController();
      final results = await ctrl.searchUsers('ghost');
      expect(results, isEmpty);
    });
  });

  group('approveWatchPair()', () {
    test('delegates to authService with correct parameters', () async {
      when(mockAuth.approveWatchPair(
        watchId: anyNamed('watchId'),
        token: anyNamed('token'),
      )).thenAnswer((_) async {});

      final ctrl = await buildController();
      await ctrl.approveWatchPair(watchId: 'watch_42', token: 'tok_xyz');

      verify(mockAuth.approveWatchPair(
        watchId: 'watch_42',
        token: 'tok_xyz',
      )).called(1);
    });
  });

  group('updateProfilePhoto()', () {
    test('does nothing when uid is null', () async {
      when(mockAuth.currentUid).thenReturn(null);
      final ctrl = await buildController();
      await ctrl.updateProfilePhoto(File('/tmp/fake.jpg'));
    });
  });
}