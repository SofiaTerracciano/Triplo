import 'dart:async';
import 'dart:ui';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/trekkingPage/end_trekking_page.dart';
import 'package:triplo/pages/HomePage/home-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class StartTrekkingPage extends StatefulWidget {
  final String trekkingid;

  const StartTrekkingPage({Key? key, required this.trekkingid})
    : super(key: key);

  @override
  State<StartTrekkingPage> createState() => _StartTrekkingPageState();
}

class _StartTrekkingPageState extends State<StartTrekkingPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _challengeTimer;
  int _challengeIndex = 0;
  List<String> _challenges = [];
  StreamSubscription<Position>? _positionStream;
  bool _hasEndedAutomatically = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadChallenges();
      _start();
      _initGpsTracking();
    });
  }

  void _initGpsTracking() async {
    // Controlliamo semplicemente se abbiamo il permesso prima di far partire lo stream.
    // Se non lo abbiamo, usciamo dalla funzione senza dire nulla all'utente.
    final status = await Permission.location.status;
    if (!status.isGranted) return;

    LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _checkDistance(position);
          },
        );
  }

  void _checkDistance(Position currentPos) {
    if (_hasEndedAutomatically) return;

    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);
    final local = AppLocalizations.of(context)!;

    if (trekking != null && trekking.points.isNotEmpty) {
      double distanceInMeters = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        trekking.points.last.latitude,
        trekking.points.last.longitude,
      );

      if (distanceInMeters <= 1000) {
        _hasEndedAutomatically = true;
        // Il controller ora gestisce la logica della notifica
        trekkingController.checkArrival(widget.trekkingid, distanceInMeters, currentPos, local);
      }
    }
  }

  void _loadChallenges() {
    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);
    if (trekking != null) {
      _challenges = trekking.challenges.map((url) {
        String nome = url.split('/').last;
        nome = nome.replaceAll('.png', '');
        nome = nome.replaceAll('_challenge', '');
        return nome.toLowerCase();
      }).toList();
    }
  }

  void _start() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (mounted) setState(() {});
    });

    if (_challenges.isNotEmpty) {
      _challengeTimer = Timer.periodic(
        const Duration(
          seconds: 30,
        ), // ricordarsi di mettere in minuti in produzione
        (_) => _sendChallengeNotification(),
      );
    }
  }

  Future<void> _sendChallengeNotification() async {
    if (_challenges.isEmpty || !mounted) return;
    
    if (_challengeIndex >= _challenges.length) {
      _challengeTimer?.cancel();
      return;
    }

    final local = AppLocalizations.of(context)!;
    final challengePayload = _challenges[_challengeIndex];
    
    // Usiamo il controller delle sfide
    context.read<ChallengesController>().notifyNewChallenge(challengePayload, local);

    _challengeIndex++;
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _challengeTimer?.cancel();
    _positionStream?.cancel(); // Importante: ferma il GPS!

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndTrekkingPage(
          trekkingid: widget.trekkingid,
          elapsedTime: _stopwatch.elapsed,
        ),
      ),
    );
  }

  String get _formattedTime {
    final elapsed = _stopwatch.elapsed;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _challengeTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);

    final Color mainColor = trekking != null
        ? difficultyToColor(trekking.difficulty_level)
        : const Color(0xFF2F80ED);

    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.height < 700;

    final double circleSize = size.width * 0.78;

    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with trekking name and icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.terrain, color: mainColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trekking?.name ?? "TREKKING",
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Timer with progress ring
                Center(
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: CircularProgressIndicator(
                            value:
                                (_stopwatch.elapsed.inMilliseconds % 60000) /
                                60000,
                            strokeWidth: 6,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              mainColor,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: mainColor.withOpacity(0.6),
                              size: isSmallPhone ? 28 : 32,
                            ),
                            SizedBox(height: isSmallPhone ? 8 : 12),
                            Text(
                              _formattedTime,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: isSmallPhone ? 42 : 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: isSmallPhone ? 4 : 6),
                            Text(
                              local.trekking_in_progress_label,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: isSmallPhone ? 11 : 13,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Stop button
                Padding(
                  padding: EdgeInsets.only(bottom: isSmallPhone ? 32 : 48),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _stop,
                        child: Container(
                          width: isSmallPhone ? 80 : 96,
                          height: isSmallPhone ? 80 : 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor.withOpacity(0.1),
                            border: Border.all(
                              color: mainColor.withOpacity(0.5),
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: isSmallPhone ? 30 : 36,
                              height: isSmallPhone ? 30 : 36,
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        local.stop_trekking,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: isSmallPhone ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
