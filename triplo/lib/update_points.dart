import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

final List<LatLng> points = [
  LatLng(46.102319, 10.738632),
  LatLng(46.102585, 10.738795),
  LatLng(46.102985, 10.738925),
  LatLng(46.103374, 10.73904),
  LatLng(46.103764, 10.739154),
  LatLng(46.104154, 10.739269),
  LatLng(46.104544, 10.739383),
  LatLng(46.10474, 10.739439),
  LatLng(46.105025, 10.73963),
  LatLng(46.105144, 10.739654),
  LatLng(46.105522, 10.739643),
  LatLng(46.105831, 10.739635),
  LatLng(46.106152, 10.739659),
  LatLng(46.106301, 10.73967),
  LatLng(46.106433, 10.7395),
  LatLng(46.106504, 10.739568),
];

class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('TEB9WuLT6XHe8UhSJi0Q');

    // Converti i LatLng in GeoPoint
    final pointsGeo = points
        .map((p) => GeoPoint(p.latitude, p.longitude))
        .toList();

    try {
      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data()?['Points'] == null) {
        // Caso 1: il campo Points NON ESISTE --> lo creo da zero
        await docRef.set({'Points': pointsGeo}, SetOptions(merge: true));

        print("Array 'Points' creato e popolato!");
      } else {
        // Caso 2: il campo Points esiste --> aggiungo i punti
        await docRef.update({'Points': FieldValue.arrayUnion(pointsGeo)});

        print("Punti aggiunti all’array esistente!");
      }
    } catch (e) {
      print("Errore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Upload Punti")),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadPoints,
          child: const Text("Carica punti nel Database"),
        ),
      ),
    );
  }
}
