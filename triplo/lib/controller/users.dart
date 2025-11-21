import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triplo/model/users.dart';

class UserController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create
  Future<void> createUser(Users user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  // Read singol one
  Future<Users?> getUser(String id) async {
    final doc = await _db.collection('users').doc(id).get();

    if (doc.exists) {
      return Users.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // READ list of users
  Stream<List<Users>> usersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Users.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Update
  Future<void> updateUser(Users user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  // Delete
  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}