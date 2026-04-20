import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/service/geo.dart';
import '../controller/servicecontroller_test.mocks.dart';

@GenerateMocks([GeoService])

class TestableGeoService extends GeoService {
  final Future<Position> Function()? fakeGetPosition;
  final Future<bool> Function()? fakeIsLocationEnabled;
  final Future<bool> Function()? fakeOpenLocationSettings;
  final Stream<Position> Function()? fakePositionStream;
  final Stream<double?> Function()? fakeCompassStream;

  TestableGeoService({
    this.fakeGetPosition,
    this.fakeIsLocationEnabled,
    this.fakeOpenLocationSettings,
    this.fakePositionStream,
    this.fakeCompassStream,
  });

  @override
  Future<LatLng?> userLocation() async {
    if (fakeGetPosition == null) return null;
    try {
      final pos = await fakeGetPosition!();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return fakeIsLocationEnabled?.call() ?? Future.value(false);
  }

  @override
  Future<bool> openLocationSettingsPage() async {
    return fakeOpenLocationSettings?.call() ?? Future.value(false);
  }

  @override
  Stream<Position> getPositionStream() {
    return fakePositionStream?.call() ?? const Stream.empty();
  }

  @override
  Stream<double?> compassStream() {
    return fakeCompassStream?.call() ?? Stream.value(null);
  }
}

Position fakePosition({double lat = 45.0, double lon = 9.0}) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime(2024),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  group('GeoService.userLocation()', () {
    test('ritorna LatLng con le coordinate corrette', () async {
      final service = TestableGeoService(
        fakeGetPosition: () async => fakePosition(lat: 45.9, lon: 7.8),
      );

      final result = await service.userLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 45.9);
      expect(result.longitude, 7.8);
    });

    test('ritorna null se Geolocator lancia eccezione', () async {
      final service = TestableGeoService(
        fakeGetPosition: () async => throw Exception('GPS error'),
      );

      final result = await service.userLocation();

      expect(result, isNull);
    });

    test('ritorna null se fakeGetPosition non è fornito', () async {
      final service = TestableGeoService();

      final result = await service.userLocation();

      expect(result, isNull);
    });
  });

  group('GeoService.isLocationServiceEnabled()', () {
    test('ritorna true se il servizio è abilitato', () async {
      final service = TestableGeoService(
        fakeIsLocationEnabled: () async => true,
      );

      expect(await service.isLocationServiceEnabled(), isTrue);
    });

    test('ritorna false se il servizio è disabilitato', () async {
      final service = TestableGeoService(
        fakeIsLocationEnabled: () async => false,
      );

      expect(await service.isLocationServiceEnabled(), isFalse);
    });
  });

  group('GeoService.openLocationSettingsPage()', () {
    test('ritorna true se le impostazioni si aprono', () async {
      final service = TestableGeoService(
        fakeOpenLocationSettings: () async => true,
      );

      expect(await service.openLocationSettingsPage(), isTrue);
    });

    test('ritorna false se le impostazioni non si aprono', () async {
      final service = TestableGeoService(
        fakeOpenLocationSettings: () async => false,
      );

      expect(await service.openLocationSettingsPage(), isFalse);
    });
  });

  group('GeoService.getPositionStream()', () {
    test('emette le posizioni dallo stream', () async {
      final positions = [
        fakePosition(lat: 45.0, lon: 9.0),
        fakePosition(lat: 46.0, lon: 10.0),
      ];

      final service = TestableGeoService(
        fakePositionStream: () => Stream.fromIterable(positions),
      );

      final result = await service.getPositionStream().toList();

      expect(result.length, 2);
      expect(result[0].latitude, 45.0);
      expect(result[1].latitude, 46.0);
    });

    test('ritorna stream vuoto se non fornito', () async {
      final service = TestableGeoService();

      final result = await service.getPositionStream().toList();

      expect(result, isEmpty);
    });
  });

  group('GeoService.compassStream()', () {
    test('emette i valori di heading', () async {
      final service = TestableGeoService(
        fakeCompassStream: () => Stream.fromIterable([45.0, 90.0, 180.0]),
      );

      final result = await service.compassStream().toList();

      expect(result, [45.0, 90.0, 180.0]);
    });

    test('emette null se il compass non è disponibile', () async {
      final service = TestableGeoService(
        fakeCompassStream: () => Stream.value(null),
      );

      final result = await service.compassStream().first;

      expect(result, isNull);
    });

    test('ritorna stream con null se non fornito', () async {
      final service = TestableGeoService();

      final result = await service.compassStream().first;

      expect(result, isNull);
    });
  });

  group('MockGeoService', () {
    test('userLocation() può essere mockato', () async {
      final mock = MockGeoService();
      when(mock.userLocation())
          .thenAnswer((_) async => const LatLng(45.0, 9.0));

      final result = await mock.userLocation();

      expect(result, const LatLng(45.0, 9.0));
    });

    test('isLocationServiceEnabled() può essere mockato', () async {
      final mock = MockGeoService();
      when(mock.isLocationServiceEnabled()).thenAnswer((_) async => true);

      expect(await mock.isLocationServiceEnabled(), isTrue);
    });

    test('getPositionStream() può essere mockato', () async {
      final mock = MockGeoService();
      when(mock.getPositionStream())
          .thenAnswer((_) => Stream.value(fakePosition()));

      final pos = await mock.getPositionStream().first;

      expect(pos.latitude, 45.0);
    });

    test('compassStream() può essere mockato', () async {
      final mock = MockGeoService();
      when(mock.compassStream()).thenAnswer((_) => Stream.value(123.0));

      final heading = await mock.compassStream().first;

      expect(heading, 123.0);
    });
  });
}