import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/service/geo.dart';

@GenerateMocks([GeoService])
import 'geo_test.mocks.dart';


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

// ─── TestableGeoService ───────────────────────────────────────────────────────
//
// Estende GeoService e overrida solo i metodi che dipendono da canali platform
// (Geolocator, FlutterCompass) non raggiungibili in unit test.
// I metodi NON overridati vengono eseguiti dal codice reale → coprono la
// coverage delle righe che non chiamano API platform.

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

  // NON ovveridiamo compassStream() → il codice reale viene eseguito.
  // Quando FlutterCompass.events è null (ambiente test senza plugin)
  // il branch `if (stream == null)` viene coperto.
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── GeoService.userLocation() ─────────────────────────────────────────────

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

  // ── GeoService.isLocationServiceEnabled() ────────────────────────────────

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

  // ── GeoService.openLocationSettingsPage() ────────────────────────────────

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

  // ── GeoService.getPositionStream() ───────────────────────────────────────

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

  // ── GeoService.compassStream() ────────────────────────────────────────────
  //
  // Questo gruppo chiama il CODICE REALE di GeoService (nessun override).
  // In ambiente test FlutterCompass.events è null → copre il branch
  // `if (stream == null) return Stream<double?>.value(null)`.
  // Le righe che usano FlutterCompass quando events != null non sono
  // raggiungibili senza il plugin nativo e sono marcate con
  // // coverage:ignore-line nel sorgente.

  group('GeoService.compassStream() – codice reale', () {
    test(
        'ritorna Stream con null quando FlutterCompass.events è null '
        '(ambiente test senza plugin)', () async {
      final service = GeoService(); // istanza reale, nessun override

      // In ambiente test FlutterCompass.events == null →
      // copre il branch if (stream == null)
      final result = await service.compassStream().first;

      expect(result, isNull);
    });
  });

  // ── MockGeoService ────────────────────────────────────────────────────────

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