import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:triplo/widgets_for_pages/weather_legend/weather_layer.dart';
import 'package:triplo/controller/API.dart';
/// This page shows a Google Satellite map
/// with several optional weather layers from OpenWeatherMap.

class GoogleSatellitePage extends StatefulWidget {
  // Center of the map, usually the user's current position
  final LatLng center;

  const GoogleSatellitePage({Key? key, required this.center}) : super(key: key);




  @override
  State<GoogleSatellitePage> createState() => _GoogleSatellitePageState();
}

class _GoogleSatellitePageState extends State<GoogleSatellitePage> {
  final API api = API();




  // Variable to store the API key loaded from .env
  //late String _openWeatherApiKey;

  // Boolean variables to know which layer is currently visible
  bool showPrecip = false;
  bool showClouds = false;
  bool showTemp = false;
  bool showPressure = false;
  bool showSnow = false;
  bool showWind = false;
  final MapController _mapController = MapController();
  //@override
  //void initState() {
  //  super.initState();
    // Get the OpenWeather API key from .env file
  //  _openWeatherApiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  //}

  @override
  Widget build(BuildContext context) {
    // Get the legend widget for the active layer
    final legendWidget = _buildLegendWidget();



    // The whole page layout
    return Scaffold(
      appBar: AppBar(

        title: const Text("Satellite map with weather layers"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          // Main Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center, // Center of the map
              initialZoom: 7, // Default zoom
              maxZoom: 18, // Max zoom allowed
              minZoom: 3, // Minimum zoom level
            ),
            children: [
              // Google Satellite base layer
              TileLayer(
                tileProvider: CancellableNetworkTileProvider(),
                urlTemplate:
                "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
                userAgentPackageName: 'com.example.triplo',
              ),

              //User Position Layer
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.center, // The user's position
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                      size: 45,
                    ),
                  ),
                ],
              ),

              // Use our WeatherLayer helper class for dynamic layers
              if (showPrecip) WeatherLayer.build(api.resolveLayer('precip')!, api.openWeatherKey),
              if (showSnow) WeatherLayer.build(api.resolveLayer('snow')!, api.openWeatherKey),
              if (showWind) WeatherLayer.build(api.resolveLayer('wind')!, api.openWeatherKey),
              if (showClouds) WeatherLayer.build(api.resolveLayer('clouds')!, api.openWeatherKey),
              if (showTemp) WeatherLayer.build(api.resolveLayer('temp')!, api.openWeatherKey),
              if (showPressure) WeatherLayer.build(api.resolveLayer('pressure')!, api.openWeatherKey),
            ],
          ),


          // These two buttons control the zoom level of the map

          Positioned(
            bottom: 100, // distance from the bottom edge
            right: 10,   // distance from the right edge
            child: Column(
              children: [
                // Button to zoom in (increase zoom)
                FloatingActionButton(
                heroTag: "zoom_in",
                mini: true, // make it smaller
                backgroundColor: Colors.green[700],
                child: const Icon(Icons.add),
                onPressed: () {


                  // move() keeps the same center but increases zoom by +1
                  _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 10), // space between buttons




              // Button to zoom out (decrease zoom)
              FloatingActionButton(
              heroTag: "zoom_out",
              mini: true,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.remove),
              onPressed: () {
                // move() keeps same center but decreases zoom by -1
                _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
                );
              },
              ),
              ],
            ),
          ),

          // Switch Panel
          Positioned(
            top: 10,
            right: 10,
            child: _buildLayerMenu(),
          ),

          // Legend Panel
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



























  /// Widget that builds the small floating panel on the right side of the screen.
  /// This panel contains all the switches that allow the user to enable or disable a specific weather layer (like rain, snow, wind, etc.).
  /// Only one layer can be active at a time — when one is turned on, the others are turned off.
  Widget _buildLayerMenu() {
    return Card(
      elevation: 4, // adds a soft shadow below the card
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        // add inner space so text and switches are not touching edges
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Weather Layers",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // A horizontal divider line to visually separate the title from switches
            const Divider(height: 8),

            // Each of the following lines creates a toggle switch for one specific OpenWeatherMap layer
            // When the user taps on the switch, setState() rebuilds the UI to show the new map layer

            // Precipitation Switch
            _buildSwitch("Precipitation", showPrecip, (v) {
              setState(() {
                // store new value (true = ON, false = OFF)
                showPrecip = v;
                // if precipitation is ON, disable all other layers
                if (v) _disableOthers("precip");
              });
            }),

            //  Snow Switch
            _buildSwitch("Snow", showSnow, (v) {
              setState(() {
                showSnow = v; // update boolean for snow visibility

                if (v) _disableOthers("snow"); // disable other layers
              });
            }),

            // Wind Switch
            _buildSwitch("Wind", showWind, (v) {
              setState(() {
                showWind = v; // toggle wind overlay
                if (v) _disableOthers("wind"); // only one active at once
              });
            }),

            //  Clouds Switch
            _buildSwitch("Clouds", showClouds, (v) {
              setState(() {
                showClouds = v;
                if (v) _disableOthers("clouds");
              });
            }),





            // Temperature Switch
            _buildSwitch("Temperature", showTemp, (v) {
              setState(() {
                showTemp = v;
                if (v) _disableOthers("temp");
              });
            }),





            // Pressure Switch
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











  /// This method builds one switch row (label + toggle button).
  /// It’s used by _buildLayerMenu()
  ///
  /// Parameters:
  /// - [label]: the text name shown on the left ("Clouds", "Wind", etc.)
  /// - [value]: true/false for whether the switch is active
  /// - [onChanged]: a function that tells Flutter what to do when user toggles the switch
  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      // Put label on the left, switch on the right
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // The text describing the switch
        Text(label),

        // The actual toggle switch
        Switch(
          value: value, // current ON/OFF state
          activeColor: Colors.green[700], // color when switch is ON
          onChanged: (v) => onChanged(v),
        ),
      ],
    );
  }









  /// When a layer is activated, this function turns OFF all the others
  void _disableOthers(String active) {
    showPrecip = active == "precip";   // only true if active layer = precip
    showClouds = active == "clouds";   // true only if current = clouds
    showTemp = active == "temp";       // true only if current = temperature
    showPressure = active == "pressure"; // true only if current = pressure
    showSnow = active == "snow";       // true only if current = snow
    showWind = active == "wind";       // true only if current = wind
  }





  /// Builds the legend that explains color meaning for the active layer
  /// For example: if "Precipitation" is active, it shows a color bar
  /// from yellow to blue with rainfall values
  Widget? _buildLegendWidget() {
    if (showPrecip) return WeatherLayer.legend("precipitation");
    if (showSnow) return WeatherLayer.legend("snow");
    if (showWind) return WeatherLayer.legend("wind");
    if (showTemp) return WeatherLayer.legend("temp");
    if (showClouds) return WeatherLayer.legend("clouds");
    if (showPressure) return WeatherLayer.legend("pressure");


    // If no layer is selected, return null (no legend visible)
    return null;
  }
}