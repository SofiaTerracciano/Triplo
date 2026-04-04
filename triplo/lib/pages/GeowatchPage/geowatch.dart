import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/servicecontroller.dart';

import 'package:triplo/widgets_for_pages/mini_map/mini_map.dart';

import '../../controller/trekking.dart';
import '../../l10n/app_localizations.dart';
import 'google_satellite_page.dart';


class GeoWatchPage extends StatefulWidget {

  final LatLng? trailCenter;





  final String? trekkingId;
  final String? trekkingName;

  const GeoWatchPage({
    Key? key,
    this.trailCenter,
    this.trekkingId,
    this.trekkingName,
  }) : super(key: key);

  @override
  State<GeoWatchPage> createState() => _GeoWatchPageState();
}

class _GeoWatchPageState extends State<GeoWatchPage> {
  late ServiceController api;
  AppLocalizations get local => AppLocalizations.of(context)!;
  bool _initialized = false;
  bool _weatherAlertEnabled = false;
  bool _loadingAlertState = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      api = context.read<ServiceController>();
      _loadAlertState().then((_) {
        _loadAll();
      });


      _timer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _loadAll(),
      );

      _initialized = true;
    }
  }


  LatLng? _userPos; // GPS dell’utente (optional)
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _forecast = [];



  bool _useTrailWeather = true;

  List<Map<String, dynamic>> _alerts = [];
  late Timer _timer;




  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAll() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _alerts = [];
    });

    try {
      final LatLng target =
      (_useTrailWeather && widget.trailCenter != null)
          ? widget.trailCenter!
          : (await api.userLocation() ?? const LatLng(46.0, 11.0));

      final langCode = Localizations.localeOf(context).languageCode;

      final w = await api.weather(
        target.latitude,
        target.longitude,
        langCode,
      );

      final rawForecast = await api.forecast(
        target.latitude,
        target.longitude,
        langCode,
      );

      if (!mounted) return;

      setState(() {
        _weather = w;
        _forecast =
        rawForecast == null ? [] : api.parseForecast(rawForecast);
        _loading = false;
      });

      final real =
      await api.weatherbitAlerts(target.latitude, target.longitude);
      final mock = await api.mockAlerts();

      if (!mounted) return;

      setState(() {
        _alerts = [...real, ...mock];
      });

      api.userLocation().then((pos) {
        if (mounted) setState(() => _userPos = pos);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = local.error_loading_weather_label;;
        _loading = false;
      });
    }
    //_loadAlertState();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final place = _useTrailWeather
        ? local.trail_area_label
        : local.your_position_label;
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
      appBar: AppBar(
        title: Text(local.weather_title),
        centerTitle: true,
        actions: [
          if (widget.trekkingId != null)
            IconButton(
              icon: _loadingAlertState
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                _weatherAlertEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_none,
              ),
              onPressed: _loadingAlertState ? null : _toggleWeatherAlert,
            ),
        ],
      ),
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
        ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ========= HEADER METEO  =========
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
                              local.based_on_nearest_station_label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
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





                  Text(
                    local.forecast_label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_forecast.isEmpty)
                    Text(
                  _loading ? "" : local.no_forecast_available_label,
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
          Mini_Map(
            center: _useTrailWeather
                ? widget.trailCenter ?? const LatLng(46.0, 11.0)
                : _userPos ?? widget.trailCenter ?? const LatLng(46.0, 11.0),
          ),

          const SizedBox(height: 10),

          // ========= BUTTON → SATELLITE MAP =========
          ElevatedButton.icon(
            onPressed: () {

              final LatLng center = _useTrailWeather
                  ? widget.trailCenter ?? const LatLng(46.0, 11.0)
                  : _userPos ?? widget.trailCenter ?? const LatLng(46.0, 11.0);


              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoogleSatellitePage(
                    trailCenter: widget.trailCenter ?? _userPos ?? const LatLng(46.0, 11.0),
                    userCenter: _userPos,
                    initialCenter: center,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: Text(local.open_satellite_weather_layers_label),
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
                  ?  Text(
                local.no_active_weather_alerts_label,
                style: TextStyle(color: Colors.black54),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.weather_alerts_label,
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

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlertDetailPage(
                              event: event,
                              severity: severity,
                              headline: headline,
                              description: description,
                            ),
                          ),
                        );
                      },

                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color),
                        ),

                        child: Row(
                          children: [

                            // BARRA COLORE
                            Container(
                              width: 6,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    severity.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );

                  }).toList(),

                ],
              ),
            ),
          ),




          const SizedBox(height: 16),


        ],
      ),  // Back button
            /*Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: _buildBackButton(context),
              ),
            ),*/], ),



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
                  local.trail_weather_label,
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
                  local.my_gps_label,
                  style: TextStyle(
                    color: !_useTrailWeather ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),

        //messo per non far sovrapporre i bottoni alla navbar di android
        SizedBox(height: MediaQuery.of(context).padding.bottom + 36),
      ],
    );
  }
  Color _severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case "advisory":
      case "minor":
        return Colors.yellow.shade700;
      case "moderate":
      case "watch" :
        return Colors.orange;
      case "severe":
        return Colors.red;
      case "extreme":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }



  Future<void> _loadAlertState() async {
    if (widget.trekkingId == null) {
      if (!mounted) return;
      setState(() {
        _weatherAlertEnabled = false;
        _loadingAlertState = false;
      });
      return;
    }

    final trekkingController = context.read<TrekkingController>();
    final enabled = await trekkingController.isWeatherAlertEnabled(
      widget.trekkingId!,
    );

    if (!mounted) return;
    setState(() {
      _weatherAlertEnabled = enabled;
      _loadingAlertState = false;
    });
  }

  Future<void> _toggleWeatherAlert() async {
    final trekkingId = widget.trekkingId;
    if (trekkingId == null) return;

    final trekkingController = context.read<TrekkingController>();

    try {
      if (_weatherAlertEnabled) {
        await trekkingController.disableWeatherAlertForTrekking(trekkingId);
      } else {
        await trekkingController.enableWeatherAlertForTrekking(trekkingId);
      }

      if (!mounted) return;

      setState(() {
        _weatherAlertEnabled = !_weatherAlertEnabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _weatherAlertEnabled
                ? "Weather notification enabled"
                : "Weather notification disabled",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error updating weather notification"),
        ),
      );
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

/*Widget _buildBackButton(BuildContext context) {
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
}*/

class AlertDetailPage extends StatelessWidget {
  final String event;
  final String severity;
  final String headline;
  final String description;

  const AlertDetailPage({
    super.key,
    required this.event,
    required this.severity,
    required this.headline,
    required this.description,
  });



  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title:  Text(local.weather_alert_title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              event,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              severity,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            if (headline.isNotEmpty)
              Text(
                headline,
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 12),

            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}
