import 'package:flutter/material.dart';
/*
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
    "Precipitation (mm)",
    [
      Color(0xFF0D47A1), // blu scuro
      Color(0xFF1976D2), // blu
      Color(0xFF00BCD4), // ciano
      Color(0xFF4CAF50), // verde
      Color(0xFFFFEB3B), // giallo
      Color(0xFFFF9800), // arancio
      Color(0xFFF44336), // rosso
    ],
    ["0", "1", "5", "10", "25", "50", "100"],
  );



  static Widget _snowLegend() => _buildGradientLegend(
    "Snow (mm)",
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


  static Widget _windLegend() => _buildGradientLegend(
    "Wind (m/s)",
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


  static Widget _tempLegend() => _buildGradientLegend(
    "Temperature (°C)",
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

  static Widget _cloudsLegend() => _buildGradientLegend(
    "Cloud coverage (%)",
    [
      Color.fromARGB(0, 255, 255, 255),
      Color.fromARGB(80, 255, 255, 255),
      Color.fromARGB(160, 230, 230, 230),
      Color.fromARGB(255, 200, 200, 200),
    ],
    ["0", "30", "60", "100%"],
  );


  static Widget _pressureLegend() => _buildGradientLegend(
    "Pressure (Pa)",
    [
      Color(0xFF2C7BB6),
      Color(0xFFABD9E9),
      Color(0xFFFFFFBF),
      Color(0xFFFDAE61),
      Color(0xFFD7191C),
    ],
    ["94000", "98000", "101000", "108000"],
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
 */