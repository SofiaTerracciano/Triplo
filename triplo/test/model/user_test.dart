import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';

Users buildUser({
  String uid = 'uid_1',
  String username = 'mario_rossi',
  String name = 'Mario',
  String surname = 'Rossi',
  String email = 'mario@example.com',
  DateTime? birthdate,
  String? photoProfile,
  List<Users>? followers,
  List<Users>? following,
  List<Diary>? publicDiaryPages,
  List<Diary>? privateDiaryPages,
  List<Trekking>? savedTrekkings,
  String level = 'Beginner',
  int advanced = 2,
  int intermediate = 5,
}) {
  return Users(
    uid: uid,
    username: username,
    name: name,
    surname: surname,
    email: email,
    birthdate: birthdate ?? DateTime(1990, 6, 15),
    photoProfile: photoProfile,
    followers: followers ?? [],
    following: following ?? [],
    publicDiaryPages: publicDiaryPages ?? [],
    privateDiaryPages: privateDiaryPages ?? [],
    savedTrekkings: savedTrekkings ?? [],
    level: level,
    advanced: advanced,
    intermediate: intermediate,
  );
}

Map<String, dynamic> buildFirestoreMap({
  String username = 'mario_rossi',
  String name = 'Mario',
  String surname = 'Rossi',
  String email = 'mario@example.com',
  String birthdate = '1990-06-15T00:00:00.000',
  String photoProfile = 'https://example.com/photo.jpg',
  String level = 'Beginner',
  int advanced = 2,
  int intermediate = 5,
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
  };
}

void main() {

  group('Constructor & Getters', () {
    test('stores all fields correctly', () {
      final u = buildUser();

      expect(u.uid, 'uid_1');
      expect(u.username, 'mario_rossi');
      expect(u.name, 'Mario');
      expect(u.surname, 'Rossi');
      expect(u.email, 'mario@example.com');
      expect(u.birthdate, DateTime(1990, 6, 15));
      expect(u.level, 'Beginner');
      expect(u.advanced, 2);
      expect(u.intermediate, 5);
      expect(u.followers, isEmpty);
      expect(u.following, isEmpty);
      expect(u.publicDiaryPages, isEmpty);
      expect(u.privateDiaryPages, isEmpty);
      expect(u.savedTrekkings, isEmpty);
    });

    test('photoProfile defaults to empty string when null', () {
      final u = buildUser(photoProfile: null);
      expect(u.photoProfile, '');
    });

    test('photoProfile is stored when provided', () {
      final u = buildUser(photoProfile: 'https://example.com/photo.jpg');
      expect(u.photoProfile, 'https://example.com/photo.jpg');
    });
  });

  group('Setters', () {
    test('username setter works', () {
      final u = buildUser();
      u.username = 'luigi_verdi';
      expect(u.username, 'luigi_verdi');
    });

    test('name setter works', () {
      final u = buildUser();
      u.name = 'Luigi';
      expect(u.name, 'Luigi');
    });

    test('surname setter works', () {
      final u = buildUser();
      u.surname = 'Verdi';
      expect(u.surname, 'Verdi');
    });

    test('email setter works', () {
      final u = buildUser();
      u.email = 'luigi@example.com';
      expect(u.email, 'luigi@example.com');
    });

    test('birthdate setter works', () {
      final u = buildUser();
      u.birthdate = DateTime(2000, 1, 1);
      expect(u.birthdate, DateTime(2000, 1, 1));
    });

    test('photoProfile setter works with value', () {
      final u = buildUser();
      u.photoProfile = 'https://example.com/new.jpg';
      expect(u.photoProfile, 'https://example.com/new.jpg');
    });

    test('photoProfile setter works with null', () {
      final u = buildUser(photoProfile: 'https://example.com/photo.jpg');
      u.photoProfile = null;
      expect(u.photoProfile, isNull);
    });

    test('level setter works', () {
      final u = buildUser();
      u.level = 'Expert';
      expect(u.level, 'Expert');
    });

    test('advanced setter works', () {
      final u = buildUser();
      u.advanced = 10;
      expect(u.advanced, 10);
    });

    test('intermediate setter works', () {
      final u = buildUser();
      u.intermediate = 8;
      expect(u.intermediate, 8);
    });

    test('followers setter replaces list', () {
      final u = buildUser();
      final follower = buildUser(uid: 'uid_2', username: 'follower');
      u.followers = [follower];
      expect(u.followers.length, 1);
      expect(u.followers.first.uid, 'uid_2');
    });

    test('following setter replaces list', () {
      final u = buildUser();
      final followed = buildUser(uid: 'uid_3', username: 'followed');
      u.following = [followed];
      expect(u.following.length, 1);
      expect(u.following.first.uid, 'uid_3');
    });

    test('publicDiaryPages setter replaces list', () {
      final u = buildUser();
      u.publicDiaryPages = [];
      expect(u.publicDiaryPages, isEmpty);
    });

    test('privateDiaryPages setter replaces list', () {
      final u = buildUser();
      u.privateDiaryPages = [];
      expect(u.privateDiaryPages, isEmpty);
    });

    test('savedTrekkings setter replaces list', () {
      final u = buildUser();
      u.savedTrekkings = [];
      expect(u.savedTrekkings, isEmpty);
    });
  });

  group('toMap()', () {
    test('produces correct scalar values', () {
      final u = buildUser(
        photoProfile: 'https://example.com/photo.jpg',
        birthdate: DateTime(1990, 6, 15),
      );
      final map = u.toMap();

      expect(map['Uid'], 'uid_1');
      expect(map['Username'], 'mario_rossi');
      expect(map['Name'], 'Mario');
      expect(map['Surname'], 'Rossi');
      expect(map['Email'], 'mario@example.com');
      expect(map['Photo_profile'], 'https://example.com/photo.jpg');
      expect(map['Level'], 'Beginner');
      expect(map['Advanced'], 2);
      expect(map['Intermediate'], 5);
    });

    test('birthdate is serialized as ISO 8601 string', () {
      final u = buildUser(birthdate: DateTime(1990, 6, 15));
      final map = u.toMap();
      expect(map['Birthdate'], isA<String>());
      expect(DateTime.parse(map['Birthdate'] as String), DateTime(1990, 6, 15));
    });

    test('followers are serialized as list of UIDs', () {
      final f1 = buildUser(uid: 'f_1');
      final f2 = buildUser(uid: 'f_2');
      final u = buildUser(followers: [f1, f2]);
      final map = u.toMap();
      expect(map['Followers'], ['f_1', 'f_2']);
    });

    test('following is serialized as list of UIDs', () {
      final f = buildUser(uid: 'fng_1');
      final u = buildUser(following: [f]);
      final map = u.toMap();
      expect(map['Following'], ['fng_1']);
    });

    test('empty followers serializes to empty list', () {
      final u = buildUser();
      expect(u.toMap()['Followers'], isEmpty);
    });

    test('empty following serializes to empty list', () {
      final u = buildUser();
      expect(u.toMap()['Following'], isEmpty);
    });

    test('public_diary serializes as list of diary IDs', () {
      // requires a real or mock Diary with a diaryId getter
      final u = buildUser(publicDiaryPages: []);
      expect(u.toMap()['Public_diary'], isEmpty);
    });

    test('private_diary serializes as list of diary IDs', () {
      final u = buildUser(privateDiaryPages: []);
      expect(u.toMap()['Private_diary'], isEmpty);
    });

    test('saved_trekkings serializes as list of document IDs', () {
      final u = buildUser(savedTrekkings: []);
      expect(u.toMap()['Saved_trekkings'], isEmpty);
    });
  });

  group('fromMap()', () {
    test('parses all scalar fields correctly', () {
      final u = Users.fromMap(buildFirestoreMap(), uid: 'uid_1');

      expect(u.uid, 'uid_1');
      expect(u.username, 'mario_rossi');
      expect(u.name, 'Mario');
      expect(u.surname, 'Rossi');
      expect(u.email, 'mario@example.com');
      expect(u.photoProfile, 'https://example.com/photo.jpg');
      expect(u.level, 'Beginner');
      expect(u.advanced, 2);
      expect(u.intermediate, 5);
    });

    test('parses birthdate from ISO 8601 string', () {
      final u = Users.fromMap(buildFirestoreMap(birthdate: '1990-06-15T00:00:00.000'), uid: 'u1');
      expect(u.birthdate, DateTime(1990, 6, 15));
    });

    test('lists are always empty (IDs reconstructed by controller)', () {
      final u = Users.fromMap(buildFirestoreMap(), uid: 'u1');
      expect(u.followers, isEmpty);
      expect(u.following, isEmpty);
      expect(u.publicDiaryPages, isEmpty);
      expect(u.privateDiaryPages, isEmpty);
      expect(u.savedTrekkings, isEmpty);
    });

    test('accepts lowercase "username" key (legacy fallback)', () {
      final map = buildFirestoreMap();
      map.remove('Username');
      map['username'] = 'legacy_user';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.username, 'legacy_user');
    });

    test('accepts lowercase "email" key (legacy fallback)', () {
      final map = buildFirestoreMap();
      map.remove('Email');
      map['email'] = 'legacy@example.com';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.email, 'legacy@example.com');
    });

    test('accepts "photoURL" key (legacy fallback)', () {
      final map = buildFirestoreMap();
      map.remove('Photo_profile');
      map['photoURL'] = 'https://example.com/legacy.jpg';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.photoProfile, 'https://example.com/legacy.jpg');
    });

    test('defaults username to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Username');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.username, '');
    });

    test('defaults name to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Name');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.name, '');
    });

    test('defaults surname to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Surname');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.surname, '');
    });

    test('defaults email to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Email');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.email, '');
    });

    test('Advanced as String is parsed to int', () {
      final map = buildFirestoreMap();
      map['Advanced'] = '7';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.advanced, 7);
    });

    test('Intermediate as String is parsed to int', () {
      final map = buildFirestoreMap();
      map['Intermediate'] = '3';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.intermediate, 3);
    });

    test('Advanced invalid string defaults to 0', () {
      final map = buildFirestoreMap();
      map['Advanced'] = 'non_numero';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.advanced, 0);
    });

    test('Intermediate invalid string defaults to 0', () {
      final map = buildFirestoreMap();
      map['Intermediate'] = 'non_numero';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.intermediate, 0);
    });
  });

  group('_parseBirthdate (via fromMap)', () {
    test('parses valid Birthdate string', () {
      final u = Users.fromMap(buildFirestoreMap(birthdate: '2000-03-20T00:00:00.000'), uid: 'u1');
      expect(u.birthdate, DateTime(2000, 3, 20));
    });

    test('falls back to default when Birthdate is empty string', () {
      final map = buildFirestoreMap(birthdate: '');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(2000, 1, 1));
    });

    test('falls back to default when Birthdate is missing', () {
      final map = buildFirestoreMap();
      map.remove('Birthdate');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(2000, 1, 1));
    });

    test('falls back to default when Birthdate is invalid string', () {
      final map = buildFirestoreMap(birthdate: 'data_non_valida');
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(2000, 1, 1));
    });

    test('uses legacy "registerdate" string when Birthdate is absent', () {
      final map = buildFirestoreMap();
      map.remove('Birthdate');
      map['registerdate'] = '1995-08-10T00:00:00.000';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(1995, 8, 10));
    });

    test('uses legacy "registerdate" DateTime when Birthdate is absent', () {
      final map = buildFirestoreMap();
      map.remove('Birthdate');
      map['registerdate'] = DateTime(1995, 8, 10);
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(1995, 8, 10));
    });

    test('falls back to default when registerdate is also invalid', () {
      final map = buildFirestoreMap();
      map.remove('Birthdate');
      map['registerdate'] = 'not_a_date';
      final u = Users.fromMap(map, uid: 'u1');
      expect(u.birthdate, DateTime(2000, 1, 1));
    });
  });

  group('Round-trip toMap() → fromMap()', () {
    test('scalar fields survive serialization round-trip', () {
      final original = buildUser(
        photoProfile: 'https://example.com/photo.jpg',
        birthdate: DateTime(1988, 4, 22),
        level: 'Expert',
        advanced: 3,
        intermediate: 7,
      );

      final map = original.toMap();
      final restored = Users.fromMap(map, uid: original.uid);

      expect(restored.uid, original.uid);
      expect(restored.username, original.username);
      expect(restored.name, original.name);
      expect(restored.surname, original.surname);
      expect(restored.email, original.email);
      expect(restored.birthdate, original.birthdate);
      expect(restored.photoProfile, original.photoProfile);
      expect(restored.level, original.level);
      expect(restored.advanced, original.advanced);
      expect(restored.intermediate, original.intermediate);
    });

    test('lists are empty after round-trip (by design)', () {
      final f = buildUser(uid: 'f1');
      final original = buildUser(followers: [f], following: [f]);
      final map = original.toMap();
      final restored = Users.fromMap(map, uid: original.uid);

      expect(restored.followers, isEmpty);
      expect(restored.following, isEmpty);
    });
  });
}