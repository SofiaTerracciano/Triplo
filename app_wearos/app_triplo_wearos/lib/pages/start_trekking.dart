import 'dart:ui';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/main.dart';
import 'package:app_triplo_wearos/pages/end_trekking.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:app_triplo_wearos/service/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkDistance(position);
    });
  }

  void _checkDistance(Position currentPos) {
    if (_hasEndedAutomatically) return;

    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);

    if (trekking != null && trekking.points.last.latitude != null && trekking.points.last.longitude != null) {
      // Calcola la distanza tra posizione attuale e destinazione
      double distanceInMeters = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        trekking.points.last.latitude, // Assicurati che il tuo modello Trekking abbia questi campi
        trekking.points.last.longitude,
      );

      if (distanceInMeters <= 1000) {
        _hasEndedAutomatically = true;
        _sendArrivalNotification();
      }
    }
  }

  Future<void> _sendArrivalNotification() async {
    if (!mounted) return;

    // 2. Recupero il dizionario dal context
    final local = AppLocalizations.of(context)!;

    const NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
          'notifications_channel', // <--- Cambialo in 'arrival_channel'
          'Arrivo Trekking',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
    );

    await flutterLocalNotificationsPlugin.show(
      999, 
      "📍 Destinazione vicina!",
      "Sei quasi arrivato. Tocca per completare il percorso.",
      platformDetails,
      payload: 'end_trekking_arrival', // Passiamo anche l'ID nel payload
    );
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
    final challenge = _challenges[_challengeIndex];
    String title;
    String body = "";

    // Message body for the notification
    switch (challenge) {
      case "balance":
        title = "Sfida: Equilibrio";
        break;
      case "hi":
        title = "Sfida: Saluto";
        break;
      case "mini_orientiring":
        title = "Sfida: Orientamento";
        break;
      case "photo":
        title = "Sfida: Fotografia";
        break;
      case "silent_walking":
        title = "Sfida: Camminata Silenziosa";
        break;
      case "time":
        title = "Sfida: Tempo senza telefono";
        break;
      default:
        title = "Arrivato!";
    }

    try {
      await flutterLocalNotificationsPlugin.show(
        _challengeIndex,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'notifications_channel',
            'Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: challenge,
      );
    } catch (e, stack) {
      print("DEBUG ERRORE notifica: $e");
      print("DEBUG STACK: $stack");
    }

    _challengeIndex++;
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _challengeTimer?.cancel();

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
