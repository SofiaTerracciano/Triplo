import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home-page.dart';

class GeowatchPage extends StatefulWidget {
  final String trekkingId;

  const GeowatchPage({super.key, required this.trekkingId});

  @override
  State<GeowatchPage> createState() => _GeowatchPageState();
}

class _GeowatchPageState extends State<GeowatchPage> {
  Map<String, dynamic>? currentWeather;
  List<Map<String, dynamic>> forecast = [];
  List<Map<String, dynamic>> alerts = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final trekkingController = context.read<TrekkingController>();
      final serviceController = context.read<ServiceController>();
      final languageController = context.read<Language>();

      final trekking = trekkingController.getTrekkingById(widget.trekkingId);
      if (trekking == null) {
        if (!mounted) return;
        setState(() {
          error = "TREKKING_NOT_FOUND";
          loading = false;
        });
        return;
      }

      final target = trekking.starting_point ?? trekking.ending_point;
      if (target == null) {
        if (!mounted) return;
        setState(() {
          error = "NO_LOCATION";
          loading = false;
        });
        return;
      }

      final langCode = languageController.locale.languageCode;

      final weatherRes = await serviceController.weather(
        target.latitude,
        target.longitude,
        langCode,
      );

      final forecastRes = await serviceController.forecast(
        target.latitude,
        target.longitude,
        langCode,
      );

      List<Map<String, dynamic>> realAlerts = [];
      List<Map<String, dynamic>> mockAlerts = [];

      try {
        realAlerts = await serviceController.weatherbitAlerts(
          target.latitude,
          target.longitude,
        );
      } catch (_) {}

      try {
        mockAlerts = await serviceController.mockAlerts();
      } catch (_) {}

      debugPrint("Weather loaded: ${weatherRes != null}");  //coverage:ignore-line
      debugPrint("Forecast loaded: ${forecastRes?.length ?? 0}"); //coverage:ignore-line
      debugPrint("Real alerts: ${realAlerts.length}"); //coverage:ignore-line
      debugPrint("Mock alerts: ${mockAlerts.length}"); //coverage:ignore-line

      if (!mounted) return;

      setState(() {
        currentWeather = weatherRes;
        forecast = forecastRes != null
            ? serviceController.parseForecast(forecastRes)
            : [];
        alerts = [...realAlerts, ...mockAlerts];
        loading = false;
      });
    } catch (e) {
      debugPrint("Weather page load error: $e"); //coverage:ignore-line
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingId);
    final local = AppLocalizations.of(context)!;

    if (trekking == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Error", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final color = difficultyToColor(trekking.difficulty_level);

    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      )
          : PageView(
        scrollDirection: Axis.vertical,
        children: [
          _buildCurrentWeatherSection(context, trekking.name, color),
          _buildForecastSection(context, color),
          _buildAlertsSection(context, color),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherSection(
      BuildContext context,
      String trekkingName,
      Color color,
      ) {
    final weather = currentWeather;
    if (weather == null) {
      return _buildSimpleMessage("No weather data", color);
    }

    final temp = weather["main"]?["temp"]?.round()?.toString() ?? "--";
    final description =
        weather["weather"]?[0]?["description"]?.toString() ?? "";
    final icon = weather["weather"]?[0]?["icon"]?.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              trekkingName.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            if (icon != null)
              Image.network(
                context.read<ServiceController>().weatherIconUrl(icon),
                width: 42,
                height: 42,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.cloud,
                  color: color,
                  size: 28,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              "$temp°",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, Color color) {
    if (forecast.isEmpty) {
      return _buildSimpleMessage("No forecast data", color);
    }

    final shownForecast = forecast.take(4).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "FORECAST",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            ...shownForecast.map((item) {
              final date = item["date"] as DateTime;
              final temp = item["temp"];
              final icon = item["icon"];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        _shortDay(date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (icon != null)
                      Image.network(
                        context.read<ServiceController>().weatherIconUrl(icon),
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.cloud,
                          color: color,
                          size: 14,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      "$temp°",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, Color color) {
    if (alerts.isEmpty) {
      return _buildSimpleMessage("No alerts", color, icon: Icons.verified);
    }

    final shownAlerts = alerts.take(3).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(height: 6),
            const Text(
              "ALERTS",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            ...shownAlerts.map((alert) {
              final title = (alert["event"] ?? "Weather alert").toString();
              final severity = (alert["severity"] ?? "").toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                      width: 0.6,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (severity.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          severity,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMessage(String text, Color color, {IconData? icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDay(DateTime date) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }
}