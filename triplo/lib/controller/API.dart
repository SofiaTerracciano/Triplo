import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:triplo/model/challenges.dart';

// API controller for external services
class API {
  late final String openWeatherKey;
  late final String weatherbitKey;

  // Constructor to load API keys from .env
  API() {
    openWeatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    weatherbitKey = dotenv.env['WEATHERBIT_API_KEY'] ?? "";

    if (openWeatherKey.isEmpty) {
      debugPrint("WARNING: OPENWEATHER_API_KEY missing");
    }
    if (weatherbitKey.isEmpty) {
      debugPrint("WARNING: WEATHERBIT_API_KEY missing");
    }
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
  Future<LatLng?> userLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  // Fetch current weather data for given coordinates
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
  }

  // Fetch 5-day weather forecast for given coordinates
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

  // Retry a task multiple times with delay
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

  // Safe HTTP GET request with error handling
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

// Class to represent API errors
class ApiError {
  final String message;
  final int? statusCode;

  ApiError(this.message, {this.statusCode});

  @override
  String toString() => "ApiError($statusCode): $message";
}

// Controller for managing challenges data from Firestore
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



}