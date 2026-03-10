import 'dart:ui';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:triplo/pages/trekkingPage/start_trekking.dart';
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
    final String formattedTime = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildFixedBackground(trekkingController, trekking),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          // Centra tutto verticalmente
                          mainAxisAlignment: MainAxisAlignment.center,
                          // Centra tutto orizzontalmente
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header
                            Text(
                              local.before_start.toUpperCase(),
                              style: TextStyle(
                                color: mainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trekking.name, 
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 48),

                            // Info Cards
                            Row(
                              children: [
                                _buildInfoCard(
                                  icon: Icons.access_time_rounded,
                                  label: local.estimated_time_trekking_label,
                                  value: formattedTime,
                                  color: mainColor,
                                ),
                                const SizedBox(width: 16),
                                _buildInfoCard(
                                  icon: trekking.upGain ? Icons.arrow_upward : Icons.arrow_downward,
                                  label: local.elevaition_gain_trekking_label,
                                  value: "${trekking.elevation_gain.round()} m",
                                  color: mainColor,
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Challenge Section 
                            _buildChallengeSection(local, trekking, trekkingController, mainColor),

                            const SizedBox(height: 48),

                            // Pulsanti Finali
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mainColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StartTrekkingPage(trekkingid: trekkingid),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      local.start_trekking_label.toUpperCase(),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    local.back_label,
                                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 11)
            ),
            const SizedBox(height: 4),
            Text(
              value, 
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection(var local, var trekking, var controller, Color mainColor) {
    return Column(
      children: [
        Text(
          local.challeng_title.toUpperCase(),
          style: TextStyle(
            color: mainColor, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        if (trekking.challenges.isEmpty)
          Text(local.no_challenge, style: const TextStyle(color: Colors.white38))
        else
          // Allineamento centrale delle icone sfide
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: trekking.challenges.map<Widget>((url) {
              return _buildChallengeImage(controller, url, mainColor, size: 64);
            }).toList(),
          ),
      ],
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
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeImage(TrekkingController controller, String url, Color color, {double size = 64}) {
    return FutureBuilder<String>(
      future: controller.getDownloadUrl(url),
      builder: (context, snapshot) {
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: snapshot.hasData 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(snapshot.data!, fit: BoxFit.contain),
              )
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}