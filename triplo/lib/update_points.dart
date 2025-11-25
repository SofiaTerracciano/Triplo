import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'firebase_options.dart';

final List<LatLng> points = [
  LatLng(46.173287, 10.737364),
  LatLng(46.172935, 10.737014),
  LatLng(46.172011, 10.735069),
  LatLng(46.171774, 10.734817),
  LatLng(46.171936, 10.734740),
  LatLng(46.171401, 10.729228),
  LatLng(46.171252, 10.729061),
  LatLng(46.170813, 10.727091),
  LatLng(46.170373, 10.726367),
  LatLng(46.170334, 10.725488),
  LatLng(46.169537, 10.723477),
  LatLng(46.169651, 10.723242),
  LatLng(46.169546, 10.722581),
  LatLng(46.168905, 10.721334),
  LatLng(46.168531, 10.721998),
  LatLng(46.168157, 10.721197),
  LatLng(46.168017, 10.719532),
  LatLng(46.168458, 10.717708),
  LatLng(46.168007, 10.716186),
  LatLng(46.168103, 10.716167),
  LatLng(46.168109, 10.715545),
  LatLng(46.168271, 10.715434),
  LatLng(46.168165, 10.714746),
  LatLng(46.168290, 10.714082),
  LatLng(46.168632, 10.714133),
  LatLng(46.168743, 10.714374),
  LatLng(46.168831, 10.714068),
  LatLng(46.168711, 10.713953),
  LatLng(46.168592, 10.714087),
  LatLng(46.168302, 10.714062),
  LatLng(46.167971, 10.712928),
  LatLng(46.167644, 10.712362),
  LatLng(46.167204, 10.712263),
  LatLng(46.166850, 10.711170),
  LatLng(46.166804, 10.709701),
  LatLng(46.166589, 10.709196),
  LatLng(46.166676, 10.708840),
  LatLng(46.166517, 10.708642),
  LatLng(46.166687, 10.708327),
  LatLng(46.166606, 10.708081),
  LatLng(46.166729, 10.707674),
  LatLng(46.166557, 10.706981),
  LatLng(46.166695, 10.706968),
  LatLng(46.166564, 10.706829),
  LatLng(46.167166, 10.706765),
  LatLng(46.166830, 10.706729),
  LatLng(46.166605, 10.706866),
  LatLng(46.166522, 10.706715),
  LatLng(46.166490, 10.706540),
  LatLng(46.166650, 10.706589),
  LatLng(46.166545, 10.706656),
  LatLng(46.166470, 10.706443),
  LatLng(46.166500, 10.706028),
  LatLng(46.166337, 10.705599),
  LatLng(46.166501, 10.705327),
  LatLng(46.166435, 10.704417),
  LatLng(46.166349, 10.704037),
  LatLng(46.166221, 10.704074),
  LatLng(46.166289, 10.703613),
  LatLng(46.166136, 10.703377),
  LatLng(46.166317, 10.703258),
  LatLng(46.166180, 10.703058),
  LatLng(46.166325, 10.702799),
  LatLng(46.166100, 10.703024),
  LatLng(46.166263, 10.703060),
  LatLng(46.166011, 10.702630),
  LatLng(46.165851, 10.701990),
  LatLng(46.165944, 10.701981),
  LatLng(46.165702, 10.701552),
  LatLng(46.165820, 10.701566),
  LatLng(46.165355, 10.700014),
  LatLng(46.165444, 10.699020),
  LatLng(46.165326, 10.698562),
  LatLng(46.165490, 10.698630),
  LatLng(46.165129, 10.698616),
  LatLng(46.165293, 10.698742),
  LatLng(46.165183, 10.698540),
  LatLng(46.165338, 10.698437),
  LatLng(46.165283, 10.697914),
  LatLng(46.164456, 10.695810),
  LatLng(46.164529, 10.695213),
  LatLng(46.164377, 10.694678),
  LatLng(46.164474, 10.694173),
  LatLng(46.164576, 10.694171),
  LatLng(46.164594, 10.693565),
  LatLng(46.164690, 10.693563),
  LatLng(46.164407, 10.693159),
  LatLng(46.164388, 10.693435),
  LatLng(46.164231, 10.693299),
  LatLng(46.164148, 10.693766),
  LatLng(46.164182, 10.693414),
  LatLng(46.164081, 10.693303),
  LatLng(46.164037, 10.693453),
  LatLng(46.163953, 10.693133)
];

Future<void> main() async {
  // Inizializza Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;

  final pointsGeo = points.map((p) => GeoPoint(p.latitude, p.longitude)).toList();

  try {
    await db.collection('trekking').doc('0ozWP0pBQN8Gkk6FP5Lf').set({
      'Points': pointsGeo,
    });
    print('Punti caricati correttamente!');
  } catch (e) {
    print('Errore durante il caricamento: $e');
  }
}