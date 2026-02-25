import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class Weather extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool loading;
  final String? error;
  final bool hideLocationName;
  const Weather({
    Key? key,
    required this.weather,
    required this.loading,
    required this.error,

    this.hideLocationName = false,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Text(
        "${local.weather_error_label}: $error",
        style: const TextStyle(color: Colors.red),
      );
    }

    if (weather == null) {
      return Text(local.no_weather_available_label);
    }

    final place = hideLocationName
        ? local.trail_area_label
        : (weather!['name'] ?? local.current_position_label);

    final temp = weather!['main']?['temp']?.round() ?? "-";
    final desc = weather!['weather']?[0]?['description'] ?? "-";
    final icon = weather!['weather']?[0]?['icon'] ?? "01d";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.network(
              "https://openweathermap.org/img/wn/$icon@2x.png",
              width: 70,
            ),
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
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
