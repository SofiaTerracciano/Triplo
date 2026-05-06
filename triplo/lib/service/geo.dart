import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GeoService {

  Future<LatLng?> userLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e"); //coverage:ignore-line
      return null;
    }
  }

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