import 'dart:ui';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/start_trekking.dart';
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

    final Color mainColor = difficultyToColor(trekking.difficulty_level);

    final hours = trekking.estimated_time ~/ 60;
    final minutes = (trekking.estimated_time % 60).toInt();
    final formattedTime = hours > 0
        ? "${hours}h ${minutes}m"
        : "${minutes}m";

    // Dimensioni responsive basate sullo schermo
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                      fontSize: isSmallPhone ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: isSmallPhone ? 24 : 32),
                  Icon(Icons.access_time, size: isSmallPhone ? 52 : 64, color: mainColor),
                  SizedBox(height: isSmallPhone ? 14 : 18),
                  Text(
                    local.estimated_time_trekking_label,
                    style: TextStyle(
                      fontSize: isSmallPhone ? 14 : 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: isSmallPhone ? 40 : 48,
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
                        Icon(Icons.arrow_upward, size: isSmallPhone ? 44 : 52, color: mainColor),
                      if (trekking.upGain && trekking.downGain)
                        const SizedBox(width: 8),
                      if (trekking.downGain)
                        Icon(Icons.arrow_downward, size: isSmallPhone ? 44 : 52, color: mainColor),
                    ],
                  ),
                  SizedBox(height: isSmallPhone ? 14 : 18),
                  Text(
                    local.elevaition_gain_trekking_label,
                    style: TextStyle(
                      fontSize: isSmallPhone ? 14 : 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${trekking.elevation_gain.round()} m",
                    style: TextStyle(
                      fontSize: isSmallPhone ? 40 : 48,
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
                        fontSize: isSmallPhone ? 13 : 15,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: isSmallPhone ? 24 : 32),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: trekking.challenges.map<Widget>(
                          (challengeUrl) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildChallengeImage(
                              trekkingController,
                              challengeUrl,
                              mainColor,
                              size: isSmallPhone ? 72.0 : 84.0,
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              if (trekking.challenges.isEmpty)
                _buildSectionWrapper(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: isSmallPhone ? 52 : 64,
                      color: mainColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      local.no_challenge.toUpperCase(),
                      style: TextStyle(
                        fontSize: isSmallPhone ? 13 : 15,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

              // Start and Back buttons
              _buildSectionWrapper(
                children: [
                  Icon(
                    Icons.directions_walk,
                    color: Colors.white54,
                    size: isSmallPhone ? 44 : 52,
                  ),
                  SizedBox(height: isSmallPhone ? 28 : 36),
                  SizedBox(
                    width: double.infinity,
                    height: isSmallPhone ? 52 : 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                        style: TextStyle(
                          fontSize: isSmallPhone ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      local.back_label,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: isSmallPhone ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWrapper({required List<Widget> children}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

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

  Widget _buildChallengeImage(
    TrekkingController controller,
    String url,
    Color color, {
    double size = 80,
  }) {
    return FutureBuilder<String>(
      future: controller.getDownloadUrl(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _challengePlaceholder(color, size: size);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.broken_image, size: size * 0.4, color: color.withOpacity(0.5)),
          );
        }

        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error, color: color, size: size * 0.35),
            ),
          ),
        );
      },
    );
  }

  Widget _challengePlaceholder(Color color, {double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.25,
          height: size * 0.25,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      ),
    );
  }
}
