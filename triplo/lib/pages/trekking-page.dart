import 'package:flutter/material.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/pages/adding-diary-page.dart';
import 'package:triplo/pages/geowatch/geowatch.dart';
import '../controller/trekking.dart';
import '../controller/user.dart';
import 'package:provider/provider.dart';

class TrekkingPage extends StatefulWidget {
  final String trekkingId;

  TrekkingPage({
    super.key,
    required this.trekkingId,
  });

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  // Icons for the bookmark button (unsaved and saved) --> 0:not saved, 1:saved
  final List<Icon> icons = [Icon(Icons.bookmark_border), Icon(Icons.bookmark)];

  final titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  final labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600, // semibold
    color: Colors.black87,
  );

  final valueStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: const Color.fromARGB(255, 0, 0, 0),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final languageController = context.watch<Language>();
    final langCode = languageController.locale.languageCode;
    final langIndex = getLanguageSelected(langCode);

    final trekkingController =context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingId)!;

    final userController = context.watch<UserController>();
    final user = userController.currentUser!;

    // To calculate the trekking durantion time
    String formattedTime;
    if (trekking.estimated_time < 60) {
      formattedTime =
          "${(trekking.estimated_time).toInt()} ${local.minutes_trekking_label}";
    } else {
      if (trekking.estimated_time % 60 == 0) {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hour_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hours_trekking_label}";
        }
      } else {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hour_trekking_label} ${(trekking.estimated_time % 60).toInt()} ${local.minutes_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time ~/ 60} ${local.hours_trekking_label} ${(trekking.estimated_time % 60).toInt()} ${local.minutes_trekking_label}";
        }
      }
    }

    final bool isSaved = user.savedTrekkings.any(
      (t) => t.documentId == trekking.documentId,
    );

    print(trekking.endingPointPhoto);

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddingDiaryPage(
                    trekkingId: trekking.documentId,
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: isSaved ? icons[1] : icons[0],
            onPressed: () async {
              if (isSaved) {
                await userController.removeTrekkingFromSaved(
                  trekking.documentId,
                );
              } else {
                await userController.addTrekkingToSaved(
                  trekking.documentId,
                );
              }

              setState(() {}); // ricostruisce l'AppBar
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAP PHOTO
            _photoSection(
              trekkingController.getDownloadUrl(trekking.mapPhoto),
            ),

            const SizedBox(height: 16),

            // TITLE
            Text(
              trekking.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // INFO CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _infoRichRow(
                      Icons.place,
                      local.starting_point_trekking_label,
                      trekking.starting_point_name,
                    ),
                    _infoRichRow(
                      Icons.flag,
                      local.ending_point_trekking_label,
                      trekking.ending_point_name,
                    ),
                    _infoRow(
                      Icons.terrain,
                      local.level_label,
                      trekking.difficulty_level,
                      valueColor: _difficultyColor(trekking.difficulty_level),
                    ),
                    _infoRow(
                      Icons.straighten,
                      local.distance_trekking_label,
                      "${trekking.distance} km",
                    ),
                    _infoRow(
                      Icons.schedule,
                      local.estimated_time_trekking_label,
                      formattedTime,
                    ),
                    _elevationRow(
                      local.elevaition_gain_trekking_label,
                      trekking.elevation_gain,
                      trekking.upGain,
                      trekking.downGain,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ENDING POINT PHOTO
            _photoSection(
              trekkingController.getDownloadUrl(
                trekking.endingPointPhoto,
              ),
            ),

            const SizedBox(height: 24),

            // INFO
            _sectionTitle(local.info_trekking_label),
            Text(trekking.info[langIndex]),

            const SizedBox(height: 16),

            // DESCRIPTION
            _sectionTitle(local.description_trekking_label),
            Text(
              trekking.description[langIndex],
            ),

            const SizedBox(height: 16),

            // Refreshment point
            _refreshmentRow(
              local.refreshment_point_trekking_label,
              trekking.refreshment_point.isNotEmpty
                  ? trekking.refreshment_point
                  : local.refreshment_point_available_trekking_label,
            ),

            // Family friendly
            _familyRow(
              Icons.family_restroom,
              local.family_friendly_trekking_label,
              trekking.family_firendly
                  ? local.yes_botton_label
                  : local.no_botton_label,
            ),

            const SizedBox(height: 16),

            // CHALLENGES
            _sectionTitle(local.challenges_trekking_label),
            trekking.challenges.isNotEmpty
                ? FutureBuilder<List<String>>(
                    future: trekkingController.getDownloadUrls(
                      trekking.challenges,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      return Wrap(
                        spacing: 8,
                        children: snapshot.data!
                            .map(
                              (url) => Chip(
                                avatar: const Icon(Icons.warning, size: 16),
                                label: Image.network(url, height: 24),
                              ),
                            )
                            .toList(),
                      );
                    },
                  )
                : Text(local.challenges_available_trekking_label),

            const SizedBox(height: 16),

            // WEATHER
            _sectionTitle(local.weather_trekking_label),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeoWatchPage(), // i controller?
                  ),
                );
              },
              child: Text(local.weather_trekking_botton),
            ),

            const SizedBox(width: 10,)
          ],
        ),
      ),
    );
  }

  int getLanguageSelected(String code) {
    switch (code) {
      case 'de':
        return 0;
      case 'en':
        return 1;
      case 'es':
        return 2;
      case 'fr':
        return 3;
      case 'it':
        return 4;
      default:
        return 1;
    }
  }

  Widget _photoSection(Future<String> future) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            snapshot.data!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _infoRichRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),

          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label:\n",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refreshmentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant, size: 18),
          const SizedBox(width: 8),

          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),

          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  Widget _familyRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return Colors.lightBlue;
      case "intermediate":
        return Colors.red;
      case "hard":
        return Colors.black;
      default:
        return Colors.blueGrey; // fallback
    }
  }

  Widget _elevationRow(
    String label,
    double elevation,
    bool upGain,
    bool downGain,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 18),
          const SizedBox(width: 8),

          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),

          Text("$elevation m"),

          const SizedBox(width: 6),

          if (upGain)
            const Icon(Icons.arrow_upward, size: 16, color: Colors.black),

          if (downGain)
            const Icon(Icons.arrow_downward, size: 16, color: Colors.black),
        ],
      ),
    );
  }
}
