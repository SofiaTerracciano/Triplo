import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/pages/geowatch/google_satellite_page.dart';
import 'package:triplo/widgets_for_pages/mini_map/mini_map.dart';
import 'package:triplo/controller/API.dart';

// Nota: qui facciamo "WeatherPage" inline: dettagli + forecast subito.
class GeoWatchPage extends StatefulWidget {

  final LatLng? trailCenter;


  const GeoWatchPage({Key? key, this.trailCenter}) : super(key: key);

  @override
  State<GeoWatchPage> createState() => _GeoWatchPageState();
}

class _GeoWatchPageState extends State<GeoWatchPage> {
  final API api = API();

  LatLng? _userPos; // GPS dell’utente (optional)
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _forecast = [];



  bool _useTrailWeather = true;

  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // 1) Determina target velocemente
    LatLng target =
    (_useTrailWeather && widget.trailCenter != null)
        ? widget.trailCenter!
        : (await api.userLocation() ?? const LatLng(46.0, 11.0));

    // 2) METEO SUBITO
    final w = await api.weather(target.latitude, target.longitude);
    final rawForecast = await api.forecast(target.latitude, target.longitude);

    if (!mounted) return;

    setState(() {
      _weather = w;
      _forecast =
      rawForecast == null ? [] : api.parseForecast(rawForecast);
      _loading = false;
    });

    // 3) TUTTO IL RESTO IN BACKGROUND

    api.userLocation().then((pos) {
      if (mounted) setState(() => _userPos = pos);
    });

    api.weatherbitAlerts(target.latitude, target.longitude).then((real) {
      if (mounted) setState(() => _alerts.addAll(real));
    });

    api.mockAlerts().then((mock) {
      if (mounted) setState(() => _alerts.addAll(mock));
    });
  }


  @override
  Widget build(BuildContext context) {
    final place = _weather?['name'] ?? "Trail area";
    final temp = _weather?['main']?['temp']?.round()?.toString() ?? "-";
    final List weatherList =
    (_weather?['weather'] is List && _weather!['weather'].isNotEmpty)
        ? _weather!['weather']
        : [];

    final icon = weatherList.isNotEmpty && weatherList[0]['icon'] != null
        ? weatherList[0]['icon'].toString()
        : "01d";

    final rawDesc = weatherList.isNotEmpty && weatherList[0]['description'] != null
        ? weatherList[0]['description'].toString().toLowerCase()
        : "-";

    final desc = rawDesc;

    return Scaffold(




        extendBodyBehindAppBar: false,

        body: Stack(
          children: [
        ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ========= HEADER METEO (DETTAGLIO SUBITO) =========
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? _buildSkeletonWeather()
                  : (_error != null)
                  ? Text("Errore: $_error", style: const TextStyle(color: Colors.red))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.network(api.weatherIconUrl(icon), width: 60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$temp°C • ${desc.capitalize()}",
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),

                            _buildLocationToggle(),



                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Forecast",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_forecast.isEmpty)
                    Text(
                      _loading ? "" : "No forecast available",
                      style: const TextStyle(color: Colors.black54),
                    )
                  else
                    Column(
                      children: _forecast.take(6).map((f) {
                        final DateTime? d = f["date"];
                        final t = f["temp"];
                        final ic = f["icon"]?.toString() ?? "01d";
                        final ds = (f["description"] ?? "-").toString();

                        final String dateLabel =
                        d != null ? "${d.day}/${d.month}" : "--/--";

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Image.network(api.weatherIconUrl(ic, big: false)),
                          title: Text("$dateLabel – ${ds.capitalize()}"),
                          trailing: Text("$t°C", style: const TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ========= MINI MAP (CENTER = PERCORSO) =========
          Mini_Map(center: widget.trailCenter ?? _userPos ?? const LatLng(0,0)),

          const SizedBox(height: 10),

          // ========= BUTTON → SATELLITE MAP =========
          ElevatedButton.icon(
            onPressed: () {

              final LatLng center =
                  widget.trailCenter ??
                      _userPos ??
                      const LatLng(46.0, 11.0);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoogleSatellitePage(
                    trailCenter: center,
                    userCenter: _userPos,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text("Open satellite view & weather layers"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ========= ALERTS SECTION (placeholder) =========
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _alerts.isEmpty
                  ? const Text(
                "No active weather alerts for this area",
                style: TextStyle(color: Colors.black54),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Weather Alerts",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ..._alerts.map((a) {

                    final String event =
                    (a["event"] ??
                        a["title"] ??
                        "Weather alert").toString();

                    final String severity =
                    (a["severity"] ??
                        a["severity_level"] ??
                        "unknown").toString();

                    final String headline =
                    (a["headline"] ??
                        a["title"] ??
                        "").toString();

                    final String description =
                    (a["description"] ??
                        a["desc"] ??
                        "").toString();

                    final color = _severityColor(severity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$event • $severity",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),

                          if (headline.isNotEmpty)
                            Text(headline),

                          if (description.isNotEmpty)
                            Text(description),
                        ],
                      ),
                    );
                  }).toList(),

                ],
              ),
            ),
          ),




          const SizedBox(height: 16),


        ],
      ),  // BACK BUTTON FLOATING
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: _buildBackButton(context),
              ),
            ),], ),



    );
  }
  Widget _buildLocationToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_useTrailWeather) {
                setState(() {
                  _useTrailWeather = true;
                });
                _loadAll();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _useTrailWeather ? Colors.green[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "Trail weather",
                  style: TextStyle(
                    color: _useTrailWeather ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_useTrailWeather) {
                setState(() {
                  _useTrailWeather = false;
                });
                _loadAll();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_useTrailWeather ? Colors.green[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "My GPS",
                  style: TextStyle(
                    color: !_useTrailWeather ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case "minor":
        return Colors.yellow.shade700;
      case "moderate":
        return Colors.orange;
      case "severe":
        return Colors.red;
      case "extreme":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }


}

extension StringCasing on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
Widget _buildSkeletonWeather() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(height: 20, width: 140, color: Colors.grey[300]),
      const SizedBox(height: 10),
      Container(height: 26, width: 90, color: Colors.grey[300]),
      const SizedBox(height: 20),
      Row(
        children: List.generate(
          5,
              (_) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    ],
  );

}
Widget _buildBackButton(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
        ),
      ],
    ),
    child: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  );
}



