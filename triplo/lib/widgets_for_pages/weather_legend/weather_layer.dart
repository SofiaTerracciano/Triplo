import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

/// This file provides reusable weather layer widgets
/// for FlutterMap (6.x compatible).
/// Each weather type (rain, snow, etc.) can be called
/// using `WeatherLayer.build("layerType", apiKey)` and it automatically returns the correct TileLayer.
class WeatherLayer {
  /// Builds a TileLayer for the given weather type.
  static TileLayer build(String layerType, String apiKey) {
    return TileLayer(
      // The layerType defines which OpenWeather map to use

      tileProvider: CancellableNetworkTileProvider(),
      urlTemplate:
      "https://tile.openweathermap.org/map/$layerType/{z}/{x}/{y}.png?appid=$apiKey",

      userAgentPackageName: 'com.example.triplo',
    );
  }









  /// Returns a legend widget for the given layer type.
  static Widget legend(String type) {
    switch (type) {
      case "precipitation":
        return _buildGradientLegend(
          "Precipitation (mm)",
          const [
            Color.fromRGBO(225, 200, 100, 1),
            Color.fromRGBO(150, 150, 170, 1),
            Color.fromRGBO(120, 120, 190, 1),
            Color.fromRGBO(80, 80, 225, 1),
            Color.fromRGBO(20, 20, 255, 1),
          ],
          const ["0", "1", "10", "140 mm"],
        );

      case "snow":
        return _buildGradientLegend(
          "Snow (mm)",
          const [
            Color.fromRGBO(0, 216, 255, 1),
            Color.fromRGBO(0, 182, 255, 1),
            Color.fromRGBO(149, 73, 255, 1),
          ],
          const ["0", "5", "10+", "25 mm"],
        );

      case "wind":
        return _buildGradientLegend(
          "Wind (m/s)",
          const [
            Color.fromRGBO(255, 255, 255, 0),
            Color.fromRGBO(179, 100, 188, 0.7),
            Color.fromRGBO(70, 0, 175, 1),
          ],
          const ["0", "5", "15", "50", "100 m/s"],
        );

      case "temp":
        return _buildGradientLegend(
          "Temperature (°C)",
          const [
            Color.fromRGBO(32, 140, 236, 1),
            Color.fromRGBO(35, 221, 221, 1),
            Color.fromRGBO(194, 255, 40, 1),
            Color.fromRGBO(252, 128, 20, 1),
          ],
          const ["-40", "-10", "0", "20", "30 °C"],
        );

      case "clouds":
        return _buildGradientLegend(
          "Cloud Coverage (%)",
          const [
            Color.fromRGBO(255, 255, 255, 0.1),
            Color.fromRGBO(243, 242, 255, 1),
            Color.fromRGBO(240, 240, 255, 1),
          ],
          const ["0", "50", "80", "100%"],
        );

      case "pressure":
        return _buildGradientLegend(
          "Pressure (Pa)",
          const [
            Color.fromRGBO(0, 115, 255, 1),
            Color.fromRGBO(75, 208, 214, 1),
            Color.fromRGBO(141, 231, 199, 1),
            Color.fromRGBO(198, 0, 0, 1),
          ],
          const ["94000", "98000", "101000", "106000", "108000 Pa"],
        );

      default:
        return const SizedBox.shrink(); // Empty widget if no layer active
    }
  }

  /// Builds a gradient color bar for legends.
  static Widget _buildGradientLegend(
      String title, List<Color> colors, List<String> labels) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title text of the legend
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            // The gradient bar itself
            Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Labels under the gradient
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((e) => Text(
                e,
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}