class Users {
  String _username;
  String? _userprofile; 
  String _name;
  String _surname;
  DateTime _birthdate;
  String _email;

  Users({
    required String username,
    required String name,
    required String surname,
    required String email,
    required DateTime birthdate,
  }) : _username = username,
       _name = name,
       _surname = surname,
       _birthdate = birthdate,
       _email = email;

  // Getters
  String get username => _username;
  String? get userprofile => _userprofile;
  String get name => _name;
  String get surname => _surname;
  DateTime get birthdate => _birthdate;
  String get email => _email;

  // Setters
  set username(String value) => _username = value;
  set userprofile(String? value) => _userprofile = value;
  set name(String value) => _name = value;
  set surname(String value) => _surname = value;
  set birthdate(DateTime value) => _birthdate = value;
  set email(String value) => _email = value;
}
