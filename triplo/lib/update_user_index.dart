import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> updateUsersIndex() async {
  final db = FirebaseFirestore.instance;
  final snap = await db.collection("users").get();

  for (final doc in snap.docs) {
    final data = doc.data();
    final uid = doc.id;
    final username = (data["Username"] ?? data["username"] ?? "") as String;

    if (username.isEmpty) {
      if (kDebugMode) {
        print("user $uid senza Username, salto");
      }
      continue;
    }

    try {
      await db.collection("users_index").doc(uid).set({
        "uid": uid,
        "username": username,
        "normalized": username.toLowerCase(),
      });
      if (kDebugMode) print("indicizzato $username ($uid)");
    } catch (e, st) {
      if (kDebugMode) {
        print("errore indicizzando $uid: $e\n$st");
      }
    }
  }

  if (kDebugMode) print("Update users_index completato");
}