import 'dart:async';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';



class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() =>
      super.noSuchMethod(
        Invocation.method(#isLocationServiceEnabled, []),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      ) as Future<bool>;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) =>
      super.noSuchMethod(
        Invocation.method(#getCurrentPosition, [], {
          #locationSettings: locationSettings,
        }),
        returnValue: Future.value(_defaultPosition()),
        returnValueForMissingStub: Future.value(_defaultPosition()),
      ) as Future<Position>;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Position _defaultPosition() => Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Position _makePosition({double lat = 45.4642, double lng = 9.1900}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 100.0,
      altitudeAccuracy: 5.0,
      heading: 0.0,
      headingAccuracy: 5.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
  });

  group('GeoService – userLocation –', () {
    test('returns null when location service is disabled', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      final result = await GeoService().userLocation();

      expect(result, isNull);
      verifyNever(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      ));
    });

    test('returns LatLng when position is obtained successfully', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => _makePosition(lat: 45.4642, lng: 9.1900));

      final result = await GeoService().userLocation();

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(45.4642, 0.0001));
      expect(result.longitude, closeTo(9.1900, 0.0001));
    });

    test('returns null when getCurrentPosition throws PermissionDeniedException',
        () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenThrow(const PermissionDeniedException('Permission denied'));

      final result = await GeoService().userLocation();

      expect(result, isNull);
    });

    test('returns null when getCurrentPosition times out', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenThrow(TimeoutException('GPS timeout'));

      final result = await GeoService().userLocation();

      expect(result, isNull);
    });

    test('returns null when isLocationServiceEnabled throws', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenThrow(Exception('platform error'));

      final result = await GeoService().userLocation();

      expect(result, isNull);
    });
  });
}