import 'dart:ui';
import 'package:app_triplo_wearos/controller/API.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/end_trekking.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../controller/challenge.dart';

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
    /*_initNotifications();
    _loadChallenges();
    _start();*/
    WidgetsBinding.instance.addPostFrameCallback((_) async{
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
      forceLocationManager: true
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkDistance(position);
    });
  }

  /*void _checkDistance(Position currentPos) {
    if (_hasEndedAutomatically) return;

    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);
    final local = AppLocalizations.of(context)!;

    if (trekking != null /*&& trekking.points.last.latitude != null && trekking.points.last.longitude != null*/) {
      // Calcola la distanza tra posizione attuale e destinazione
      double distanceInMeters = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        trekking.points.last.latitude, 
        trekking.points.last.longitude,
      );

      if (distanceInMeters <= 1000) {
        _hasEndedAutomatically = true;
        trekkingController.checkArrival(widget.trekkingid, distanceInMeters, local);
      }
    }
  }*/

  void _checkDistance(Position currentPos) {
    
    if (_hasEndedAutomatically) {
      return;
    }

    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);
    final local = AppLocalizations.of(context)!;

    if (trekking != null && trekking.points.isNotEmpty) {
      final lastPoint = trekking.points.last;
      
      double distanceInMeters = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        lastPoint.latitude, 
        lastPoint.longitude,
      );


      if (distanceInMeters <= 1000) {
        _hasEndedAutomatically = true;
        trekkingController.checkArrival(widget.trekkingid, distanceInMeters, local);
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

  /*Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }*/

  void _start() {
    _stopwatch.start();

    // Aggiorna UI ogni 10ms
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (mounted) setState(() {});
    });

    // Manda notifica ogni 30 minuti se ci sono challenges
    if (_challenges.isNotEmpty) {
      _challengeTimer = Timer.periodic(
        //attualmente messo a 10 secondi per vedere che funziona, poisarà ogni20 minuti
        const Duration(seconds: 10),
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
    final double screenSize = MediaQuery.of(context).size.shortestSide;
    final trekkingController = context.watch<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid)!;
    final color = difficultyToColor(trekking.difficulty_level);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: screenSize,
              height: screenSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: screenSize * 0.90,
                    height: screenSize * 0.90,
                    child: CircularProgressIndicator(
                      value:
                          (_stopwatch.elapsed.inSeconds % 60) / 60,
                      strokeWidth: 3,
                      backgroundColor:
                          const Color.fromARGB(
                              255, 100, 100, 100),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: screenSize * 0.10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                          height: 1,
                        ),
                      ),
                      SizedBox(
                          height: screenSize * 0.06),
                        //tasto di debug da togliere
                      /*ElevatedButton(
                          onPressed: () {
                            final trekkingController = context.read<TrekkingController>();
                            final local = AppLocalizations.of(context)!;
                            trekkingController.checkArrival(widget.trekkingid, 500, local);
                          },
                          child: const Text("TEST ARRIVO"),
                        ),*/
                      GestureDetector(
                        onTap: _stop,
                        child: Container(
                          width: screenSize * 0.18,
                          height: screenSize * 0.18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color,
                              width: 1,
                            ),
                            color: Colors.black
                                .withOpacity(0.4),
                          ),
                          child: Center(
                            child: Container(
                              width:
                                  screenSize * 0.07,
                              height:
                                  screenSize * 0.07,
                              decoration:
                                  BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius
                                        .circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
