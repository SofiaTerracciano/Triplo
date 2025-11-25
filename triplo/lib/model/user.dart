import 'package:firebase_auth/firebase_auth.dart';

import 'diary.dart';
class Users {
  String _username;
  String? _photoProfile; 
  String _name;
  String _surname;
  DateTime _birthdate;
  String _email;
  List<Users> _followers;
  List<Users> _following;
  List<Diary> _publicDiaryPages;
  List<Diary> _privateDiaryPages;
  List<Diary> _savedTrekkings;

  Users({
    required String username,
    required String name,
    required String surname,
    required String email,
    required DateTime birthdate,
    required List<Users> followers,
    required List<Users> following,
    required List<Diary> publicDiaryPages,
    required List<Diary> privateDiaryPages,
    required List<Diary> savedTrekkings,
  }) : _username = username,
       _name = name,
       _surname = surname,
       _birthdate = birthdate,
       _email = email,
       _followers = followers,
       _following = following,
      _publicDiaryPages = publicDiaryPages, 
      _privateDiaryPages = privateDiaryPages,
      _savedTrekkings = savedTrekkings;

  // Getters
  String get username => _username;
  String? get photoProfile => _photoProfile;
  String get name => _name;
  String get surname => _surname;
  DateTime get birthdate => _birthdate;
  String get email => _email;
  List<Users> get followers => _followers;
  List<Users> get following => _following;
  List<Diary> get publicDiaryPages => _publicDiaryPages;
  List<Diary> get privateDiaryPages => _privateDiaryPages;
  List<Diary> get savedTrekkings => _savedTrekkings;

  // Setters
  set username(String username) => _username = username;
  set photoProfile(String? photoProfile) => _photoProfile = photoProfile;
  set name(String name) => _name = name;
  set surname(String surname) => _surname = surname;
  set birthdate(DateTime birthdate) => _birthdate = birthdate;
  set email(String email) => _email = email;
  set followers(List<Users> followers) => _followers = followers;
  set following(List<Users> following) => _following = following;
  set publicDiaryPages(List<Diary> pubblicPages) => _publicDiaryPages = pubblicPages;
  set privateDiaryPages(List<Diary> privatePages) => _privateDiaryPages = privatePages;
  set savedTrekkeings(List<Diary> savedTrekkings) => _savedTrekkings = savedTrekkings;

  Map<String, dynamic> toMap() {
    return {
      "Username": _username,
      "Photo_profile": _photoProfile,
      "Name": _name,
      "Surname": _surname,
      "Birthdate": _birthdate.toIso8601String(),
      "Email": _email,
      "Followers": _followers,
      "Following": _following,
      "Public_diary": _publicDiaryPages,
      "Private_diary": _privateDiaryPages,
      "Saved_trekkings": _savedTrekkings,
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      username: map["Username"],
      name: map["Name"],
      surname: map["Surname"],
      birthdate: DateTime.parse(map["Birthdate"]),
      email: map["Email"],
      followers: List<Users>.from(map["Followers"]),
      following: List<Users>.from(map["Following"]),
      publicDiaryPages: List<Diary>.from(map["Public_diary"]),
      privateDiaryPages: List<Diary>.from(map["Private_diary"]),
      savedTrekkings: List<Diary>.from(map["Saved_trekkings"]),
    );
  }
}
