import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/geo.dart';
import 'package:triplo/service/permission.dart';
import 'servicecontroller_test.mocks.dart';

// external services replaced with Mockito fakes
@GenerateMocks([MemoryService, GeoService, PermissionService])

void main() {
  // Fake dependencies used by the controller
  late MockGeoService mockGeo;
  late MockPermissionService mockPermission;
  late MockMemoryService mockMemory;

  // "ctrl" is the controller under test.
  late ServiceController ctrl;
  // Fake HTTP client so we can return custom JSON without real network calls.
  late http.Client mockClient;


  setUp(() {
    mockGeo = MockGeoService();
    mockPermission = MockPermissionService();
    mockMemory = MockMemoryService();

    // By default, every HTTP request gets back an empty success response.
    mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });

    // Load fake API keys because the real controller expects them to exist.
    dotenv.testLoad(fileInput: '''
    OPENWEATHER_API_KEY=test
    WEATHERBIT_API_KEY=test
    ''');

    // Build the controller with test doubles instead of real services.
    ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );
  });

  // test helper methods: URLs, ids, and mappings
  group('Gestione Layer e URL', () {
    test('weatherTile() costruisce URL corretta', () {
      // The URL should contain both the selected layer and the fake API key
      final url = ctrl.weatherTile('temp_new');
      expect(url, contains('temp_new'));
      expect(url, contains('test'));
    });

    test('resolveLayer() funziona', () {
      expect(ctrl.resolveLayer('precip'), 'precipitation');
      expect(ctrl.resolveLayer('unknown'), isNull);
    });

    test('weatherTileFromId() errore su id invalido', () {
      expect(() => ctrl.weatherTileFromId('bad'), throwsArgumentError);
    });

    test('legendTypeFromId() mapping corretto', () {
      expect(ctrl.legendTypeFromId('snow'), 'snow');
    });
  });

  // test parsing logic that transforms raw API data into cleaner data.
  group('Parsing Meteo', () {
    test('parseForecastItem() normalizza dati', () {
      // This map looks like a small piece of a real weather API response.
      final raw = {
        "dt_txt": "2026-07-01 12:00:00",
        "main": {"temp": 22.8},
        "weather": [
          {"icon": "04d", "description": "Broken Clouds"}
        ],
      };

      final res = ctrl.parseForecastItem(raw);

      // The controller rounds temperature and lowercases the description.
      expect(res['temp'], 23);
      expect(res['description'], 'broken clouds');
    });

    test('parseForecast() lista corretta', () {
      final rawList = [
        {
          "dt_txt": "2026-07-01 12:00:00",
          "main": {"temp": 10.0},
          "weather": [{"icon": "01d", "description": "Clear"}]
        }
      ];

      final res = ctrl.parseForecast(rawList);

      expect(res.length, 1);
    });
  });

  // tests focusing on GPS state, permissions, and compass data
  group('Geolocalizzazione', () {
    test('userLocation delega GeoService', () async {
      final pos = LatLng(45.0, 9.0);

      when(mockGeo.userLocation()).thenAnswer((_) async => pos);

      final result = await ctrl.userLocation();

      // the controller should forward the call.
      expect(result, pos);
      verify(mockGeo.userLocation()).called(1);
    });

    test('GPS disabilitato', () async {
      when(mockPermission.isLocationGranted())
          .thenAnswer((_) async => true);

      when(mockGeo.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      // If permissions are fine but GPS is off, the controller should expose that error
      final state = await ctrl.loadNavigationLocation();

      expect(state.error, 'GPS_DISABLED');
    });

    test('permission denied', () async {
      when(mockPermission.isLocationGranted())
          .thenAnswer((_) async => false);


      final state = await ctrl.loadNavigationLocation();

      expect(state.error, 'PERMISSION_DENIED');
    });

    test('compass stream delega', () {
      final stream = Stream<double?>.value(180);

      when(mockGeo.compassStream()).thenAnswer((_) => stream);


      expect(ctrl.compassStream(), stream);
    });
  });

  test('weather() ritorna dati validi', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"temp": 20, "weather": []}',
        200,
      );
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weather(45.0, 9.0, 'en');

    // A 200 response with JSON should produce a non-null result
    expect(res, isNotNull);
  });

  test('weather() ritorna null su errore HTTP', () async {
    final client = MockClient((request) async {
      return http.Response('error', 500);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weather(45.0, 9.0, 'en');

    expect(res, isNull);
  });

  test('forecast() ritorna lista campionata ogni 24h', () async {
    final fakeList = List.generate(16, (i) {
      return {
        "dt_txt": "2026-07-01 12:00:00",
        "main": {"temp": 10},
        "weather": [
          {"icon": "01d", "description": "clear"}
        ]
      };
    });

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({"list": fakeList}),
        200,
      );
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.forecast(45.0, 9.0, 'en');
    expect(res!.length, 2);
  });

  test('weatherbitAlerts() parse alerts correttamente', () async {
    // This payload imitates the alert API and lets us check the parsed output.
    final client = MockClient((request) async {
      return http.Response(jsonEncode({
        "alerts": [
          {
            "title": "Storm Warning",
            "severity": "high",
            "description": "Heavy storm incoming",
            "effective_local": "now",
            "expires_local": "later"
          }
        ]
      }), 200);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weatherbitAlerts(45.0, 9.0);

    expect(res.length, 1);
    expect(res.first['event'], 'Storm Warning');
    expect(res.first['severity'], 'high');
  });

  test('mockAlerts() ritorna lista valida', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode([
        {"id": 1, "msg": "test alert"}
      ]), 200);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.mockAlerts();

    expect(res.length, 1);
  });

  test('hasInternet() ritorna bool (success path)', () async {
    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: MockClient((_) async => http.Response('ok', 200)),
    );

    final res = await ctrl.hasInternet();

    expect(res, isA<bool>());
  });

  test('hasInternet() gestisce errore DNS', () async {
    final res = await ctrl.hasInternet((_) async {
      throw Exception();
    });

    expect(res, isFalse);
  });

  test('hasInternet() true', () async {
    final res = await ctrl.hasInternet((_) async {
      return [InternetAddress('8.8.8.8')];
    });

    expect(res, isTrue);
  });

  test('hasInternet false', () async {
    final res = await ctrl.hasInternet((_) async => []);

    expect(res, false);
  });

  test('hasInternet exception', () async {
    final res = await ctrl.hasInternet((_) async {
      throw Exception();
    });

    expect(res, false);
  });

  test('weather() ritorna null senza API key', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=');

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );

    final res = await ctrl.weather(0, 0, 'en');

    expect(res, isNull);
  });

  test('forecast() errore HTTP', () async {
    final client = MockClient((_) async => http.Response('err', 500));

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.forecast(0, 0, 'en');

    expect(res, isNull);
  });

  test('weatherbitAlerts() senza API key', () async {
    dotenv.testLoad(fileInput: 'WEATHERBIT_API_KEY=');

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, []);
  });

  test('navigation ok', () async {
    when(mockPermission.isLocationGranted())
        .thenAnswer((_) async => true);

    when(mockGeo.isLocationServiceEnabled())
        .thenAnswer((_) async => true);

    final state = await ctrl.loadNavigationLocation();

    expect(state.error, isNull);
  });

  test('weatherIconUrl big', () {
    final url = ctrl.weatherIconUrl('01d');
    expect(url, contains('@2x'));
  });

  test('subdomains', () {
    expect(ctrl.openTopoMapSubdomains(), contains('a'));
  });

  test('google tile', () {
    expect(ctrl.googleSatelliteTile(), contains('google'));
  });

  test('weather() API key vuota', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=');

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );

    final res = await ctrl.weather(0, 0, 'en');

    expect(res, isNull);
  });

  test('weather() eccezione', () async {
    final client = MockClient((_) async {
      throw Exception('fail');
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weather(0, 0, 'en');

    expect(res, isNull);
  });

  test('forecast() errore HTTP', () async {
    final client = MockClient((_) async => http.Response('err', 500));

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.forecast(0, 0, 'en');

    expect(res, isNull);
  });

  test('forecast() eccezione', () async {
    final client = MockClient((_) async {
      throw Exception();
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.forecast(0, 0, 'en');

    expect(res, isNull);
  });

  test('forecast() API key vuota', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=');

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );

    final res = await ctrl.forecast(0, 0, 'en');

    expect(res, isNull);
  });

  test('weatherbitAlerts() API key vuota', () async {
    dotenv.testLoad(fileInput: 'WEATHERBIT_API_KEY=');

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: mockClient,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, []);
  });

  test('weatherbitAlerts() errore HTTP', () async {
    final client = MockClient((_) async => http.Response('err', 500));

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, []);
  });

  test('weatherbitAlerts() eccezione', () async {
    final client = MockClient((_) async {
      throw Exception();
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, []);
  });

  test('mockAlerts() ritorna map', () async {
    final client = MockClient((_) async {
      return http.Response(jsonEncode({"a": 1}), 200);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.mockAlerts();

    expect(res.length, 1);
  });

  test('mockAlerts() errore HTTP', () async {
    final client = MockClient((_) async {
      return http.Response('err', 500);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.mockAlerts();

    expect(res, []);
  });

  test('mockAlerts() eccezione', () async {
    final client = MockClient((_) async {
      throw Exception();
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.mockAlerts();

    expect(res, []);
  });

  test('navigation success', () async {
    when(mockPermission.isLocationGranted())
        .thenAnswer((_) async => true);

    when(mockGeo.isLocationServiceEnabled())
        .thenAnswer((_) async => true);

    final res = await ctrl.loadNavigationLocation();

    expect(res.error, isNull);
  });

  test('weatherIconUrl small', () {
    final url = ctrl.weatherIconUrl('01d', big: false);
    expect(url.contains('@2x'), false);
  });

  test('openTopoMapTile', () {
    expect(ctrl.openTopoMapTile(), contains('opentopomap'));
  });

  test('navigationPositionStream delega', () {
    final stream = Stream<Position>.empty();

    when(mockGeo.getPositionStream()).thenAnswer((_) => stream);

    expect(ctrl.navigationPositionStream(), stream);
  });

  test('weatherbitAlerts() senza campo alerts', () async {
    final client = MockClient((_) async {
      return http.Response(jsonEncode({}), 200);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, []);
  });

  test('weatherbitAlerts() fallback campi null', () async {
    dotenv.testLoad(fileInput: '''
      OPENWEATHER_API_KEY=test
      WEATHERBIT_API_KEY=test
      ''');

    final client = MockClient((_) async {
      return http.Response(jsonEncode({
        "alerts": [
          {
            "title": null,
            "severity": null,
            "description": null
          }
        ]
      }), 200);
    });

    final ctrl = ServiceController.test(
      memory: mockMemory,
      geo: mockGeo,
      permission: mockPermission,
      client: client,
    );

    final res = await ctrl.weatherbitAlerts(0, 0);

    expect(res, isNotEmpty);
    expect(res.first['event'], 'Weather Alert');
    expect(res.first['severity'], 'Unknown');
  });

  test('parseForecastItem() edge case', () {
    final raw = {
      "dt_txt": "2026-07-01 12:00:00",
      "main": {"temp": 0},
      "weather": [
        {"icon": null, "description": null}
      ],
    };

    final res = ctrl.parseForecastItem(raw);

    expect(res['description'], 'null'); 
  });

  test('resolveLayer tutti i casi', () {
    expect(ctrl.resolveLayer('snow'), 'snow');
    expect(ctrl.resolveLayer('wind'), 'wind');
    expect(ctrl.resolveLayer('clouds'), 'clouds_new');
    expect(ctrl.resolveLayer('temp'), 'temp_new');
    expect(ctrl.resolveLayer('pressure'), 'pressure_new');
  });

  test('legendTypeFromId invalid', () {
    expect(() => ctrl.legendTypeFromId('bad'), throwsArgumentError);
  });

  test('weatherTileFromId valido', () {
    final url = ctrl.weatherTileFromId('temp');

    expect(url, contains('temp_new'));
  });

  test('hasInternet lista vuota', () async {
    final res = await ctrl.hasInternet((_) async => []);

    expect(res, false);
  });

  test('hasInternet eccezione', () async {
    final res = await ctrl.hasInternet((_) async {
      throw Exception();
    });

    expect(res, false);
  });
}
