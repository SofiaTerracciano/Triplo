import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:triplo/l10n/app_localizations.dart' show AppLocalizations;

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
  static Widget legend(String type, BuildContext context) {
    final local = AppLocalizations.of(context)!;
    
    switch (type) {
      case "precipitation":
        return _buildGradientLegend(
          "${local.layer_precipitation} (mm)",
          [
            Color(0xFFE0F7FA), // quasi bianco
            Color(0xFF1976D2), // blu
            Color(0xFF00BCD4), // ciano
            Color(0xFF4CAF50), // verde
            Color(0xFFFFEB3B), // giallo
            Color(0xFFFF9800), // arancio
            Color(0xFFF44336), // rosso
          ],
          ["0", "1", "5", "10", "25", "50", "100"],
        );

      case "snow":
        return _buildGradientLegend(
          "$local.layer_snow (mm)",
          [
            Color(0xFFE0F7FA), // quasi bianco
            Color(0xFF81D4FA), // azzurro
            Color(0xFF29B6F6), // blu
            Color(0xFF4CAF50), // verde
            Color(0xFFFFF176), // giallo chiaro
            Color(0xFFFF9800), // arancio
            Color(0xFFF44336), // rosso
          ],
          ["0", "1", "5", "7", "10", "12", "25"],
        );

      case "wind":
        return _buildGradientLegend(
          "$local.layer_wind (m/s)",
          [
            Color(0xFF0D47A1), // blu scuro
            Color(0xFF1976D2), // blu
            Color(0xFF00BCD4), // ciano
            Color(0xFF4CAF50), // verde
            Color(0xFFFFEB3B), // giallo
            Color(0xFFFF9800), // arancio
          ],
          ["0", "5", "10", "20", "40", "80"],
        );

      case "temp":
        return _buildGradientLegend(
          "$local.layer_temperature (°C)",
          [
            Color(0xFF0D47A1), // molto freddo
            Color(0xFF1976D2), // freddo
            Color(0xFF00BCD4), // fresco
            Color(0xFF4CAF50), // mite
            Color(0xFFFFEB3B), // caldo
            Color(0xFFFF9800), // molto caldo
          ],
          ["-30", "-10", "0", "10", "20", "35"],
        );

      case "clouds":
        return _buildGradientLegend(
          "$local.layer_clouds (%)",
          [
            Color.fromARGB(0, 255, 255, 255),
            Color.fromARGB(80, 255, 255, 255),
            Color.fromARGB(160, 230, 230, 230),
            Color.fromARGB(255, 200, 200, 200),
          ],
          ["0", "30", "60", "100%"],
        );

      case "pressure":
        return _buildGradientLegend(
          "$local.layer_pressure (Pa)",
          [
            Color(0xFF2C7BB6),
            Color(0xFFABD9E9),
            Color(0xFFFFFFBF),
            Color(0xFFFDAE61),
            Color(0xFFD7191C),
          ],
          ["94000", "98000", "101000", "108000"],
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