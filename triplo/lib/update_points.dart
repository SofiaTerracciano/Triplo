/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';



class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('CrbwYeJUulYAzfuAqmPl');

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
}*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<List<GeoPoint>> loadPointsFromJson() async {
    // Carica il file JSON dagli assets
    final jsonString = await rootBundle.loadString('points.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    // Converte in GeoPoint
    return jsonData
        .map((p) => GeoPoint(
              (p['lat'] as num).toDouble(),
              (p['lon'] as num).toDouble(),
            ))
        .toList();
  }

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('QXbf9XjSlOvRdUQ4ZhxV');

    try {
      final pointsGeo = await loadPointsFromJson();

      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data()?['Points'] == null) {
        // Caso 1: campo Points NON esiste
        await docRef.set(
          {'Points': pointsGeo},
          SetOptions(merge: true),
        );

        print("Array 'Points' creato e popolato!");
      } else {
        // Caso 2: campo Points esiste
        await docRef.update({
          'Points': FieldValue.arrayUnion(pointsGeo),
        });

        print("Punti aggiunti all’array esistente!");
      }
    } catch (e) {
      print("Errore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Punti")),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadPoints,
          child: const Text("Carica punti nel Database"),
        ),
      ),
    );
  }
}

// Serve per prendere tutti i trekking e creare l'indice di ricerca
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBuildTrekkingIndexPage extends StatelessWidget {
  const AdminBuildTrekkingIndexPage({super.key});

  Future<void> buildTrekkingIndex(BuildContext context) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    try {
      // Prendo tutti i trekking
      final trekkingSnap = await db.collection('trekking').get();

      if (trekkingSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun trekking trovato')),
        );
        return;
      }

      final WriteBatch batch = db.batch();

      for (final doc in trekkingSnap.docs) {
        final data = doc.data();

        if (!data.containsKey('Name')) continue;

        final String trekkingId = doc.id;
        final String name = data['Name'];

        final indexRef =
            db.collection('trekking_index').doc(trekkingId);

        batch.set(indexRef, {
          'Trekking_id': trekkingId,
          'Trekking_name': name,
          'Normalized': name.toLowerCase().trim(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trekking index creato (${trekkingSnap.docs.length} elementi)',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Build Trekking Index'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.build),
          label: const Text('Crea / Aggiorna Trekking Index'),
          onPressed: () => buildTrekkingIndex(context),
        ),
      ),
    );
  }
}*/
