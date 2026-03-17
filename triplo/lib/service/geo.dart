import 'package:flutter/foundation.dart';
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
      debugPrint("Error getting location: $e");
      return null;
    }
  }
}