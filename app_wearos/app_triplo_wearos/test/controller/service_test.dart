import 'dart:convert';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';


@GenerateMocks([GeoService, MemoryService])
import 'service_test.mocks.dart';

http.Client _fakeClient(int statusCode, dynamic body) =>
    http_testing.MockClient(
      (_) async => http.Response(
        body is String ? body : jsonEncode(body),
        statusCode,
      ),
    );

http.Client _throwingClient() =>
    http_testing.MockClient((_) async => throw Exception('network error'));

ServiceController _makeSvc({
  MockGeoService? geo,
  MockMemoryService? memory,
  String owKey = 'test-ow-key',
  String wbKey = 'test-wb-key',
}) {
  dotenv.testLoad(fileInput: '''
OPENWEATHER_API_KEY=$owKey
WEATHERBIT_API_KEY=$wbKey
''');
  return ServiceController(
    geo: geo ?? MockGeoService(),
    memory: memory ?? MockMemoryService(),
  );
}

void main() {
  group('costruttore', () {
    test('carica le chiavi API dal dotenv', () {
      final c = _makeSvc(owKey: 'ow123', wbKey: 'wb456');
      expect(c.openWeatherKey, 'ow123');
      expect(c.weatherbitKey, 'wb456');
    });

    test('chiavi vuote quando assenti nel dotenv', () {
      dotenv.testLoad(fileInput: '');
      final c = ServiceController(
        geo: MockGeoService(),
        memory: MockMemoryService(),
      );
      expect(c.openWeatherKey, '');
      expect(c.weatherbitKey, '');
    });
  });

  group('userLocation', () {
    test('delega a GeoService e restituisce LatLng', () async {
      final geo = MockGeoService();
      when(geo.userLocation()).thenAnswer((_) async => const LatLng(45.0, 9.0));
      expect(await _makeSvc(geo: geo).userLocation(), const LatLng(45.0, 9.0));
    });

    test('restituisce null se GeoService restituisce null', () async {
      final geo = MockGeoService();
      when(geo.userLocation()).thenAnswer((_) async => null);
      expect(await _makeSvc(geo: geo).userLocation(), isNull);
    });
  });

  group('weather', () {
    test('restituisce mappa JSON con status 200', () async {
      final result = await _makeSvc().weather(45.0, 9.0, 'it',
          client: _fakeClient(200, {'main': {'temp': 22.5}}));
      expect(result, isNotNull);
      expect(result!['main']['temp'], 22.5);
    });

    test('restituisce null con status != 200', () async {
      expect(
        await _makeSvc().weather(45.0, 9.0, 'it',
            client: _fakeClient(401, {})),
        isNull,
      );
    });

    test('restituisce null se openWeatherKey è vuota', () async {
      expect(await _makeSvc(owKey: '').weather(45.0, 9.0, 'it'), isNull);
    });

    test('restituisce null in caso di eccezione', () async {
      expect(
        await _makeSvc().weather(45.0, 9.0, 'it', client: _throwingClient()),
        isNull,
      );
    });
  });

  group('forecast', () {
    List<Map<String, dynamic>> _makeList(int n) => List.generate(n, (i) => {
          'dt_txt': '2024-06-01 ${(i % 8) * 3}:00:00',
          'main': {'temp': 20.0 + i},
          'weather': [{'icon': '01d', 'description': 'sunny'}],
        });

    test('restituisce lista campionata (ogni 8) con status 200', () async {
      final result = await _makeSvc().forecast(45.0, 9.0, 'it',
          client: _fakeClient(200, {'list': _makeList(16)}));
      expect(result, isNotNull);
      expect(result!.length, 2);
    });

    test('restituisce null con status != 200', () async {
      expect(
        await _makeSvc().forecast(45.0, 9.0, 'it',
            client: _fakeClient(500, {})),
        isNull,
      );
    });

    test('restituisce null se openWeatherKey è vuota', () async {
      expect(await _makeSvc(owKey: '').forecast(45.0, 9.0, 'it'), isNull);
    });

    test('restituisce null in caso di eccezione', () async {
      expect(
        await _makeSvc().forecast(45.0, 9.0, 'it', client: _throwingClient()),
        isNull,
      );
    });
  });

  group('parseForecastItem', () {
    final raw = {
      'dt_txt': '2024-06-15 12:00:00',
      'main': {'temp': 22.6},
      'weather': [{'icon': '01d', 'description': 'Clear Sky'}],
    };

    test('data corretta', () {
      expect(_makeSvc().parseForecastItem(raw)['date'],
          DateTime.parse('2024-06-15 12:00:00'));
    });

    test('temperatura arrotondata', () {
      expect(_makeSvc().parseForecastItem(raw)['temp'], 23);
    });

    test('icon code preservato', () {
      expect(_makeSvc().parseForecastItem(raw)['icon'], '01d');
    });

    test('descrizione in lowercase', () {
      expect(_makeSvc().parseForecastItem(raw)['description'], 'clear sky');
    });
  });

  group('parseForecast', () {
    test('mappa tutti gli elementi', () {
      final result = _makeSvc().parseForecast([
        {
          'dt_txt': '2024-06-01 00:00:00',
          'main': {'temp': 15.0},
          'weather': [{'icon': '01n', 'description': 'clear'}],
        },
        {
          'dt_txt': '2024-06-02 00:00:00',
          'main': {'temp': 20.0},
          'weather': [{'icon': '01d', 'description': 'Sunny'}],
        },
      ]);
      expect(result.length, 2);
      expect(result.last['description'], 'sunny');
    });

    test('lista vuota → lista vuota', () {
      expect(_makeSvc().parseForecast([]), isEmpty);
    });
  });

  group('weatherIconUrl', () {
    test('URL standard', () {
      expect(_makeSvc().weatherIconUrl('01d'),
          'https://openweathermap.org/img/wn/01d.png');
    });

    test('URL @2x quando big=true', () {
      expect(_makeSvc().weatherIconUrl('01d', big: true),
          'https://openweathermap.org/img/wn/01d@2x.png');
    });
  });

  group('openTopoMap', () {
    test('tile template corretto', () {
      expect(_makeSvc().openTopoMapTile(),
          'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png');
    });

    test('subdomains [a, b, c]', () {
      expect(_makeSvc().openTopoMapSubdomains(), ['a', 'b', 'c']);
    });
  });

  group('mockAlerts', () {
    test('lista JSON → lista', () async {
      final result = await _makeSvc().mockAlerts(
          client: _fakeClient(200, [
        {'event': 'Storm', 'severity': 'High'}
      ]));
      expect(result.length, 1);
      expect(result[0]['event'], 'Storm');
    });

    test('mappa JSON singola → lista con 1 elemento', () async {
      final result = await _makeSvc().mockAlerts(
          client: _fakeClient(200, {'event': 'Wind'}));
      expect(result.length, 1);
    });

    test('status != 200 → lista vuota', () async {
      expect(
          await _makeSvc().mockAlerts(client: _fakeClient(503, {})), isEmpty);
    });

    test('eccezione → lista vuota', () async {
      expect(
          await _makeSvc().mockAlerts(client: _throwingClient()), isEmpty);
    });
  });

  group('weatherbitAlerts', () {
    final fakeBody = {
      'alerts': [
        {
          'title': 'Storm',
          'severity': 'Extreme',
          'description': 'Heavy rain',
          'effective_local': '2024-01-01',
          'expires_local': '2024-01-02',
        }
      ]
    };

    test('weatherbitKey vuota → lista vuota', () async {
      expect(await _makeSvc(wbKey: '').weatherbitAlerts(45.0, 9.0), isEmpty);
    });

    test('status 200 → alert mappati correttamente', () async {
      final result = await _makeSvc()
          .weatherbitAlerts(45.0, 9.0, client: _fakeClient(200, fakeBody));
      expect(result.length, 1);
      expect(result[0]['event'], 'Storm');
      expect(result[0]['source'], 'weatherbit');
    });

    test('status 429 → lista vuota', () async {
      expect(
        await _makeSvc()
            .weatherbitAlerts(45.0, 9.0, client: _fakeClient(429, {})),
        isEmpty,
      );
    });

    test('status 500 → lista vuota', () async {
      expect(
        await _makeSvc()
            .weatherbitAlerts(45.0, 9.0, client: _fakeClient(500, {})),
        isEmpty,
      );
    });

    test('eccezione → lista vuota', () async {
      expect(
        await _makeSvc()
            .weatherbitAlerts(45.0, 9.0, client: _throwingClient()),
        isEmpty,
      );
    });

    test('chiave "alerts" assente → lista vuota', () async {
      expect(
        await _makeSvc()
            .weatherbitAlerts(45.0, 9.0, client: _fakeClient(200, {})),
        isEmpty,
      );
    });

    test('title mancante → usa "Weather Alert" come default', () async {
      final body = {
        'alerts': [
          {'severity': 'Low', 'description': 'Fog'}
        ]
      };
      final result = await _makeSvc()
          .weatherbitAlerts(45.0, 9.0, client: _fakeClient(200, body));
      expect(result[0]['event'], 'Weather Alert');
    });
  });
}