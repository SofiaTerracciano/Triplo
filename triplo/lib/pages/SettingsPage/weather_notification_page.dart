import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/pages/trekkingPage/trekking-page.dart';

class WeatherAlertSubscriptionPage extends StatefulWidget {
  const WeatherAlertSubscriptionPage({super.key});

  @override
  State<WeatherAlertSubscriptionPage> createState() =>
      _WeatherAlertSubscriptionPageState();
}

class _WeatherAlertSubscriptionPageState
    extends State<WeatherAlertSubscriptionPage> {
  late Future<List<Trekking>> _futureTrekkings;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureTrekkings =
        context.read<TrekkingController>().getWeatherAlertTrekkings();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final trekkingController = context.read<TrekkingController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(local.weather_alerts_label),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Trekking>>(
        future: _futureTrekkings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Error loading subscribed routes",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final trekkings = snapshot.data ?? [];

          if (trekkings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "No routes with weather alerts enabled",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _futureTrekkings;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trekkings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trekking = trekkings[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<File?>(
                          future: trekkingController.getCachedImage(
                            trekking.mapPhoto,
                          ),
                          builder: (context, imageSnap) {
                            Widget child;

                            if (imageSnap.connectionState ==
                                ConnectionState.waiting) {
                              child = Container(
                                width: 90,
                                height: 90,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            } else if (imageSnap.hasData &&
                                imageSnap.data != null) {
                              child = ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  imageSnap.data!,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              child = Container(
                                width: 90,
                                height: 90,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.terrain,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              );
                            }

                            return child;
                          },
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trekking.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${local.distance_trekking_label}: ${trekking.distance} km",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${local.level_label}: ${trekking.difficulty_level}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TrekkingPage(
                                            trekkingId: trekking.documentId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text("Open"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await trekkingController
                                          .disableWeatherAlertForTrekking(
                                        trekking.documentId,
                                      );

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Weather alert removed",
                                          ),
                                        ),
                                      );

                                      setState(_reload);
                                    },
                                    icon: const Icon(Icons.notifications_off),
                                    label: const Text("Remove"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}