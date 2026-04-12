import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../service/OSservice/geo.dart';
import '../service/OSservice/permission_service.dart';
import '../service/OSservice/memory.dart';


class ServiceController {
  /// The API key for OpenWeatherMap services.
  late final String openWeatherKey;


  /// The API key for Weatherbit services (used for alerts).
  late final String weatherbitKey;

  /// Service responsible for handling local data and image caching.
  MemoryService memory;

  /// Service responsible for device geolocation.
  GeoService geo;

  /// Service responsible for managing system permissions.
  late PermissionService permission;


  //NotificationService notification;
  
  // Constructor to load API keys from .env
  ServiceController({required this.memory, required this.geo}) {
    openWeatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    weatherbitKey = dotenv.env['WEATHERBIT_API_KEY'] ?? "";

    if (openWeatherKey.isEmpty) {
      debugPrint("WARNING: OPENWEATHER_API_KEY missing"); //coverage:ignore-line
    }
    if (weatherbitKey.isEmpty) {
      debugPrint("WARNING: WEATHERBIT_API_KEY missing"); //coverage:ignore-line
    }
  }




  /// Retrieves the user's current [LatLng] coordinates using the [GeoService].
  Future<LatLng?> userLocation() async {
    return geo.userLocation();
  }

  Future<Map<String, dynamic>?> weather(
      double lat,
      double lon,
      String lang,
      ) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/weather"
        "?lat=$lat&lon=$lon&appid=$openWeatherKey&units=metric&lang=$lang";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      debugPrint("Weather error: HTTP ${res.statusCode}"); //coverage:ignore-line
      return null;
    } catch (e) {
      debugPrint("Weather request failed: $e"); //coverage:ignore-line
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> forecast(
      double lat,
      double lon,
      String lang,
      ) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/forecast"
        "?lat=$lat&lon=$lon&appid=$openWeatherKey&units=metric&lang=$lang";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['list']);

        return [
          for (int i = 0; i < list.length; i += 8) list[i],
        ];
      }

      debugPrint("Forecast error: HTTP ${res.statusCode}"); //coverage:ignore-line
      return null;
    } catch (e) {
      debugPrint("Forecast request failed: $e"); //coverage:ignore-line
      return null;
    }
  }

  Map<String, dynamic> parseForecastItem(Map<String, dynamic> raw) {
    return {
      "date": DateTime.parse(raw["dt_txt"]),
      "temp": raw["main"]["temp"].round(),
      "icon": raw["weather"][0]["icon"],
      "description": raw["weather"][0]["description"].toString().toLowerCase(),
    };
  }

  List<Map<String, dynamic>> parseForecast(List<Map<String, dynamic>> raw) {
    return raw.map(parseForecastItem).toList();
  }

  String weatherIconUrl(String iconCode, {bool big = false}) {
    final size = big ? "@2x" : "";
    return "https://openweathermap.org/img/wn/$iconCode$size.png";
  }

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> mockAlerts() async {
    try {
      final res = await http
          .get(Uri.parse("https://meteodemoserver.onrender.com/alerts"))
          .timeout(const Duration(seconds: 4));

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
      debugPrint("Mock alerts error $e");  //coverage:ignore-line
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> weatherbitAlerts(
      double lat,
      double lon,
      ) async {
    if (weatherbitKey.isEmpty) return [];

    final url =
        "https://api.weatherbit.io/v2.0/alerts"
        "?lat=$lat&lon=$lon&key=$weatherbitKey";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 429) {
        debugPrint("Weatherbit rate limit reached"); //coverage:ignore-line
        return [];
      }

      if (res.statusCode != 200) {
        debugPrint("Weatherbit alerts error ${res.statusCode}"); //coverage:ignore-line
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
      debugPrint("Weatherbit alerts exception $e"); //coverage:ignore-line
      return [];
    }
  }


  /// Returns the base URL template for OpenTopoMap topographic tiles.
  String openTopoMapTile() {
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  /// Returns the list of subdomains used by OpenTopoMap.
  List<String> openTopoMapSubdomains() {
    return ['a', 'b', 'c'];
  }

}

