import 'dart:ui';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/HomePage/home-page.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/start_trekking.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DetailsTrekking extends StatelessWidget {
  final String trekkingid;

  const DetailsTrekking({
    Key? key,
    required this.trekkingid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(trekkingid)!;

    // Colore basato sulla difficoltà (stessa logica dell'altra pagina)
    final Color mainColor = difficultyToColor(trekking.difficulty_level);

    final hours = trekking.estimated_time ~/ 60;
    final minutes = (trekking.estimated_time % 60).toInt();
    final formattedTime = hours > 0 
      ? "${hours}h ${minutes}m" 
      : "${minutes}m";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background con immagine del trekking e blur
          _buildFixedBackground(trekkingController, trekking),

          PageView(
            scrollDirection: Axis.vertical,
            children: [
              // Estimated time + Title
              _buildSectionWrapper(
                children: [
                  Text(
                    local.before_start.toUpperCase(),
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Icon(Icons.access_time, size: 30, color: mainColor),
                  const SizedBox(height: 8),
                  Text(
                    local.estimated_time_trekking_label,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Elevation gain
              _buildSectionWrapper(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (trekking.upGain)
                        Icon(Icons.arrow_upward, size: 28, color: mainColor),
                      if (trekking.downGain)
                        Icon(Icons.arrow_downward, size: 28, color: mainColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    local.elevaition_gain_trekking_label,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  Text(
                    "${trekking.elevation_gain.round()} m",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Challenges (present or not)
              if (trekking.challenges.isNotEmpty)
                _buildSectionWrapper(
                  children: [
                    Text(
                      local.challeng_title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: trekking.challenges.map<Widget>(
                          (challengeUrl) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildChallengeImage(
                                trekkingController, challengeUrl, mainColor),
                          ),
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              if (trekking.challenges.isEmpty)
                _buildSectionWrapper(
                  children: [
                    Text(
                      local.no_challenge.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                  ],
                ),

              //Start and Back buttons
              _buildSectionWrapper(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.white54, size: 24),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 130,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartTrekkingPage(
                              trekkingid: trekkingid,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        local.start_trekking_label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      local.back_label,
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to center sections with some padding
  Widget _buildSectionWrapper({required List<Widget> children}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  // Background with image + blur
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
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }

  // Challenges images with loading placeholder
  Widget _buildChallengeImage(TrekkingController controller, String url, Color color) {
    return FutureBuilder<String>(
      future: controller.getDownloadUrl(url),
      builder: (context, snapshot) {
        // To manage loading state, show placeholder until the image is loaded
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _challengePlaceholder(color);
        }

        // Gestione errore (se una specifica immagine non esiste o fallisce)
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.broken_image, size: 20, color: color.withOpacity(0.5)),
          );
        }

        return Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(6), 
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), 
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.contain, 
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: color, size: 18),
            ),
          ),
        );
      },
    );
  }

  // Placeholder widget while loading challenge images
  Widget _challengePlaceholder(Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      ),
    );
  }
}