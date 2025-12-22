import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/pages/geowatch/weather_page.dart';
import 'package:triplo/pages/geowatch/google_satellite_page.dart';
import '../../controller/API.dart';
import '../../widgets_for_pages/mini_map/mini_map.dart';
import '../../widgets_for_pages/weather/weather.dart';


class GeoWatchPage extends StatefulWidget {
  const GeoWatchPage({Key? key}) : super(key: key);

  @override
  State<GeoWatchPage> createState() => _GeoWatchPageState();

}








class _GeoWatchPageState extends State<GeoWatchPage> {
  LatLng _center = const LatLng(46.0667, 11.1218);
  bool _loadingWeather = false;
  String? _weatherError;
  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _forecast = [];
  //late String _openWeatherApiKey;


  final API api = API();


  @override
  void initState() {
    super.initState();
    //_openWeatherApiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    _loadAll();
  }

  /*
  // --- GEOLOCALIZZAZIONE ---
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _weatherError = "Servizi di localizzazione disattivati");
      return;
    }








    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _weatherError = "location_disabled");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _weatherError = "Permesso posizione negato permanentemente");
      return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _center = LatLng(position.latitude, position.longitude));

    await _fetchWeather();
    await _fetchForecast();
  }

  // --- METEO ---
  Future<void> _fetchWeather() async {
    if (_openWeatherApiKey.isEmpty) return;
    setState(() => _loadingWeather = true);

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=${_center.latitude}&lon=${_center.longitude}&appid=$_openWeatherApiKey&units=metric&lang=en";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() => _weather = json.decode(res.body));
      } else {
        setState(() => _weatherError = "Errore meteo (${res.statusCode})");
      }
    } catch (e) {
      setState(() => _weatherError = "Connessione meteo non riuscita");
    } finally {
      setState(() => _loadingWeather = false);
    }
  }

  Future<void> _fetchForecast() async {
    if (_openWeatherApiKey.isEmpty) return;

    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=${_center.latitude}&lon=${_center.longitude}&appid=$_openWeatherApiKey&units=metric&lang=en";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List list = data['list'];
        setState(() {
          _forecast = List<Map<String, dynamic>>.from(
              [for (int i = 0; i < list.length; i += 8) list[i]]);
        });
      }
    } catch (e) {
      debugPrint("Errore previsioni: $e");
    }
  }
   */






  Future<void> _loadAll() async {
    final pos = await api.userLocation();
    if (pos == null) {
      setState(() => _weatherError = "Location unavailable");
      return;
    }

    setState(() => _center = pos);

    final weather = await api.weather(pos.latitude, pos.longitude);
    final forecast = await api.forecast(pos.latitude, pos.longitude);

    setState(() {
      _weather = weather;
      _forecast = forecast ?? [];
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GeoWatch"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            tooltip: "Aggiorna dati",
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Card Meteo
          GestureDetector(
            onTap: () {
              if (_weather != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeatherPage(
                      weather: _weather!,
                      forecast: _forecast,
                    ),
                  ),
                );
              }
            },
            child: Weather(
              weather: _weather,
              loading: _loadingWeather,
              error: _weatherError,
            ),
          ),
          const SizedBox(height: 12),
          // Mappa
          Mini_Map(center: _center),
          const SizedBox(height: 10),
          // Bottone per aprire la mappa completa
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoogleSatellitePage(center: _center),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text("Open satellite view by Google"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _weatherError == null
                ? "Posizione rilevata automaticamente dal GPS"
                : "${_weatherError!}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _weatherError == null ? Colors.green[700] : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          /*
          // Bottone Copernicus
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SatelliteGallery(images: [])),
              );
            },
            icon: const Icon(Icons.satellite_alt),
            label: const Text("Apri Copernicus Gallery"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
           */
        ],
      ),
    );
  }






/*
  // Anteprima Meteo
  Widget _buildWeatherPreview() {
    if (_loadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherError != null) {
      return Text("Errore: $_weatherError", style: const TextStyle(color: Colors.red));
    }
    if (_weather == null) {
      return const Text("Nessun dato meteo disponibile");
    }

    final place = _weather!['name'] ?? "Posizione corrente";
    final temp = _weather!['main']?['temp']?.round() ?? "-";
    final desc = _weather!['weather']?[0]?['description'] ?? "-";
    final icon = _weather!['weather']?[0]?['icon'] ?? "01d";


    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.network("https://openweathermap.org/img/wn/$icon@2x.png", width: 70),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$temp°C", style: const TextStyle(fontSize: 22)),
                Text(desc, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey)
          ],
        ),

      ),
    );
  }

  // Mini mappa
  Widget _buildMiniMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          key: ValueKey(_center),
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 10,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
              userAgentPackageName: 'com.example.triplo2',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _center,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 */
}