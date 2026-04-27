import 'dart:convert';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'challenge_test.mocks.dart' show MockMemoryService;
import 'service_test.mocks.dart' show MockGeoService;

@GenerateMocks([GeoService, MemoryService])
void main() {
  setUpAll(() async {
    await dotenv.load(mergeWith: {
      'OPENWEATHER_API_KEY': 'test-ow-key',
      'WEATHERBIT_API_KEY': 'test-wb-key',
    });
  });

  ServiceController makeController({
    MockGeoService? geo,
    MockMemoryService? memory,
  }) =>
      ServiceController(
        geo: geo ?? MockGeoService(),
        memory: memory ?? MockMemoryService(),
      );

  http.Client fakeClient(int statusCode, dynamic body) => MockClient(
        (_) async => http.Response(
          body is String ? body : jsonEncode(body),
          statusCode,
        ),
      );

  group('constructor', () {
    test('reads API keys from dotenv', () {
      final c = makeController();
      expect(c.openWeatherKey, 'test-ow-key');
      expect(c.weatherbitKey, 'test-wb-key');
    });

    test('sets empty keys when env vars are absent', () async {
      // Temporarily reload with missing keys
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': '',
        'WEATHERBIT_API_KEY': '',
      });
      final c = makeController();
      expect(c.openWeatherKey, '');
      expect(c.weatherbitKey, '');
      // Restore
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': 'test-ow-key',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
    });
  });

  group('userLocation', () {
    test('delegates to GeoService and returns LatLng', () async {
      const expected = LatLng(45.0, 9.0);
      final geo = MockGeoService();
      when(geo.userLocation()).thenAnswer((_) async => expected);

      final c = makeController(geo: geo);
      expect(await c.userLocation(), expected);
      verify(geo.userLocation()).called(1);
    });

    test('returns null when GeoService returns null', () async {
      final geo = MockGeoService();
      when(geo.userLocation()).thenAnswer((_) async => null);

      final c = makeController(geo: geo);
      expect(await c.userLocation(), isNull);
    });
  });

  group('weather', () {
    final weatherBody = {
      'weather': [{'id': 800, 'description': 'clear sky'}],
      'main': {'temp': 22.5},
    };

    test('returns parsed map on HTTP 200', () async {
      final c = makeController();
      final result = await c.weather(45.0, 9.0, 'it',
          client: fakeClient(200, weatherBody));

      expect(result, isNotNull);
      expect(result!['main']['temp'], 22.5);
    });

    test('returns null on non-200 status', () async {
      final c = makeController();
      final result = await c.weather(45.0, 9.0, 'it',
          client: fakeClient(401, {'message': 'Invalid API key'}));

      expect(result, isNull);
    });

    test('returns null when openWeatherKey is empty', () async {
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': '',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
      final c = makeController();
      expect(await c.weather(45.0, 9.0, 'it'), isNull);
      // Restore
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': 'test-ow-key',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
    });

    test('returns null on network exception / timeout', () async {
      final throwingClient = MockClient((_) async => throw Exception('timeout'));
      final c = makeController();
      expect(await c.weather(45.0, 9.0, 'it', client: throwingClient), isNull);
    });
  });

  group('forecast', () {
    List<Map<String, dynamic>> makeRawList(int count) => List.generate(
          count,
          (i) => {
            'dt_txt': '2024-06-0${(i ~/ 8) + 1} ${(i % 3) * 6}:00:00',
            'main': {'temp': 20.0 + i},
            'weather': [{'icon': '01d', 'description': 'sunny'}],
          },
        );

    test('returns sampled list (every 8th entry) on HTTP 200', () async {
      final body = {'list': makeRawList(16)};
      final c = makeController();
      final result = await c.forecast(45.0, 9.0, 'it',
          client: fakeClient(200, body));

      expect(result, isNotNull);
      expect(result, hasLength(2)); 
    });

    test('returns null on non-200 status', () async {
      final c = makeController();
      expect(
        await c.forecast(45.0, 9.0, 'it', client: fakeClient(500, {})),
        isNull,
      );
    });

    test('returns null when openWeatherKey is empty', () async {
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': '',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
      final c = makeController();
      expect(await c.forecast(45.0, 9.0, 'it'), isNull);
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': 'test-ow-key',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
    });

    test('returns null on network exception', () async {
      final throwingClient = MockClient((_) async => throw Exception('error'));
      final c = makeController();
      expect(await c.forecast(45.0, 9.0, 'it', client: throwingClient), isNull);
    });
  });

  group('parseForecastItem', () {
    final raw = {
      'dt_txt': '2024-06-01 12:00:00',
      'main': {'temp': 23.7},
      'weather': [{'icon': '02d', 'description': 'Few Clouds'}],
    };

    test('parses date correctly', () {
      final c = makeController();
      final item = c.parseForecastItem(raw);
      expect(item['date'], DateTime.parse('2024-06-01 12:00:00'));
    });

    test('rounds temperature to int', () {
      final c = makeController();
      expect(c.parseForecastItem(raw)['temp'], 24);
    });

    test('preserves icon code', () {
      final c = makeController();
      expect(c.parseForecastItem(raw)['icon'], '02d');
    });

    test('lowercases description', () {
      final c = makeController();
      expect(c.parseForecastItem(raw)['description'], 'few clouds');
    });
  });

  group('parseForecast', () {
    test('maps every raw entry through parseForecastItem', () {
      final c = makeController();
      final raw = [
        {
          'dt_txt': '2024-06-01 00:00:00',
          'main': {'temp': 15.0},
          'weather': [{'icon': '01n', 'description': 'clear sky'}],
        },
        {
          'dt_txt': '2024-06-02 00:00:00',
          'main': {'temp': 20.0},
          'weather': [{'icon': '01d', 'description': 'Sunny'}],
        },
      ];
      final result = c.parseForecast(raw);
      expect(result, hasLength(2));
      expect(result.first['description'], 'clear sky');
      expect(result.last['description'], 'sunny');
    });

    test('returns empty list for empty input', () {
      expect(makeController().parseForecast([]), isEmpty);
    });
  });

  group('weatherIconUrl', () {
    test('returns standard URL for normal size', () {
      final url = makeController().weatherIconUrl('01d');
      expect(url, 'https://openweathermap.org/img/wn/01d.png');
    });

    test('returns @2x URL when big is true', () {
      final url = makeController().weatherIconUrl('01d', big: true);
      expect(url, 'https://openweathermap.org/img/wn/01d@2x.png');
    });
  });

  group('openTopoMapTile', () {
    test('returns the expected template URL', () {
      expect(
        makeController().openTopoMapTile(),
        'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      );
    });
  });

  group('openTopoMapSubdomains', () {
    test('returns exactly [a, b, c]', () {
      expect(makeController().openTopoMapSubdomains(), ['a', 'b', 'c']);
    });
  });

  group('mockAlerts', () {
    test('returns list when server responds with a JSON array', () async {
      final body = [
        {'event': 'Storm', 'severity': 'High'},
        {'event': 'Rain', 'severity': 'Low'},
      ];
      final c = makeController();
      final result = await c.mockAlerts(client: fakeClient(200, body));
      expect(result, hasLength(2));
      expect(result.first['event'], 'Storm');
    });

    test('wraps a single JSON object in a list', () async {
      final body = {'event': 'Wind', 'severity': 'Medium'};
      final c = makeController();
      final result = await c.mockAlerts(client: fakeClient(200, body));
      expect(result, hasLength(1));
      expect(result.first['event'], 'Wind');
    });

    test('returns empty list on non-200 status', () async {
      final c = makeController();
      expect(await c.mockAlerts(client: fakeClient(500, {})), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final throwingClient = MockClient((_) async => throw Exception('down'));
      expect(await makeController().mockAlerts(client: throwingClient), isEmpty);
    });
  });

  group('weatherbitAlerts', () {
    final alertsBody = {
      'alerts': [
        {
          'title': 'Thunderstorm',
          'severity': 'Extreme',
          'description': 'Heavy thunderstorms expected.',
          'effective_local': '2024-06-01T10:00:00',
          'expires_local': '2024-06-01T18:00:00',
        }
      ]
    };

    test('parses alerts correctly on HTTP 200', () async {
      final c = makeController();
      final result = await c.weatherbitAlerts(45.0, 9.0,
          client: fakeClient(200, alertsBody));

      expect(result, hasLength(1));
      expect(result.first['event'], 'Thunderstorm');
      expect(result.first['severity'], 'Extreme');
      expect(result.first['source'], 'weatherbit');
    });

    test('returns empty list when weatherbitKey is empty', () async {
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': 'test-ow-key',
        'WEATHERBIT_API_KEY': '',
      });
      final c = makeController();
      expect(await c.weatherbitAlerts(45.0, 9.0), isEmpty);
      await dotenv.load(mergeWith: {
        'OPENWEATHER_API_KEY': 'test-ow-key',
        'WEATHERBIT_API_KEY': 'test-wb-key',
      });
    });

    test('returns empty list on HTTP 429 (rate limit)', () async {
      final c = makeController();
      expect(
        await c.weatherbitAlerts(45.0, 9.0,
            client: fakeClient(429, {'error': 'rate limit'})),
        isEmpty,
      );
    });

    test('returns empty list on other non-200 status', () async {
      final c = makeController();
      expect(
        await c.weatherbitAlerts(45.0, 9.0,
            client: fakeClient(500, {})),
        isEmpty,
      );
    });

    test('returns empty list on network exception', () async {
      final throwingClient = MockClient((_) async => throw Exception('error'));
      expect(
        await makeController().weatherbitAlerts(45.0, 9.0,
            client: throwingClient),
        isEmpty,
      );
    });

    test('handles missing "alerts" key gracefully (returns empty)', () async {
      final c = makeController();
      final result = await c.weatherbitAlerts(45.0, 9.0,
          client: fakeClient(200, <String, dynamic>{}));
      expect(result, isEmpty);
    });

    test('uses default "Weather Alert" when title is missing', () async {
      final body = {
        'alerts': [
          {'severity': 'Low', 'description': 'Fog.'},
        ]
      };
      final c = makeController();
      final result = await c.weatherbitAlerts(45.0, 9.0,
          client: fakeClient(200, body));
      expect(result.first['event'], 'Weather Alert');
    });
  });
}