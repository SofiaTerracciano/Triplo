import 'dart:ui';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/details_trekking.dart';
import 'package:app_triplo_wearos/pages/HomePage/home-page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../GeowatchPage/geowatch.dart';

class TrekkingPage extends StatelessWidget {
  final String trekkingId;

  const TrekkingPage({super.key, required this.trekkingId});

  @override
  Widget build(BuildContext context) {
    final languageController = context.watch<Language>();
    final langCode = languageController.locale.languageCode;
    final langIndex = getLanguageSelected(langCode);

    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(trekkingId);

    if (trekking == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Error", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Color based on difficulty
    final Color mainColor = difficultyToColor(trekking.difficulty_level);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with blur
          _buildFixedBackground(trekkingController, trekking),
          PageView(
            scrollDirection: Axis.vertical,
            children: [
              // List of sections
              _buildHeroSection(context, trekking, mainColor),
              _buildTechnicalSection(
                trekking,
                trekking.estimated_time.toInt(),
                mainColor,
              ),
              // Details and description
              _buildInfoSection(context, trekking, mainColor, langIndex),
              // Start trekking
              _buildStartSection(context, trekking, mainColor),
              // Back and Meteo
              _buildActionsSection(context, trekking, mainColor),
            ],
          ),
        ],
      ),
    );
  }

  // Title and level
  Widget _buildHeroSection(BuildContext context, var trekking, Color color) {
    final local = AppLocalizations.of(context)!;
    String level;

    // Logica per il livello
    if (trekking.difficulty_level == "easy") { 
      level = local.beginner_level;
    } else if (trekking.difficulty_level == "intermediate") {
      level = local.intermediate_level;
    } else {
      level = local.advanced_level;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terrain, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              trekking.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 3,
              softWrap: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              level.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icons
  Widget _buildTechnicalSection(var trekking, int estimatedTime, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Starting point
              _watchLocationRowCompact(
                Icons.place,
                trekking.starting_point_name!,
                color,
              ),
              const SizedBox(height: 4),
              // Ending point
              _watchLocationRowCompact(
                Icons.flag,
                trekking.ending_point_name!,
                color,
              ),

              const SizedBox(height: 10),
              //Distance, elevation gain, estimated time
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Distance
                    _buildCompactStat(
                      Icons.straighten,
                      "${trekking.distance}km",
                      color,
                    ),

                    // Elevation gain with conditional arrows
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trekking.upGain == true)
                              Icon(Icons.arrow_upward, color: color, size: 14),

                            if (trekking.downGain == true)
                              Icon(
                                Icons.arrow_downward,
                                color: color,
                                size: 14,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${trekking.elevation_gain}m",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Estimated time
                    _buildCompactStat(
                      Icons.schedule,
                      formatShortTimeFromMinutes(
                        trekking.estimated_time.toInt(),
                      ),
                      color,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Service icons
              _buildServiceIcons(trekking, color),
            ],
          ),
        ),
      ),
    );
  }

  // Info
  Widget _buildInfoSection(
    BuildContext context,
    var trekking,
    Color color,
    int langIndex,
  ) {
    String infoText = "";
    if (trekking.info != null && trekking.info.length > langIndex) {
      infoText = trekking.info[langIndex];
    } else {
      // Fallback to english if selected language is not available, otherwise to the first element of the list
      infoText = trekking.info.length > 1 ? trekking.info[1] : trekking.info[0];
    }
    final local = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      child: Column(
        children: [
          Text(
            local.details_trekking_label, 
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                infoText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Back and Meteo
  Widget _buildActionsSection(BuildContext context, var trekking, Color color) {
    final local = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weather Button
          _actionButton(
            Icons.wb_sunny,
            local.weather_trekking_label,
            Colors.blueGrey[800]!,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GeowatchPage(trekkingId: trekking.documentId)
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Back Button
          _actionButton(
            Icons.arrow_back,
            local.home_page_title,
            color,
            () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Start trekking if you want
  Widget _buildStartSection(BuildContext context, var trekking, Color color,) {
    final local = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              local.start_question_label, 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: 130,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsTrekking(
                        trekkingid: trekking.documentId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text(
                  local.start_trekking_label,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button for meteo and back
  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 140,
      height: 35,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
    );
  }

  // Background with blur
  Widget _buildFixedBackground(TrekkingController controller, var trekking) {
    return Stack(
      children: [
        Positioned.fill(
          child: FutureBuilder<String>(
            future: controller.getDownloadUrl(trekking.endingPointPhoto),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container(color: Colors.black);
              return Image.network(snapshot.data!, fit: BoxFit.cover);
            },
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  // Helper for location rows (starting and ending point) with compact layout for watch
  Widget _watchLocationRowCompact(IconData icon, String text, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(height: 2),

        SizedBox(
          width: 140,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  // Helper for distance, elevation gain, and estimated time with compact layout for watch
  Widget _buildCompactStat(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Hours/hour -> h, Minutes/minute --> m
  String formatShortTimeFromMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return "${hours}h${minutes}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else {
      return "${minutes}m";
    }
  }

  // Helper for service icons (PicNic, Refreshment, Family) with compact layout for watch
  Widget _buildServiceIcons(var trekking, Color color) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: [
        if (trekking.pic_nic_area == true)
          Icon(Icons.table_restaurant, color: color, size: 16),
        if (trekking.refreshment_point != null &&
            trekking.refreshment_point.isNotEmpty)
          Icon(Icons.restaurant, color: color, size: 16),
        if (trekking.family_firendly == true)
          Icon(Icons.family_restroom, color: color, size: 16),
      ],
    );
  }

  // Get language index based on language code --> it is used to select the correct language from info and description lists
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
}
