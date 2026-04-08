import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


class GeoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<LatLng?> userLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }
  //geoservice non dovrebbe parlare con firestore, è servizio per OS
  //spostato nel controller dei trekking dove questo metodo è usato
  /*Future<void> uploadLocation(Position position) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('location')
        .doc(userId)
        .set({
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

   */
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<bool> openLocationSettingsPage() async {
    return Geolocator.openLocationSettings();
  }

  Stream<double?> compassStream() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      return Stream<double?>.value(null);
    }
    return stream.map((event) => event.heading);
  }
}