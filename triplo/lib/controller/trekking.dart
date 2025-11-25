import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trekking.dart';

class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Trekking> _trekkings;

  TrekkingController({
    required List<Trekking> trekkings,
  }) : _trekkings = trekkings;

  // Getter per tutta la collezione
  List<Trekking> get allTrekkings => _trekkings;

  // Carica tutti i trekking dalla collezione
  Future<void> loadTrekkings() async {
    final snapshot = await _db.collection("trekking").get();

    _trekkings = snapshot.docs.map((doc) {
      return Trekking.fromMap(doc.data(), docId: doc.id);
    }).toList();

    notifyListeners();
  }

  // Getter trekking per indice
  Trekking getTrekkingByIndex(int index) => _trekkings[index];

  // Getter trekking per documentId
  Trekking? getTrekkingById(String documentId) {
    try {
      return _trekkings.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }
}
