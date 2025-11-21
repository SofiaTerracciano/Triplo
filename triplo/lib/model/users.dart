import 'package:intl/intl.dart';

class Users {
  final String id; // username
  final String name;
  final String surname;
  final String email;
  final DateTime birthdate;

  Users({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.birthdate,
  });

  // From Firestore to Model
  factory Users.fromMap(String id, Map<String, dynamic> data) {
    return Users(
      id: id,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      email: data['email'] ?? '',
      birthdate: data['birthdate'] ?? DateFormat('yyyy-MM-dd'),
    );
  }

  // From Model to Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': id,
      'name': name,
      'surname': surname,
      'email': email,
      'birthdate': birthdate,
    };
  }
}
