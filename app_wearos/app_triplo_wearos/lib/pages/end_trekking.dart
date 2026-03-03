import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// TODO: migliorare la grafica
class EndTrekkingPage extends StatelessWidget {
  final String trekkingid;
  final Duration elapsedTime;

  const EndTrekkingPage({
    Key? key,
    required this.trekkingid,
    required this.elapsedTime,
  }) : super(key: key);

  String get _formattedTime {
    final minutes = elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final  trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(trekkingid)!;
    final color = difficultyToColor(trekking.difficulty_level);
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: color, size: 36),
            const SizedBox(height: 10),
            const Text(
              'TREKKING\nCOMPLETATO', // da mettere nel diszioanrio
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formattedTime,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 32,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  local.home_page_title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}