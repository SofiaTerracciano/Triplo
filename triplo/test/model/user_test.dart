import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';


/// Fake classes per coprire toMap()
class FakeDiary implements Diary {
  @override
  String get diaryId => "diary_1";
}

class FakeTrekking implements Trekking {
  @override
  String get documentId => "trek_1";
}

void main() {
  group('Users FULL coverage test', () {

    test('Constructor + getters', () {
      final user = Users(
        uid: "1",
        username: "user",
        name: "Mario",
        surname: "Rossi",
        email: "test@test.com",
        birthdate: DateTime(1990),
        followers: [],
        following: [],
        publicDiaryPages: [],
        privateDiaryPages: [],
        savedTrekkings: [],
        level: "Beginner",
        advanced: 1,
        intermediate: 2,
      );

      expect(user.uid, "1");
      expect(user.username, "user");
      expect(user.name, "Mario");
      expect(user.surname, "Rossi");
      expect(user.email, "test@test.com");
      expect(user.level, "Beginner");
      expect(user.advanced, 1);
      expect(user.intermediate, 2);
    });

    test('Setters coverage', () {
      final user = Users(
        uid: "1",
        username: "a",
        name: "b",
        surname: "c",
        email: "d",
        birthdate: DateTime.now(),
        followers: [],
        following: [],
        publicDiaryPages: [],
        privateDiaryPages: [],
        savedTrekkings: [],
        level: "",
        advanced: 0,
        intermediate: 0,
      );

      user.username = "new";
      user.name = "name";
      user.surname = "surname";
      user.email = "mail";
      user.level = "Advanced";
      user.advanced = 10;
      user.intermediate = 20;
      user.photoProfile = "url";

      expect(user.username, "new");
      expect(user.photoProfile, "url");
      expect(user.level, "Advanced");
      expect(user.advanced, 10);
      expect(user.intermediate, 20);
    });

    test('toMap FULL coverage (with lists)', () {
      final follower = Users(
        uid: "f1",
        username: "follower",
        name: "",
        surname: "",
        email: "",
        birthdate: DateTime.now(),
        followers: [],
        following: [],
        publicDiaryPages: [],
        privateDiaryPages: [],
        savedTrekkings: [],
        level: "",
        advanced: 0,
        intermediate: 0,
      );

      final user = Users(
        uid: "1",
        username: "user",
        name: "Mario",
        surname: "Rossi",
        email: "test@test.com",
        birthdate: DateTime(1990),
        followers: [follower],
        following: [follower],
        publicDiaryPages: [FakeDiary()],
        privateDiaryPages: [FakeDiary()],
        savedTrekkings: [FakeTrekking()],
        level: "Pro",
        advanced: 3,
        intermediate: 4,
      );

      final map = user.toMap();

      expect(map["Followers"], ["f1"]);
      expect(map["Following"], ["f1"]);
      expect(map["Public_diary"], ["diary_1"]);
      expect(map["Private_diary"], ["diary_1"]);
      expect(map["Saved_trekkings"], ["trek_1"]);
      expect(map["Advanced"], 3);
      expect(map["Intermediate"], 4);
    });

    test('fromMap - full valid data', () {
      final map = <String, dynamic>{
        "Username": "user",
        "Name": "Mario",
        "Surname": "Rossi",
        "Email": "mail",
        "Birthdate": "2000-01-01T00:00:00.000",
        "Photo_profile": "img",
        "Level": "Pro",
        "Advanced": 5,
        "Intermediate": 6,
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.username, "user");
      expect(user.birthdate.year, 2000);
      expect(user.photoProfile, "img");
      expect(user.advanced, 5);
      expect(user.intermediate, 6);
    });

    test('fromMap - fallback username/email lowercase', () {
      final map = <String, dynamic>{
        "username": "lower",
        "email": "lower@mail",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.username, "lower");
      expect(user.email, "lower@mail");
    });

    test('fromMap - int parsing from string', () {
      final map = <String, dynamic>{
        "Advanced": "10",
        "Intermediate": "20",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.advanced, 10);
      expect(user.intermediate, 20);
    });

    test('fromMap - invalid int fallback', () {
      final map = <String, dynamic>{
        "Advanced": "abc",
        "Intermediate": null,
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.advanced, 0);
      expect(user.intermediate, 0);
    });

    test('Birthdate parsing - valid', () {
      final map = <String, dynamic>{
        "Birthdate": "2010-01-01T00:00:00.000",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.birthdate.year, 2010);
    });

    test('Birthdate parsing - fallback registerdate', () {
      final map = <String, dynamic>{
        "registerdate": "2015-01-01T00:00:00.000",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.birthdate.year, 2015);
    });

    test('Birthdate parsing - invalid → default', () {
      final map = <String, dynamic>{
        "Birthdate": "invalid",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.birthdate.year, 2000);
    });

    test('Photo fallback (photoURL)', () {
      final map = <String, dynamic>{
        "photoURL": "firebase",
      };

      final user = Users.fromMap(map, uid: "1");

      expect(user.photoProfile, "firebase");
    });

    test('Lists always empty in fromMap', () {
      final user = Users.fromMap(<String, dynamic>{}, uid: "1");

      expect(user.followers.isEmpty, true);
      expect(user.following.isEmpty, true);
      expect(user.publicDiaryPages.isEmpty, true);
      expect(user.privateDiaryPages.isEmpty, true);
      expect(user.savedTrekkings.isEmpty, true);
    });
  });
}