import 'package:flutter/material.dart';

/**
 * Classe statica che costruisce le legende grafiche dei layer meteo.
 */
class WeatherLegend {
  /**
   * Restituisce la legenda corretta in base al layer attivo.
   */
  static Widget? getLegendWidget({
    required bool showPrecip,
    required bool showSnow,
    required bool showWind,
    required bool showTemp,
    required bool showClouds,
    required bool showPressure,

  }) {
    if (showPrecip) return _rainLegend();
    if (showSnow) return _snowLegend();
    if (showWind) return _windLegend();
    if (showTemp) return _tempLegend();
    if (showClouds) return _cloudsLegend();
    if (showPressure) return _pressureLegend();
    return null;
  }



  // --- Singole legende per ciascun layer ---

  static Widget _rainLegend() => _buildGradientLegend(
    "Precipitazioni (mm)",
    [
      Color.fromRGBO(225, 200, 100, 1),
      Color.fromRGBO(200, 150, 150, 1),
      Color.fromRGBO(120, 120, 190, 1),
      Color.fromRGBO(80, 80, 225, 1),
      Color.fromRGBO(20, 20, 255, 1),
    ],
    ["0", "1", "10", "140 mm"],
  );

  static Widget _snowLegend() => _buildGradientLegend(
    "Neve (mm)",
    [
      Color.fromRGBO(0, 216, 255, 1),
      Color.fromRGBO(0, 182, 255, 1),
      Color.fromRGBO(149, 73, 255, 1),
    ],
    ["0", "5", "10+", "25 mm"],
  );

  static Widget _windLegend() => _buildGradientLegend(
    "Vento (m/s)",
    [
      Color.fromRGBO(255, 255, 255, 0),
      Color.fromRGBO(238, 206, 206, 0.4),
      Color.fromRGBO(179, 100, 188, 0.7),
      Color.fromRGBO(70, 0, 175, 1),
    ],
    ["0", "5", "15", "100 m/s"],
  );

  static Widget _tempLegend() => _buildGradientLegend(
    "Temperatura (°C)",
    [
      Color.fromRGBO(130, 22, 146, 1),
      Color.fromRGBO(32, 140, 236, 1),
      Color.fromRGBO(194, 255, 40, 1),
      Color.fromRGBO(252, 128, 20, 1),
    ],
    ["-40", "-10", "0", "30 °C"],
  );

  static Widget _pressureLegend() => _buildGradientLegend(
    "Pressione (Pa)",
    [
      Color.fromRGBO(0, 115, 255, 1),
      Color.fromRGBO(75, 208, 214, 1),
      Color.fromRGBO(251, 85, 21, 1),
      Color.fromRGBO(198, 0, 0, 1),
    ],
    ["94000", "98000", "101000", "108000 Pa"],
  );

  static Widget _cloudsLegend() => _buildGradientLegend(
    "Copertura nuvolosa (%)",
    [
      Color.fromRGBO(255, 255, 255, 0.1),
      Color.fromRGBO(243, 242, 255, 1),
      Color.fromRGBO(240, 240, 255, 1),
    ],
    ["0", "50", "100%"],
  );

  /**
   * Costruisce una barra colorata con etichette per la legenda.
   */
  static Widget _buildGradientLegend(
      String title, List<Color> colors, List<String> labels) {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((e) => Text(e, style: const TextStyle(fontSize: 10, color: Colors.black))).toList(),




            ),
          ],
        ),
      ),
    );
  }
}