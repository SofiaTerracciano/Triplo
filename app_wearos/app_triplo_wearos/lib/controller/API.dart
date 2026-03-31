import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:app_triplo_wearos/service/notification.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../service/geo.dart';
import '../service/permission_service.dart';
import '../service/memory.dart';

/// Controller for managing external API integrations.
/// This class handles interactions with OpenWeather and Weatherbit for weather 
/// data, manages map tiles, and provides utility methods for network safety.
class API {
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

  NotificationService notification; 
  
  // Constructor to load API keys from .env
  API({required this.memory, required this.geo, required this.notification}) {
    openWeatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    weatherbitKey = dotenv.env['WEATHERBIT_API_KEY'] ?? "";

    if (openWeatherKey.isEmpty) {
      debugPrint("WARNING: OPENWEATHER_API_KEY missing");
    }
    if (weatherbitKey.isEmpty) {
      debugPrint("WARNING: WEATHERBIT_API_KEY missing");
    }
  }

  /* Builds the URL for OpenWeather map tiles used in FlutterMap.
  /// [layer] represents the weather data type (e.g., precipitation, clouds).
  String weatherTile(String layer) {
    return "https://tile.openweathermap.org/map/$layer/{z}/{x}/{y}.png?appid=$openWeatherKey";
  }*/

  /* Maps internal layer IDs to OpenWeather's specific layer naming convention.
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
  }*/

  /// Retrieves the user's current [LatLng] coordinates using the [GeoService].
  Future<LatLng?> userLocation() async {
    return geo.userLocation();
  }


  /* Fetches current weather data for the specified coordinates.
  /// Uses OpenWeatherMap API with metric units and English language
  Future<Map<String, dynamic>?> weather(double lat, double lon) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon"
        "&appid=$openWeatherKey&units=metric&lang=en";


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
  }*/

  /* Fetches the 5-day weather forecast (sampled every 24 hours) for the specified coordinates.
  Future<List<Map<String, dynamic>>?> forecast(
      double lat, double lon) async {
    if (openWeatherKey.isEmpty) return null;

    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon"
        "&appid=$openWeatherKey&units=metric&lang=en";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['list']);

        // Return one sample per day (sampling every 8 entries, as they are 3h apart)
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
  }*/

  /// Retries an asynchronous [task] a specified number of times if it returns null.
  /// [retries] is the number of additional attempts.
  /// [delayMs] is the wait time between attempts.
  Future<T?> retry<T>(Future<T?> Function() task,
      {int retries = 2, int delayMs = 400}) async {
    T? result;

    for (int i = 0; i <= retries; i++) {
      result = await task();
      if (result != null) return result;
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    return null;
  }

  /// Executes a safe HTTP GET request with automated timeout and error handling. 
  /// Returns a [jsonDecode] object on success, or an [ApiError] on failure.
  Future<dynamic> safeRequest(
      Uri url, {
        Duration timeout = const Duration(seconds: 6),
      }) async {
    try {
      final res = await http.get(url).timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }

      return ApiError(
        "Server responded with ${res.statusCode}",
        statusCode: res.statusCode,
      );
    }

    on TimeoutException {
      return ApiError("Connection timed out");
    }

    catch (e) {
      return ApiError("Network error or API unreachable");
    }
  }

  /* Checks for active internet connectivity via DNS lookup.
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }*/

  /*Builds the full URL for an OpenWeatherMap weather icon. 
  /// Set [big] to true for @2x resolution.
  String weatherIconUrl(String iconCode, {bool big = true}) {
    final size = big ? "@2x" : "";
    return "https://openweathermap.org/img/wn/$iconCode$size.png";
  }*/


  /* Extracts core weather information from a raw API response.
  Map<String, dynamic> parseWeather(Map<String, dynamic> raw) {
    return {
      "place": raw["name"] ?? "Current position",
      "temp": raw["main"]?["temp"]?.round() ?? "-",
      "description": raw["weather"]?[0]?["description"]?.toString().toLowerCase() ?? "-",
      "icon": raw["weather"]?[0]?["icon"] ?? "01d",
    };
  }*/

  /* Parses a raw forecast item into a UI-friendly map.
  Map<String, dynamic> parseForecastItem(Map<String, dynamic> raw) {
    return {
      "date": DateTime.parse(raw["dt_txt"]),
      "temp": raw["main"]["temp"].round(),
      "icon": raw["weather"][0]["icon"],
      "description": raw["weather"][0]["description"].toString().toLowerCase(),
    };
  }*/

  /* Maps an entire list of raw forecast data using [parseForecastItem].
  List<Map<String, dynamic>> parseForecast(List<Map<String, dynamic>> raw) {
    return raw.map(parseForecastItem).toList();
  }*/

  /// Returns the base URL template for OpenTopoMap topographic tiles.
  String openTopoMapTile() {
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  /// Returns the list of subdomains used by OpenTopoMap.
  List<String> openTopoMapSubdomains() {
    return ['a', 'b', 'c'];
  }

/*
  Future<List<Map<String, dynamic>>> meteoAlarmAlerts(
      double lat,
      double lon,
      ) async {

    final url =
        "https://api.meteoalarm.org/edr/v1/collections/warnings/items"
        "?coords=POINT($lon $lat)";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        debugPrint("MeteoAlarm error ${res.statusCode}");
        return [];
      }

      final data = jsonDecode(res.body);

      final List features = data["features"] ?? [];

      return features.map<Map<String, dynamic>>((f) {
        final p = f["properties"] ?? {};
        return {
          "event": p["event"] ?? "Unknown",
          "severity": p["severity"] ?? "Unknown",
          "headline": p["headline"] ?? "",
          "description": p["description"] ?? "",
          "start": p["effective"],
          "end": p["expires"],
        };
      }).toList();
    } catch (e) {
      debugPrint("MeteoAlarm exception $e");
      return [];
    }
  }
*/

  /* Fetches simulated weather alerts from a development server.
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
  }*/

  /* Fetches real-time weather alerts from Weatherbit for specific coordinates.
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
  }*/

  /*
  LatLng computeCentroid(List<LatLng> points) {
    double lat = 0;
    double lon = 0;

    for (final p in points) {
      lat += p.latitude;
      lon += p.longitude;
    }

    return LatLng(
      lat / points.length,
      lon / points.length,
    );
  }


 */
}

/// Represents an error returned by the API during a request.
class ApiError {
  final String message;

  /// The HTTP status code, if any
  final int? statusCode;

  ApiError(this.message, {this.statusCode});

  @override
  String toString() => "ApiError($statusCode): $message";
}

/* Controller for managing challenges data from Firestore
class ChallengesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Challenges> _challenges;
  bool _loaded = false;


  ChallengesController():
  _challenges = []
  ;

  // Getter for all trekkings
  List<Challenges> get allChallenges => _challenges;

  // Load trekkings from Firestore
  Future<void> loadChallenges() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db
        .collection('challenges') 
        .get();

    // Map documents to Trekking objects and store in the list --> this function create a 
    //list of istance of trekkning (model)
    _challenges = snap.docs
        .map((doc) => Challenges.fromMap(doc.data(), docId: doc.id))
        .toList();

    notifyListeners();
  }

  // Callback when a trekking is selected
  void Function(Challenges challenges)? onTrekkingSelected;

  // Getter trekking per documentId
  Challenges? getChallengesById(String documentId) {
    try {
      return _challenges.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  // Fetch image URL from Firebase Storage given challenge complete firestore url
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }



}*/