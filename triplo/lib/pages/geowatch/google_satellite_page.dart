import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triplo/widgets_for_pages/weather_legend/weather_layer.dart';
import 'package:triplo/controller/API.dart';

/// Google Satellite map + optional OpenWeather layers

class GoogleSatellitePage extends StatefulWidget {
  final LatLng trailCenter;
  final LatLng? userCenter;

  final LatLng initialCenter;
  const GoogleSatellitePage({
    Key? key,
    required this.trailCenter,
    required this.userCenter,
    required this.initialCenter,
  }) : super(key: key);


  @override
  State<GoogleSatellitePage> createState() => _GoogleSatellitePageState();
}

class _GoogleSatellitePageState extends State<GoogleSatellitePage> {
  final API api = API();

  bool showPrecip = false;
  bool showClouds = false;
  bool showTemp = false;
  bool showPressure = false;
  bool showSnow = false;
  bool showWind = false;

  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final legendWidget = _buildLegendWidget();


    return Scaffold(
      appBar: AppBar(
        title: const Text("Satellite map with weather layers"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(

              initialCenter: widget.initialCenter,
              initialZoom: 9,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                tileProvider: CancellableNetworkTileProvider(),
                urlTemplate: "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
                userAgentPackageName: 'com.example.triplo',
              ),


              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.trailCenter,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  if (widget.userCenter != null)
                    Marker(
                      point: widget.userCenter!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 42,
                      ),
                    ),
                ],
              ),

              if (showPrecip) WeatherLayer.build(api.resolveLayer('precip')!, api.openWeatherKey),
              if (showSnow) WeatherLayer.build(api.resolveLayer('snow')!, api.openWeatherKey),
              if (showWind) WeatherLayer.build(api.resolveLayer('wind')!, api.openWeatherKey),
              if (showClouds) WeatherLayer.build(api.resolveLayer('clouds')!, api.openWeatherKey),
              if (showTemp) WeatherLayer.build(api.resolveLayer('temp')!, api.openWeatherKey),
              if (showPressure) WeatherLayer.build(api.resolveLayer('pressure')!, api.openWeatherKey),
            ],
          ),

          // Zoom buttons
          Positioned(
            bottom: 100,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  backgroundColor: Colors.green[700],
                  child: const Icon(Icons.add),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  backgroundColor: Colors.green[700],
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // Layer menu
          Positioned(
            top: 10,
            right: 10,
            child: _buildLayerMenu(),
          ),

          // Legend
          if (legendWidget != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: legendWidget,
            ),
        ],
      ),
    );
  }

  Widget _buildLayerMenu() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weather Layers",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 8),

            _buildSwitch("Precipitation", showPrecip, (v) {
              setState(() {
                showPrecip = v;
                if (v) _disableOthers("precip");
              });
            }),

            _buildSwitch("Snow", showSnow, (v) {
              setState(() {
                showSnow = v;
                if (v) _disableOthers("snow");
              });
            }),

            _buildSwitch("Wind", showWind, (v) {
              setState(() {
                showWind = v;
                if (v) _disableOthers("wind");
              });
            }),

            _buildSwitch("Clouds", showClouds, (v) {
              setState(() {
                showClouds = v;
                if (v) _disableOthers("clouds");
              });
            }),

            _buildSwitch("Temperature", showTemp, (v) {
              setState(() {
                showTemp = v;
                if (v) _disableOthers("temp");
              });
            }),

            _buildSwitch("Pressure", showPressure, (v) {
              setState(() {
                showPressure = v;
                if (v) _disableOthers("pressure");
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(
          value: value,
          activeColor: Colors.green[700],
          onChanged: (v) => onChanged(v),
        ),
      ],
    );
  }

  void _disableOthers(String active) {
    showPrecip = active == "precip";
    showClouds = active == "clouds";
    showTemp = active == "temp";
    showPressure = active == "pressure";
    showSnow = active == "snow";
    showWind = active == "wind";
  }

  Widget? _buildLegendWidget() {
    if (showPrecip) return WeatherLayer.legend("precipitation");
    if (showSnow) return WeatherLayer.legend("snow");
    if (showWind) return WeatherLayer.legend("wind");
    if (showTemp) return WeatherLayer.legend("temp");
    if (showClouds) return WeatherLayer.legend("clouds");
    if (showPressure) return WeatherLayer.legend("pressure");
    return null;
  }
}
