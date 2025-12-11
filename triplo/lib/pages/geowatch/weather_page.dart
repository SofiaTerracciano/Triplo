import 'package:flutter/material.dart';
import 'package:triplo/controller/API.dart';

class WeatherPage extends StatelessWidget {
  final Map<String, dynamic> weather;
  final List<Map<String, dynamic>> forecast;


  WeatherPage({
    Key? key,
    required this.weather,
    required this.forecast,
  }) : super(key: key);

  final API api = API();



  @override
  Widget build(BuildContext context) {
    final place = weather['name'] ?? "Current position";
    final temp = weather['main']?['temp']?.round() ?? "-";
    final rawDescription = (weather['weather']?[0]?['description'] ?? "-").toString().toLowerCase();
    final description = rawDescription;
    final icon = weather['weather']?[0]?['icon'] ?? "01d";





    return Scaffold(
      appBar: AppBar(
        title: Text("$place"),
        backgroundColor: Colors.green[700],
        /*actions: [
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (newLang) {
            },
            itemBuilder: (context) => AppLanguage.values.map((lang) {
              return PopupMenuItem(
                value: lang,
                child: Text(lang.name),
              );
            }).toList(),
          ),
        ],*/

      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(api.weatherIconUrl(icon), width: 100),
            Text("$temp°C",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(description.capitalize(),
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            Text("Previsioni per i prossimi giorni",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final f = forecast[index];
                  //final dt = DateTime.parse(f['dt_txt']);
                  //final t = f['main']['temp'].round();
                  //final ic = f['weather'][0]['icon'];
                  //final rawDescriptionDay =
                  //(f['weather'][0]['description'] ?? "-").toString().toLowerCase();
                  //final descriptionDay = rawDescriptionDay;

                  return ListTile(
                    leading: Image.network(api.weatherIconUrl(f["icon"], big: false)),
                    title: Text("${f["date"].day}/${f["date"].month} – ${f["description"].capitalize()}"),
                    trailing: Text("${f["temp"]}°C",
                        style: const TextStyle(fontSize: 18)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasing on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}