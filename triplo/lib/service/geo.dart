import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract class GeolocatorWrapper {
  Future<Position> getCurrentPosition();
  Future<bool> isLocationServiceEnabled();
  Future<bool> openLocationSettings();
  Stream<Position> getPositionStream();
}

// coverage:ignore-start
class RealGeolocatorWrapper implements GeolocatorWrapper {
  const RealGeolocatorWrapper();

  @override
  Future<Position> getCurrentPosition() =>
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  @override
  Stream<Position> getPositionStream() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
}
// coverage:ignore-end

abstract class CompassWrapper {
  Stream<CompassEvent>? get events;
}

// coverage:ignore-start
class RealCompassWrapper implements CompassWrapper {
  const RealCompassWrapper();

  @override
  Stream<CompassEvent>? get events => FlutterCompass.events;
}
// coverage:ignore-end

class GeoService {
  final GeolocatorWrapper _geolocator;
  final CompassWrapper _compass;

  GeoService({
    GeolocatorWrapper? geolocator,
    CompassWrapper? compass,
  })  : _geolocator = geolocator ?? const RealGeolocatorWrapper(),
        _compass = compass ?? const RealCompassWrapper();

  Future<LatLng?> userLocation() async {
    try {
      final pos = await _geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e"); // coverage:ignore-line
      return null;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return _geolocator.isLocationServiceEnabled();
  }

  Stream<Position> getPositionStream() {
    return _geolocator.getPositionStream();
  }

  Future<bool> openLocationSettingsPage() async {
    return _geolocator.openLocationSettings();
  }

  Stream<double?> compassStream() {
    final stream = _compass.events;
    if (stream == null) {
      return Stream<double?>.value(null);
    }
    return stream.map((event) => event.heading);
  }
}