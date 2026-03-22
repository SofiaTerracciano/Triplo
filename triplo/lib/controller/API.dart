import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../service/memory.dart';
import '../service/geo.dart';
import '../service/permission.dart';

// API controller for external services
class API {
  late final String openWeatherKey;
  late final String weatherbitKey;


  //memory è usato solo nel costruttore, va lasciato?
  MemoryService memory;
  GeoService geo;
  //permission è usato nel metodo initPermissions che non è mai usato, va lasciato?
  late PermissionService permission;

  // Constructor to load API keys from .env
  API({required this.memory, required this.geo}) {

    openWeatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    weatherbitKey = dotenv.env['WEATHERBIT_API_KEY'] ?? "";

    if (openWeatherKey.isEmpty) {
      debugPrint("WARNING: OPENWEATHER_API_KEY missing");
    }
    if (weatherbitKey.isEmpty) {
      debugPrint("WARNING: WEATHERBIT_API_KEY missing");
    }
  }

  //metodo che non è mai usato, va lasciato?
  // Se ti serve chiamare i permessi dall'API, fai così:
  Future<void> initPermissions() async {
    await PermissionService.askPermissionsOnce();
  }


  /// Build OpenWeather tile URL for FlutterMap
  String weatherTile(String layer) {
    return "https://tile.openweathermap.org/map/$layer/{z}/{x}/{y}.png?appid=$openWeatherKey";
  }

  /// Provide map of supported layers for cleaner UI code
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

  // Get user's current location
  Future<LatLng?> userLocation() {
    return geo.userLocation();
  }

  // Fetch current weather data for given coordinates
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

  // Fetch 5-day weather forecast for given coordinates
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



  // Check for internet connectivity
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Build full URL for weather icon
  String weatherIconUrl(String iconCode, {bool big = true}) {
    final size = big ? "@2x" : "";
    return "https://openweathermap.org/img/wn/$iconCode$size.png";
  }


  //metodo che non è mai usato, vedo se eliminarlo
  /// Extract weather information from a weather response
  Map<String, dynamic> parseWeather(Map<String, dynamic> raw) {
    return {
      "place": raw["name"] ?? "Current position",
      "temp": raw["main"]?["temp"]?.round() ?? "-",
      "description": raw["weather"]?[0]?["description"]?.toString().toLowerCase() ?? "-",
      "icon": raw["weather"]?[0]?["icon"] ?? "01d",
    };
  }

  /// Extract a single forecast entry
  Map<String, dynamic> parseForecastItem(Map<String, dynamic> raw) {
    return {
      "date": DateTime.parse(raw["dt_txt"]),
      "temp": raw["main"]["temp"].round(),
      "icon": raw["weather"][0]["icon"],
      "description": raw["weather"][0]["description"].toString().toLowerCase(),
    };
  }

  /// Convert entire forecast list
  List<Map<String, dynamic>> parseForecast(List<Map<String, dynamic>> raw) {
    return raw.map(parseForecastItem).toList();
  }

  // Base map tiles (OpenTopoMap) --> da capire dove metterla
  String openTopoMapTile() {
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  List<String> openTopoMapSubdomains() {
    return ['a', 'b', 'c'];
  }



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

  


}


