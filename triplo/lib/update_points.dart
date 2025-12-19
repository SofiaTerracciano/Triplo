import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

const List<LatLng> points = [
  LatLng(46.1288, 10.7431), // Rifugio San Giuliano
  LatLng(46.1345, 10.7465), // Sentiero 230 (Nord-Ovest)
  LatLng(46.1382, 10.7530), // Malga Campostril
  LatLng(46.1350, 10.7645), // Sella di Campo
  LatLng(46.1285, 10.7682), // Pozza delle Vacche (Punto più a est)
  LatLng(46.1220, 10.7635), // Versante Sud-Est (Sentiero 221)
  LatLng(46.1185, 10.7580), // Malga Campantìl
  LatLng(46.1168, 10.7515), // Lago di Vacarsa
  LatLng(46.1172, 10.7485), // Bocchetta dell'Acqua Fredda (Sud)
  LatLng(46.1230, 10.7442), // Lago Garzoné
  LatLng(46.1288, 10.7431), // Chiusura anello
];


class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('k7Qv4bHxBy4fFDsxofaL');

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
