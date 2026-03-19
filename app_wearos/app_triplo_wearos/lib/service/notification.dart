import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationService {
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
      builder: (_) => AlertDialog(
        // Rendi il fondo scuro o coerente con Wear OS
        backgroundColor: Colors.grey[900],
        // Arrotonda molto i bordi per seguire la forma circolare
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        insetPadding: const EdgeInsets.all(10),
        contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
        content: Container(
          // Forziamo una larghezza che stia bene nello schermo tondo
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView( // Fondamentale se il testo è lungo
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  textToShow,
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Colors.white70
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              "OK",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
            ),
          ),
        ],
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

    await _notifications.show(id, title, body, platformDetails,
        payload: payload);
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