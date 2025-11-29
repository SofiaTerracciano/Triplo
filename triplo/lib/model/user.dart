import 'package:firebase_auth/firebase_auth.dart';

import 'diary.dart';
class Users {
  String _uid; //user id on firebase
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
    required String uid,
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
    String? photoProfile,
  }) : _uid = uid,
        _username = username,
       _name = name,
       _surname = surname,
       _birthdate = birthdate,
       _email = email,
       _followers = followers,
       _following = following,
      _publicDiaryPages = publicDiaryPages,
      _privateDiaryPages = privateDiaryPages,
      _savedTrekkings = savedTrekkings,
        _photoProfile = photoProfile ?? "";


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
  String get uid => _uid;

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
  set savedTrekkings(List<Diary> savedTrekkings) => _savedTrekkings = savedTrekkings;

  /*
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
   */

  /// Converts this Users object into a Map<String, dynamic> that can be stored in Firestore.
  /// IMPORTANT: fields  as followers, following, diary pages, saved trekkings cannot be saved as full Dart objects.
  /// Firestore only stores primitive values and simple collections.
  /// Only the IDs (e.g., user IDs or diary IDs) of related objects are saved on firestore.
  /// The actual reconstruction of related Users and Diary objects happens inside the Controller where each ID is fetched and converted back into a full object.
  Map<String, dynamic> toMap() {
    return {
      "Uid": _uid,
      "Username": _username,
      "Photo_profile": _photoProfile,
      "Name": _name,
      "Surname": _surname,
      "Birthdate": _birthdate.toIso8601String(),
      "Email": _email,

      "Followers": _followers.map((u) => u.uid).toList(),
      "Following": _following.map((u) => u.uid).toList(),

      "Public_diary": _publicDiaryPages.map((d) => d.diaryId).toList(),
      "Private_diary": _privateDiaryPages.map((d) => d.diaryId).toList(),
      "Saved_trekkings": _savedTrekkings.map((d) => d.diaryId).toList(),
    };
  }

  /*
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
   */






  /// Creates a Users object from Firestore data (a Map<String, dynamic>).
  /// IMPORTANT: Firestore does not store full Users or Diary objects, only their IDs.
  /// Therefore, fromMap() can only populate the "primitive" fields of the model
  /// Lists such as followers, following, publicDiaryPages, privateDiaryPages,
  /// and savedTrekkings cannot be reconstructed here because Firestore only stores IDs.
  /// These lists are intentionally left empty here and are later populated in the UserController
  ///  by converting the ID into a User or Diary object.
  /*
  factory Users.fromMap(Map<String, dynamic> map, {required String uid}) {
    return Users(
      uid: uid,
      username: map["Username"] ?? "",
      name: map["Name"] ?? "",
      surname: map["Surname"] ?? "",
      email: map["Email"] ?? "",

      birthdate: map["Birthdate"] != null
          ? DateTime.parse(map["Birthdate"])
          : DateTime(2000, 1, 1),

      photoProfile: map["Photo_profile"],

      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],
    );
  }
   */
  factory Users.fromMap(Map<String, dynamic> map, {required String uid}) {
    return Users(
      uid: uid,
      username: (map["Username"] ?? map["username"] ?? "") as String,
      name: (map["Name"] ?? "") as String,
      surname: (map["Surname"] ?? "") as String,
      email: (map["Email"] ?? map["email"] ?? "") as String,
      birthdate: _parseBirthdate(map),
      photoProfile: (map["Photo_profile"] ?? map["photoURL"] ?? "") as String?,
      followers: [],
      following: [],
      publicDiaryPages: [],
      privateDiaryPages: [],
      savedTrekkings: [],
    );
  }

  static DateTime _defaultBirthdate = DateTime(2000, 1, 1);

  static DateTime _parseBirthdate(Map<String, dynamic> map) {
    final raw = map["Birthdate"];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ?? _defaultBirthdate;
    }
    // gestione legacy: se esiste un timestamp "registerdate"
    final reg = map["registerdate"];
    if (reg is DateTime) return reg;
    return _defaultBirthdate;
  }
}
