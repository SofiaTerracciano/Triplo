import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

List<LatLng> points = [
  LatLng(46.188769, 10.827545),
  LatLng(46.188701, 10.827552),
  LatLng(46.188589, 10.827409),
  LatLng(46.188523, 10.827290),
  LatLng(46.188434, 10.827057),
  LatLng(46.188362, 10.826888),
  LatLng(46.188289, 10.826720),
  LatLng(46.188206, 10.826555),
  LatLng(46.188126, 10.826388),
  LatLng(46.188043, 10.826223),
  LatLng(46.187961, 10.826057),
  LatLng(46.187880, 10.825892),
  LatLng(46.187802, 10.825725),
  LatLng(46.187720, 10.825559),
  LatLng(46.187637, 10.825394),
  LatLng(46.187555, 10.825227),
  LatLng(46.187474, 10.825062),
  LatLng(46.187391, 10.824895),
  LatLng(46.187311, 10.824729),
  LatLng(46.187228, 10.824563),
  LatLng(46.187146, 10.824397),
  LatLng(46.187062, 10.824231),
  LatLng(46.186980, 10.824065),
  LatLng(46.186897, 10.823899),
  LatLng(46.186815, 10.823733),
  LatLng(46.186733, 10.823567),
  LatLng(46.186650, 10.823402),
  LatLng(46.186568, 10.823235),
  LatLng(46.186485, 10.823070),
  LatLng(46.186403, 10.822904),
  LatLng(46.186321, 10.822738),
  LatLng(46.186237, 10.822573),
  LatLng(46.186156, 10.822405),
  LatLng(46.186073, 10.822241),
  LatLng(46.185990, 10.822074),
  LatLng(46.185908, 10.821908),
  LatLng(46.185826, 10.821743),
  LatLng(46.185743, 10.821576),
  LatLng(46.185661, 10.821411),
  LatLng(46.185578, 10.821245),
  LatLng(46.185496, 10.821079),
  LatLng(46.185413, 10.820914),
  LatLng(46.185331, 10.820748),
  LatLng(46.185249, 10.820581),
  LatLng(46.185167, 10.820415),
  LatLng(46.185084, 10.820250),
  LatLng(46.185002, 10.820084),
  LatLng(46.184919, 10.819918),
  LatLng(46.184837, 10.819752),
  LatLng(46.184755, 10.819587),
  LatLng(46.184672, 10.819420),
  LatLng(46.184590, 10.819255),
  LatLng(46.184508, 10.819089),
  LatLng(46.184425, 10.818923),
  LatLng(46.184343, 10.818758),
  LatLng(46.184260, 10.818591),
  LatLng(46.184178, 10.818426),
  LatLng(46.184096, 10.818260),
  LatLng(46.184014, 10.818094),
  LatLng(46.183931, 10.817928),
  LatLng(46.183849, 10.817763),
  LatLng(46.183767, 10.817596),
  LatLng(46.183684, 10.817431),
  LatLng(46.183602, 10.817265),
  LatLng(46.183519, 10.817099),
  LatLng(46.183437, 10.816933),
  LatLng(46.183355, 10.816768),
  LatLng(46.183272, 10.816601),
  LatLng(46.183190, 10.816436),
  LatLng(46.183108, 10.816270),
  LatLng(46.183025, 10.816104),
  LatLng(46.182943, 10.815938),
  LatLng(46.182860, 10.815773),
  LatLng(46.182778, 10.815606),
  LatLng(46.182696, 10.815441),
  LatLng(46.182613, 10.815275),
  LatLng(46.182531, 10.815109),
  LatLng(46.182449, 10.814944),
  LatLng(46.182366, 10.814777),
  LatLng(46.182284, 10.814612),
  LatLng(46.182201, 10.814445),
  LatLng(46.182119, 10.814279),
  LatLng(46.182037, 10.814114),
  LatLng(46.181954, 10.813948),
  LatLng(46.181872, 10.813781),
  LatLng(46.181790, 10.813616),
  LatLng(46.181707, 10.813450),
  LatLng(46.181625, 10.813284),
  LatLng(46.181543, 10.813119),
  LatLng(46.181460, 10.812952),
  LatLng(46.181378, 10.812787),
  LatLng(46.181296, 10.812621),
  LatLng(46.181213, 10.812455),
  LatLng(46.181131, 10.812289),
  LatLng(46.181048, 10.812124),
  LatLng(46.180966, 10.811958),
  LatLng(46.180884, 10.811791),
  LatLng(46.180801, 10.811626),
  LatLng(46.180719, 10.811460),
  LatLng(46.180637, 10.811294),
  LatLng(46.180554, 10.811129),
  LatLng(46.180472, 10.810962),
  LatLng(46.180389, 10.810797),
  LatLng(46.180307, 10.810631),
  LatLng(46.180225, 10.810465),
  LatLng(46.180142, 10.810300),
  LatLng(46.180060, 10.810133),
  LatLng(46.179977, 10.809968),
  LatLng(46.179895, 10.809802),
  LatLng(46.179813, 10.809636),
  LatLng(46.179730, 10.809470),
  LatLng(46.179648, 10.809305),
  LatLng(46.179566, 10.809138),
  LatLng(46.179483, 10.808973),
  LatLng(46.179401, 10.808807),
  LatLng(46.179319, 10.808641),
  LatLng(46.179236, 10.808476),
  LatLng(46.179154, 10.808309),
  LatLng(46.179072, 10.808144),
  LatLng(46.178989, 10.807978),
  LatLng(46.178907, 10.807812),
  LatLng(46.178825, 10.807646),
  LatLng(46.178742, 10.807481),
];

class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('tJsGcSQnni8fMGRe3j03');

    // Converti i LatLng in GeoPoint
    final pointsGeo = points.map((p) => GeoPoint(p.latitude, p.longitude)).toList();

    try {
      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data()?['Points'] == null) {
        // Caso 1: il campo Points NON ESISTE --> lo creo da zero
        await docRef.set({
          'Points': pointsGeo,
        }, SetOptions(merge: true));

        print("Array 'Points' creato e popolato!");
      } else {
        // Caso 2: il campo Points esiste --> aggiungo i punti
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
