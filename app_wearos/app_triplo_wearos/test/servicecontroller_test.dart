import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'servicecontroller_test.mocks.dart';


@GenerateMocks([MemoryService, GeoService])
void main() {
  late MockMemoryService mockMemory;
  late MockGeoService mockGeo;
  late ServiceController ctrl;

  setUp(() {
    mockMemory = MockMemoryService();
    mockGeo = MockGeoService();

    dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=test_openweather_key
WEATHERBIT_API_KEY=test_weatherbit_key
''');

    ctrl = ServiceController(
      memory: mockMemory,
      geo: mockGeo,
    );
  });

  group('constructor', () {
    test('loads API keys from dotenv', () {
      expect(ctrl.openWeatherKey, 'test_openweather_key');
      expect(ctrl.weatherbitKey, 'test_weatherbit_key');
    });
  });

  group('userLocation()', () {
    test('delegates to GeoService and returns LatLng', () async {
      const expected = LatLng(45.4642, 9.1900);

      when(mockGeo.userLocation()).thenAnswer((_) async => expected);

      final result = await ctrl.userLocation();

      expect(result, expected);
      verify(mockGeo.userLocation()).called(1);
    });

    test('returns null when GeoService returns null', () async {
      when(mockGeo.userLocation()).thenAnswer((_) async => null);

      final result = await ctrl.userLocation();

      expect(result, isNull);
      verify(mockGeo.userLocation()).called(1);
    });
  });

  group('parseForecastItem()', () {
    test('parses and normalizes a valid forecast item', () {
      final raw = {
        'dt_txt': '2026-07-01 12:00:00',
        'main': {'temp': 22.8},
        'weather': [
          {
            'icon': '04d',
            'description': 'Broken Clouds',
          }
        ],
      };

      final result = ctrl.parseForecastItem(raw);

      expect(result['date'], DateTime.parse('2026-07-01 12:00:00'));
      expect(result['temp'], 23);
      expect(result['icon'], '04d');
      expect(result['description'], 'broken clouds');
    });

    test('keeps null icon and stringifies null description', () {
      final raw = {
        'dt_txt': '2026-07-01 12:00:00',
        'main': {'temp': 0},
        'weather': [
          {
            'icon': null,
            'description': null,
          }
        ],
      };

      final result = ctrl.parseForecastItem(raw);

      expect(result['date'], DateTime.parse('2026-07-01 12:00:00'));
      expect(result['temp'], 0);
      expect(result['icon'], isNull);
      expect(result['description'], 'null');
    });
  });

  group('parseForecast()', () {
    test('maps all raw items through parseForecastItem', () {
      final raw = [
        {
          'dt_txt': '2026-07-01 12:00:00',
          'main': {'temp': 10.2},
          'weather': [
            {'icon': '01d', 'description': 'Clear Sky'}
          ],
        },
        {
          'dt_txt': '2026-07-02 12:00:00',
          'main': {'temp': 15.6},
          'weather': [
            {'icon': '02d', 'description': 'Few Clouds'}
          ],
        },
      ];

      final result = ctrl.parseForecast(raw);

      expect(result.length, 2);

      expect(result[0]['temp'], 10);
      expect(result[0]['icon'], '01d');
      expect(result[0]['description'], 'clear sky');

      expect(result[1]['temp'], 16);
      expect(result[1]['icon'], '02d');
      expect(result[1]['description'], 'few clouds');
    });

    test('returns empty list when input is empty', () {
      final result = ctrl.parseForecast([]);

      expect(result, isEmpty);
    });
  });


  group('weatherIconUrl()', () {
    test('returns small icon url by default', () {
      final url = ctrl.weatherIconUrl('01d');

      expect(url, 'https://openweathermap.org/img/wn/01d.png');
    });

    test('returns big icon url when big is true', () {
      final url = ctrl.weatherIconUrl('01d', big: true);

      expect(url, 'https://openweathermap.org/img/wn/01d@2x.png');
    });
  });

  group('openTopoMap helpers', () {
    test('openTopoMapTile returns expected template', () {
      expect(
        ctrl.openTopoMapTile(),
        'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      );
    });

    test('openTopoMapSubdomains returns expected subdomains', () {
      expect(ctrl.openTopoMapSubdomains(), ['a', 'b', 'c']);
    });
  });
}