import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../service/memory.dart';
import '../service/geo.dart';
import '../service/permission.dart';


class ServiceController {
  /// API key for OpenWeather services.
  late final String openWeatherKey;

  /// API key for Weatherbit services (used for alerts).
  late final String weatherbitKey;

  /// Service for managing local image/data caching.
  MemoryService memory;

  /// Service for handling device geolocation.
  GeoService geo;

  /// Service for managing system permissions.
  late PermissionService permission;

  // Constructor to load API keys from .env
  ServiceController({required this.memory, required this.geo, required this.permission}) {

    openWeatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    weatherbitKey = dotenv.env['WEATHERBIT_API_KEY'] ?? "";

    if (openWeatherKey.isEmpty) {
      debugPrint("WARNING: OPENWEATHER_API_KEY missing");
    }
    if (weatherbitKey.isEmpty) {
      debugPrint("WARNING: WEATHERBIT_API_KEY missing");
    }
  }

  /// Builds an OpenWeather tile URL for FlutterMap layers (e.g., precipitation, wind).
  String weatherTile(String layer) {
    return "https://tile.openweathermap.org/map/$layer/{z}/{x}/{y}.png?appid=$openWeatherKey";
  }

  /// Maps internal layer IDs to OpenWeather's specific layer naming convention.
  String? resolveLayer(String id) {
    const map = {
      "precip": "precipitation",
      "snow": "snow",
      "wind": "wind",
      "clouds": "clouds_new",
      "temp": "temp_new",
      "pressure": "pressure_new",
    };

    return map[id];
  }

  /// Retrieves the user's current [LatLng] coordinates using the [GeoService].
  Future<LatLng?> userLocation() {
    return geo.userLocation();
  }

  /// Fetches current weather data from OpenWeather for the given [lat] and [lon].
  /// [lang] defines the language for the weather description.
  Future<Map<String, dynamic>?> weather(double lat, double lon, String lang) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon"
        "&appid=$openWeatherKey&units=metric&lang=$lang";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      debugPrint("Weather error: HTTP ${res.statusCode}");
      return null;
    } catch (e) {
      debugPrint("Weather request failed: $e");
      return null;
    }
  }

  /// Fetches a 5-day weather forecast (3-hour intervals) from OpenWeather.
  /// Returns a list of forecast entries sampled daily.
  Future<List<Map<String, dynamic>>?> forecast(
      double lat, double lon, String lang) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon"
        "&appid=$openWeatherKey&units=metric&lang=$lang";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['list']);

        // Returns one sample every 24 hours (8 entries * 3 hours = 24h)
        return [
          for (int i = 0; i < list.length; i += 8) list[i],
        ];
      }

      debugPrint("Forecast error: HTTP ${res.statusCode}");
      return null;
    } catch (e) {
      debugPrint("Forecast request failed: $e");
      return null;
    }
  }

  /// Performs a low-level check for internet connectivity by looking up google.com.
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }


  /// Builds the full URL for the weather condition icon.
  /// Set [big] to true for higher resolution (@2x).
  String weatherIconUrl(String iconCode, {bool big = true}) {
    final size = big ? "@2x" : "";
    return "https://openweathermap.org/img/wn/$iconCode$size.png";
  }



  /// Parses a single item from the forecast list into a standardized map.
  Map<String, dynamic> parseForecastItem(Map<String, dynamic> raw) {
    return {
      "date": DateTime.parse(raw["dt_txt"]),
      "temp": raw["main"]["temp"].round(),
      "icon": raw["weather"][0]["icon"],
      "description": raw["weather"][0]["description"].toString().toLowerCase(),
    };
  }

  /// Converts a full list of raw forecast entries into standardized maps.
  List<Map<String, dynamic>> parseForecast(List<Map<String, dynamic>> raw) {
    return raw.map(parseForecastItem).toList();
  }

  /// Returns the OpenTopoMap tile URL template for topographic map rendering.
  String openTopoMapTile() {
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  List<String> openTopoMapSubdomains() {
    return ['a', 'b', 'c'];
  }

  /// Fetches mock weather alerts from a demo server for testing purposes.
  Future<List<Map<String, dynamic>>> mockAlerts() async {
    try {
      final res = await http.get(
        Uri.parse("https://meteodemoserver.onrender.com/alerts"),
      );

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }

      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }

      return [];
    } catch (e) {
      debugPrint("Mock alerts error $e");
      return [];
    }
  }

  /// Fetches real-time weather alerts from Weatherbit for the specified location.
  /// Returns a list of alerts including severity, timing, and description.
  Future<List<Map<String, dynamic>>> weatherbitAlerts(
      double lat,
      double lon,
      ) async {

    if (weatherbitKey.isEmpty) return [];

    final url =
        "https://api.weatherbit.io/v2.0/alerts"
        "?lat=$lat&lon=$lon&key=$weatherbitKey";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        debugPrint("Weatherbit alerts error ${res.statusCode}");
        return [];
      }

      final data = jsonDecode(res.body);
      final List alerts = data["alerts"] ?? [];

      return alerts.map<Map<String, dynamic>>((a) {
        return {
          "event": a["title"] ?? "Weather Alert",
          "severity": (a["severity"] ?? "Unknown").toString(),
          "headline": a["title"] ?? "",
          "description": a["description"] ?? "",
          "start": a["effective_local"],
          "end": a["expires_local"],
          "source": "weatherbit",
        };
      }).toList();

    } catch (e) {
      debugPrint("Weatherbit alerts exception $e");
      return [];
    }
  }
  Future<NavigationLocationState> loadNavigationLocation() async {
    final granted = await permission.isLocationGranted();

    if (!granted) {
      return const NavigationLocationState(
        altitude: null,
        position: null,
        error: "PERMISSION_DENIED",
        isChecking: false,
      );
    }

    final serviceEnabled = await geo.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const NavigationLocationState(
        altitude: null,
        position: null,
        error: "GPS_DISABLED",
        isChecking: false,
      );
    }

    return const NavigationLocationState(
      altitude: null,
      position: null,
      error: null,
      isChecking: false,
    );
  }

  Stream<Position> navigationPositionStream() {
    return geo.getPositionStream();
  }

  Future<void> openGpsSettings() async {
    await geo.openLocationSettingsPage();
  }

  Future<void> openPermissionSettings() async {
    await permission.openAppSettingsPage();
  }


  String googleSatelliteTile() {
    return "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}";
  }
}

class NavigationLocationState {
  final double? altitude;
  final Position? position;
  final String? error;
  final bool isChecking;

  const NavigationLocationState({
    required this.altitude,
    required this.position,
    required this.error,
    required this.isChecking,
  });
}