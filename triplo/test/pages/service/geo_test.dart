import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/service/geo.dart';

@GenerateMocks([GeoService, GeolocatorWrapper, CompassWrapper])
import 'geo_test.mocks.dart';

Position fakePosition({double lat = 45.0, double lon = 9.0}) => Position(
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

class FakeCompassWrapper implements CompassWrapper {
  final Stream<CompassEvent>? _stream;
  FakeCompassWrapper(this._stream);

  @override
  Stream<CompassEvent>? get events => _stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorWrapper mockGeo;
  late GeoService svc;

  setUp(() {
    mockGeo = MockGeolocatorWrapper();
    svc = GeoService(geolocator: mockGeo);
  });

  group('GeoService.userLocation()', () {
    test('ritorna LatLng con coordinate corrette', () async {
      when(mockGeo.getCurrentPosition())
          .thenAnswer((_) async => fakePosition(lat: 45.9, lon: 7.8));

      final result = await svc.userLocation();
      expect(result?.latitude, 45.9);
      expect(result?.longitude, 7.8);
    });

    test('ritorna null se getCurrentPosition lancia eccezione', () async {
      when(mockGeo.getCurrentPosition()).thenThrow(Exception('GPS error'));
      expect(await svc.userLocation(), isNull);
    });

    test('coordinate (0, 0)', () async {
      when(mockGeo.getCurrentPosition())
          .thenAnswer((_) async => fakePosition(lat: 0.0, lon: 0.0));
      final result = await svc.userLocation();
      expect(result?.latitude, 0.0);
      expect(result?.longitude, 0.0);
    });

    test('coordinate negative', () async {
      when(mockGeo.getCurrentPosition())
          .thenAnswer((_) async => fakePosition(lat: -33.9, lon: -70.6));
      final result = await svc.userLocation();
      expect(result?.latitude, -33.9);
      expect(result?.longitude, -70.6);
    });

    test('coordinate ai limiti massimi (90, 180)', () async {
      when(mockGeo.getCurrentPosition())
          .thenAnswer((_) async => fakePosition(lat: 90.0, lon: 180.0));
      final result = await svc.userLocation();
      expect(result?.latitude, 90.0);
      expect(result?.longitude, 180.0);
    });
  });

  group('GeoService.isLocationServiceEnabled()', () {
    test('ritorna true', () async {
      when(mockGeo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      expect(await svc.isLocationServiceEnabled(), isTrue);
    });

    test('ritorna false', () async {
      when(mockGeo.isLocationServiceEnabled()).thenAnswer((_) async => false);
      expect(await svc.isLocationServiceEnabled(), isFalse);
    });
  });

  group('GeoService.openLocationSettingsPage()', () {
    test('ritorna true', () async {
      when(mockGeo.openLocationSettings()).thenAnswer((_) async => true);
      expect(await svc.openLocationSettingsPage(), isTrue);
    });

    test('ritorna false', () async {
      when(mockGeo.openLocationSettings()).thenAnswer((_) async => false);
      expect(await svc.openLocationSettingsPage(), isFalse);
    });
  });

  group('GeoService.getPositionStream()', () {
    test('emette posizioni', () async {
      final positions = [
        fakePosition(lat: 45.0),
        fakePosition(lat: 46.0),
      ];
      when(mockGeo.getPositionStream())
          .thenAnswer((_) => Stream.fromIterable(positions));

      final result = await svc.getPositionStream().toList();
      expect(result[0].latitude, 45.0);
      expect(result[1].latitude, 46.0);
    });

    test('stream vuoto', () async {
      when(mockGeo.getPositionStream())
          .thenAnswer((_) => const Stream.empty());
      expect(await svc.getPositionStream().toList(), isEmpty);
    });

    test('propaga errore', () {
      when(mockGeo.getPositionStream())
          .thenAnswer((_) => Stream.error(Exception('GPS lost')));
      expect(svc.getPositionStream(), emitsError(isA<Exception>()));
    });

    test('emette valori poi errore', () async {
      final ctrl = StreamController<Position>();
      when(mockGeo.getPositionStream()).thenAnswer((_) => ctrl.stream);

      final emitted = <double>[];
      final sub = svc.getPositionStream().listen(
        (p) => emitted.add(p.latitude),
        onError: (_) {},
      );

      ctrl.add(fakePosition(lat: 44.0));
      ctrl.add(fakePosition(lat: 45.5));
      ctrl.addError(Exception('lost'));

      await Future.delayed(Duration.zero);
      await sub.cancel();
      await ctrl.close();

      expect(emitted, [44.0, 45.5]);
    });
  });

  group('GeoService.compassStream() – codice reale', () {
    test('branch null: events == null → emette null', () async {
      final s = GeoService(
        geolocator: mockGeo,
        compass: FakeCompassWrapper(null), // copre il branch if (stream == null)
      );
      expect(await s.compassStream().first, isNull);
    });

    test('branch events != null: mappa heading double', () async {
      final events = [
        CompassEvent.fromList([90.0, 0.0, 90.0]),
        CompassEvent.fromList([180.0, 0.0, 180.0]),
        CompassEvent.fromList([270.0, 0.0, 270.0]),
      ];
      final s = GeoService(
        geolocator: mockGeo,
        compass: FakeCompassWrapper(Stream.fromIterable(events)),
      );
      expect(await s.compassStream().toList(), [90.0, 180.0, 270.0]);
    });

    test('branch events != null: mappa heading null', () async {
      final s = GeoService(
        geolocator: mockGeo,
        compass: FakeCompassWrapper(
          Stream.fromIterable([CompassEvent.fromList(null)]),
        ),
      );
      expect(await s.compassStream().first, isNull);
    });

    test('branch events != null: stream vuoto', () async {
      final s = GeoService(
        geolocator: mockGeo,
        compass: FakeCompassWrapper(const Stream.empty()),
      );
      expect(await s.compassStream().toList(), isEmpty);
    });

    test('heading misto: valori validi e null', () async {
      final events = [
        CompassEvent.fromList([45.0, 0.0, 45.0]),
        CompassEvent.fromList(null),
        CompassEvent.fromList([135.0, 0.0, 135.0]),
      ];
      final s = GeoService(
        geolocator: mockGeo,
        compass: FakeCompassWrapper(Stream.fromIterable(events)),
      );
      expect(await s.compassStream().toList(), [45.0, null, 135.0]);
    });
  });

  group('MockGeoService', () {
    test('userLocation() con valore', () async {
      final mock = MockGeoService();
      when(mock.userLocation())
          .thenAnswer((_) async => const LatLng(45.0, 9.0));
      expect(await mock.userLocation(), const LatLng(45.0, 9.0));
    });

    test('userLocation() con null', () async {
      final mock = MockGeoService();
      when(mock.userLocation()).thenAnswer((_) async => null);
      expect(await mock.userLocation(), isNull);
    });

    test('isLocationServiceEnabled()', () async {
      final mock = MockGeoService();
      when(mock.isLocationServiceEnabled()).thenAnswer((_) async => true);
      expect(await mock.isLocationServiceEnabled(), isTrue);
    });

    test('openLocationSettingsPage() false', () async {
      final mock = MockGeoService();
      when(mock.openLocationSettingsPage()).thenAnswer((_) async => false);
      expect(await mock.openLocationSettingsPage(), isFalse);
    });

    test('getPositionStream() stream vuoto', () async {
      final mock = MockGeoService();
      when(mock.getPositionStream()).thenAnswer((_) => const Stream.empty());
      expect(await mock.getPositionStream().toList(), isEmpty);
    });

    test('compassStream() con double', () async {
      final mock = MockGeoService();
      when(mock.compassStream()).thenAnswer((_) => Stream.value(123.0));
      expect(await mock.compassStream().first, 123.0);
    });

    test('compassStream() con null', () async {
      final mock = MockGeoService();
      when(mock.compassStream()).thenAnswer((_) => Stream.value(null));
      expect(await mock.compassStream().first, isNull);
    });
  });
}