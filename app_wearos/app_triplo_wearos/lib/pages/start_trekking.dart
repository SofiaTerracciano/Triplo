import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/pages/end_trekking.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadChallenges();
    _start();
  }

  void _loadChallenges() {
    // Legge il trekking dal controller tramite context
    final trekkingController = context.read<TrekkingController>();
    final trekking = trekkingController.getTrekkingById(widget.trekkingid);
    if (trekking != null) {
      _challenges = trekking.challenges;
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  void _start() {
    _stopwatch.start();

    // Aggiorna UI ogni 10ms
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      setState(() {});
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

  //TODO: mostrare notifica con sfida, attualmente è solo un print
  Future<void> _sendChallengeNotification() async {
    if (_challenges.isEmpty) return;

    // Prende la challenge corrente e avanza all'indice successivo (ciclico)
    final challenge = _challenges[_challengeIndex % _challenges.length];
    _challengeIndex++;

    /*const androidDetails = AndroidNotificationDetails(
      'challenge_channel',
      'Challenge Notifiche',
      channelDescription: 'Notifiche challenge trekking',
      importance: Importance.high,
      priority: Priority.high,
    );

    await notifications.show(
      _challengeIndex,
      '🏆 Nuova Sfida!',
      challenge,
      const NotificationDetails(android: androidDetails),
    );*/
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
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds = (elapsed.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _challengeTimer?.cancel();
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
      body: Center(
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
                  value: (_stopwatch.elapsed.inSeconds % 60) / 60,
                  strokeWidth: 3,
                  backgroundColor: const Color.fromARGB(255, 100, 100, 100),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
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
                  SizedBox(height: screenSize * 0.06),
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
                        color: Colors.black,
                      ),
                      child: Center(
                        child: Container(
                          width: screenSize * 0.07,
                          height: screenSize * 0.07,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
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
    );
  }
}
