import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

final List<LatLng> points = [
  LatLng(46.241515, 10.800153),
  LatLng(46.241503, 10.800086),
  LatLng(46.241515, 10.800021),
  LatLng(46.241533, 10.799957),
  LatLng(46.241551, 10.799891),
  LatLng(46.241581, 10.799841),
  LatLng(46.241590, 10.799761),
  LatLng(46.241622, 10.799817),
  LatLng(46.241615, 10.799753),
  LatLng(46.241579, 10.799706),
  LatLng(46.241552, 10.799641),
  LatLng(46.241549, 10.799576),
  LatLng(46.241549, 10.799497),
  LatLng(46.241523, 10.799434),
  LatLng(46.241503, 10.799370),
  LatLng(46.241503, 10.799301),
  LatLng(46.241492, 10.799227),
  LatLng(46.241482, 10.799164),
  LatLng(46.241463, 10.799104),
  LatLng(46.241459, 10.799031),
  LatLng(46.241448, 10.798959),
  LatLng(46.241436, 10.798888),
  LatLng(46.241420, 10.798815),
  LatLng(46.241398, 10.798756),
  LatLng(46.241381, 10.798688),
  LatLng(46.241372, 10.798613),
  LatLng(46.241363, 10.798548),
  LatLng(46.241347, 10.798487),
  LatLng(46.241325, 10.798418),
  LatLng(46.241294, 10.798365),
  LatLng(46.241269, 10.798307),
  LatLng(46.241288, 10.798245),
  LatLng(46.241338, 10.798220),
  LatLng(46.241384, 10.798203),
  LatLng(46.241380, 10.798135),
  LatLng(46.241449, 10.798186),
  LatLng(46.241477, 10.798133),
  LatLng(46.241523, 10.798092),
  LatLng(46.241547, 10.798030),
  LatLng(46.241592, 10.798005),
  LatLng(46.241641, 10.798011),
  LatLng(46.241690, 10.797997),
  LatLng(46.241737, 10.797999),
  LatLng(46.241783, 10.798013),
  LatLng(46.241839, 10.798037),
  LatLng(46.241881, 10.798064),
  LatLng(46.241940, 10.798061),
  LatLng(46.241984, 10.798078),
  LatLng(46.242034, 10.798098),
  LatLng(46.242081, 10.798102),
  LatLng(46.242115, 10.798147),
  LatLng(46.242162, 10.798163),
  LatLng(46.242214, 10.798169),
  LatLng(46.242261, 10.798160),
  LatLng(46.242306, 10.798161),
  LatLng(46.242350, 10.798120),
  LatLng(46.242399, 10.798128),
  LatLng(46.242444, 10.798165),
  LatLng(46.242498, 10.798170),
  LatLng(46.242516, 10.798231),
  LatLng(46.242559, 10.798256),
  LatLng(46.242585, 10.798313),
  LatLng(46.242626, 10.798361),
  LatLng(46.242610, 10.798428),
  LatLng(46.242655, 10.798416),
  LatLng(46.242713, 10.798436),
  LatLng(46.242724, 10.798501),
  LatLng(46.242765, 10.798530),
  LatLng(46.242815, 10.798555),
  LatLng(46.242813, 10.798620),
  LatLng(46.242826, 10.798683),
  LatLng(46.242834, 10.798750),
  LatLng(46.242846, 10.798814),
  LatLng(46.242871, 10.798881),
  LatLng(46.242904, 10.798930),
  LatLng(46.242916, 10.798993),
  LatLng(46.242914, 10.799066),
  LatLng(46.242893, 10.799137),
  LatLng(46.242903, 10.799205),
  LatLng(46.242913, 10.799269),
  LatLng(46.242897, 10.799330),
  LatLng(46.242926, 10.799384),
  LatLng(46.242949, 10.799451),
  LatLng(46.242935, 10.799519),
  LatLng(46.242937, 10.799584),
  LatLng(46.242937, 10.799654),
  LatLng(46.242980, 10.799688),
  LatLng(46.243004, 10.799748),
  LatLng(46.243032, 10.799802),
  LatLng(46.243026, 10.799876),
  LatLng(46.243008, 10.799943),
  LatLng(46.242992, 10.800013),
  LatLng(46.242952, 10.800055),
  LatLng(46.242950, 10.800121),
  LatLng(46.242945, 10.800188),
  LatLng(46.242926, 10.800252),
  LatLng(46.242886, 10.800303),
  LatLng(46.242881, 10.800425),
  LatLng(46.242867, 10.800495),
  LatLng(46.242823, 10.800565),
  LatLng(46.242819, 10.800639),
  LatLng(46.242808, 10.800718),
  LatLng(46.242763, 10.800757),
  LatLng(46.242727, 10.800814),
  LatLng(46.242720, 10.800897),
  LatLng(46.242712, 10.800967),
  LatLng(46.242698, 10.801030),
  LatLng(46.242700, 10.801101),
  LatLng(46.242714, 10.801168),
  LatLng(46.242728, 10.801234),
  LatLng(46.242723, 10.801312),
  LatLng(46.242706, 10.801382),
  LatLng(46.242666, 10.801438),
  LatLng(46.242619, 10.801483),
  LatLng(46.242575, 10.801526),
  LatLng(46.242545, 10.801591),
  LatLng(46.242524, 10.801649),
  LatLng(46.242501, 10.801718),
  LatLng(46.242480, 10.801779),
  LatLng(46.242468, 10.801842),
  LatLng(46.242441, 10.801899),
  LatLng(46.242418, 10.801956),
  LatLng(46.242379, 10.801999),
  LatLng(46.242334, 10.802033),
  LatLng(46.242291, 10.802072),
  LatLng(46.242244, 10.802103),
  LatLng(46.242197, 10.802116),
  LatLng(46.242142, 10.802124),
  LatLng(46.242089, 10.802117),
  LatLng(46.242042, 10.802122),
  LatLng(46.241985, 10.802129),
  LatLng(46.241940, 10.802134),
  LatLng(46.241911, 10.802076),
  LatLng(46.241896, 10.801971),
  LatLng(46.241854, 10.801937),
  LatLng(46.241819, 10.801895),
  LatLng(46.241788, 10.801846),
  LatLng(46.241737, 10.801790),
  LatLng(46.241697, 10.801754),
  LatLng(46.241655, 10.801712),
  LatLng(46.241614, 10.801685),
  LatLng(46.241568, 10.801675),
  LatLng(46.241516, 10.801659),
  LatLng(46.241508, 10.801591),
  LatLng(46.241506, 10.801520),
  LatLng(46.241518, 10.801419),
  LatLng(46.241536, 10.801346),
  LatLng(46.241536, 10.801275),
  LatLng(46.241541, 10.801201),
  LatLng(46.241553, 10.801125),
  LatLng(46.241571, 10.801061),
  LatLng(46.241583, 10.800997),
  LatLng(46.241588, 10.800929),
  LatLng(46.241581, 10.800862),
  LatLng(46.241587, 10.800790),
];


class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({super.key});

  Future<void> uploadPoints() async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('trekking').doc('HXJLiwWo2IdNf6l6tSqw');

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
