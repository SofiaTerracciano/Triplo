import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/adding-diary-page.dart';
import 'package:triplo/pages/home-page.dart';

//TODO:  sfondo non sta funzionando (i percorsi hard hanno il nero)
class EndTrekkingPage extends StatelessWidget {
  final String trekkingid;
  final Duration elapsedTime;

  const EndTrekkingPage({
    Key? key,
    required this.trekkingid,
    required this.elapsedTime,
  }) : super(key: key);

  String get _formattedTime {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(trekkingid)!;
    final Color mainColor = difficultyToColor(trekking.difficulty_level);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          _buildFixedBackground(trekkingController, trekking),

          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 90,
                      color: mainColor,
                      shadows: [Shadow(color: mainColor.withOpacity(0.5), blurRadius: 20)],
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      local.trekking_completed_label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Tempo Finale
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text(
                      local.add_to_diary_question_label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2),
                    ),
                    
                    const SizedBox(height: 30),

                    // Goes to AddingDiaryPage button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddingDiaryPage(trekkingId: trekkingid),
                            ),
                          );
                        },
                        child: Text(local.add_to_diary_label, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Goes to HomePage button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: mainColor.withOpacity(0.5)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyHomePage()),
                          );
                        },
                        child: Text(local.not_now, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
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
}