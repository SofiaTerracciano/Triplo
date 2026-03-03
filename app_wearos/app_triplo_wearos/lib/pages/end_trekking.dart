import 'dart:ui';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EndTrekkingPage extends StatelessWidget {
  final String trekkingid;
  final Duration elapsedTime;

  const EndTrekkingPage({
    Key? key,
    required this.trekkingid,
    required this.elapsedTime,
  }) : super(key: key);

  String get _formattedTime {
    final minutes =
        elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();
    final trekking =
        trekkingController.getTrekkingById(trekkingid)!;

    final color =
        difficultyToColor(trekking.difficulty_level);

    final local = AppLocalizations.of(context)!;

    final double screenSize =
        MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildFixedBackground(trekkingController, trekking),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize,
                ),
                child: Center(
                  child: SizedBox(
                    width: screenSize,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize * 0.12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Check icon
                          Container(
                            width: screenSize * 0.22,
                            height: screenSize * 0.22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withOpacity(0.6),
                                width: 1.5,
                              ),
                              color: Colors.black.withOpacity(0.35),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: color,
                              size: screenSize * 0.12,
                            ),
                          ),

                          SizedBox(height: screenSize * 0.045),

                          // Title
                          Text(
                            local.trekking_completed_label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize * 0.055,
                              letterSpacing: 1,
                            ),
                          ),

                          SizedBox(height: screenSize * 0.035),

                          // Time
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: screenSize * 0.12,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: screenSize * 0.06),

                          // Button
                          GestureDetector(
                            onTap: () => Navigator.popUntil(
                                context, (route) => route.isFirst),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize * 0.07,
                                vertical: screenSize * 0.03,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: color.withOpacity(0.6),
                                ),
                                color: Colors.black.withOpacity(0.25),
                              ),
                              child: Text(
                                local.home_page_title.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: screenSize * 0.048,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBackground(
      TrekkingController controller, var trekking) {
    return Stack(
      children: [
        Positioned.fill(
          child: FutureBuilder<String>(
            future: controller
                .getDownloadUrl(
                    trekking.endingPointPhoto),
            builder: (context, snapshot) {
              if (snapshot.connectionState !=
                  ConnectionState.done) {
                return Container(color: Colors.black);
              }

              if (!snapshot.hasData ||
                  snapshot.hasError) {
                return Container(color: Colors.black);
              }

              return Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 3.0, sigmaY: 3.0),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}