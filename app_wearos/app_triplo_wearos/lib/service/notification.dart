import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import '/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Riferimento al navigatorKey del main per accedere al context
  GlobalKey<NavigatorState>? _navKey;

  void setNavKey(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }
  // In notification_service.dart
  FlutterLocalNotificationsPlugin get plugin => _notifications;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload ?? "");
      },
    );
  }

  void startListening({
      required void Function(LatLng location) onLocationUpdate,
    }) {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      _subscription = _firestore
          .collection('location')
          .doc(userId)
          .snapshots()
          .listen((doc) {
            if (!doc.exists) return;
            final lat = (doc['lat'] as num).toDouble();
            final lng = (doc['lng'] as num).toDouble();
            onLocationUpdate(LatLng(lat, lng));
          });
    }

    void stopListening() {
      _subscription?.cancel();
      _subscription = null;
    }

  // Tutta la logica del tap sulla notifica è qui dentro
  void _handleNotificationTap(String payload) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    final local = AppLocalizations.of(context);
    if (local == null) return;

    final challengeContent = getChallengeContent(payload, local);
    final String title = challengeContent['title'] ?? "";
    final String textToShow = (challengeContent['alert']?.isNotEmpty ?? false) 
        ? challengeContent['alert']! 
        : challengeContent['body'] ?? "";

    showDialog(
      context: context,
      barrierDismissible: true, // Permette di chiudere toccando fuori
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // Sfondo trasparente per il dialog esterno
        insetPadding: const EdgeInsets.all(12), // Margine esterno per distanziare dai bordi dell'orologio
        child: Container(
          // QUESTA È LA CHIAVE: Un cerchio perfetto!
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Grigio molto scuro, coerente con Wear OS
            shape: BoxShape.circle, // Forza il popup a essere tondo
            border: Border.all(color: Colors.white24, width: 1), // Bordo sottile opzionale per definizione
          ),
          // Padding interno importante per spingere il testo al centro del cerchio
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titolo (Bold, più grande)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // Corpo (Scrollabile se lungo)
              // Fondamentale su schermi tondi: SingleChildScrollView per testo lungo
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    textToShow,
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.white70,
                      height: 1.3 // Leggermente più distanziato per leggibilità
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Bottone OK (Distaccato dal testo)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  // Riduciamo la densità visiva del bottone
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showTrekkingNotification({
  required int id,
  required String title,
  required String body,
  required String payload,
  String channelId = 'notifications_channel',
  String channelName = 'Notifications',
  }) async {
    final NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notifications.show(
      id, 
      title, 
      body, 
      platformDetails, 
      payload: payload,
    );
  }
}

Map<String, String> getChallengeContent(
    String payload, AppLocalizations local) {
  switch (payload) {
    case "balance":
      return {
        'title': local.title_challenge_balance,
        'body': local.body_challenge_balance,
        'alert': local.alert_challenge_balance
      };
    case "hi":
      return {
        'title': local.title_challenge_hi,
        'body': local.body_challenge_hi,
        'alert': local.alert_challenge_hi
      };
    case "mini_orientiring":
      return {
        'title': local.title_challenge_mini_orientiring,
        'body': local.body_challenge_mini_orientiring,
        'alert': local.alert_challenge_mini_orientiring
      };
    case "photo":
      return {
        'title': local.title_challenge_photo,
        'body': local.body_challenge_photo,
        'alert': local.alert_challenge_photo
      };
    case "silent_walking":
      return {
        'title': local.title_challenge_silent_walking,
        'body': local.body_challenge_silent_walking,
        'alert': local.alert_challenge_silent_walking
      };
    case "time":
      return {
        'title': local.title_challenge_time,
        'body': local.body_challenge_time,
        'alert': local.alert_challenge_time
      };
    case "end_trekking_arrival":
      return {
        'title': local.title_notification_arrival,
        'body': local.body_notification_arrival,
        'alert': local.alert_notification_arrival
      };
    default:
      return {'title': "", 'body': ""};
  }
}