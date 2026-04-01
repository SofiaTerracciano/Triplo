import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Riferimento al navigatorKey del main per accedere al context
  GlobalKey<NavigatorState>? _navKey;

  void setNavKey(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }

  GlobalKey<NavigatorState>? getNavKey() => _navKey;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings
    iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // IMPORTANTE: Permette di mostrare la notifica di sistema ANCHE se l'app è aperta
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload ?? "");
      },
    );

    // --- LOGICA SPECIFICA PER iOS (App terminata/chiusa) ---
    if (Platform.isIOS) {
      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null) {
          // Usiamo un delay per essere sicuri che la UI di Flutter sia pronta
          // e il navigatorKey sia popolato dopo il boot
          Future.delayed(const Duration(milliseconds: 800), () {
            _handleNotificationTap(payload);
          });
        }
      }
    }

    if (Platform.isIOS) {
      await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    }
  }

  // Tutta la logica del tap sulla notifica è qui dentro
  void _handleNotificationTap(String payload) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    final local = AppLocalizations.of(context);
    if (local == null) return;

    final challengeContent = notificationcontent(payload, local);
    final String title = challengeContent['title'] ?? "";

    // QUI LA LOGICA RICHIESTA:
    // Se esiste un alert specifico, usalo. Altrimenti usa il body.
    final String textToShow = (challengeContent['alert']?.isNotEmpty ?? false)
        ? challengeContent['alert']!
        : challengeContent['body'] ?? "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(textToShow),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
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
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
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

  Future<void> showWeatherNotification({
    required int id,
    required String title,
    required String body,
    String payload = 'weather_alert',
  }) async {
    await showTrekkingNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: 'weather_alerts_channel',
      channelName: 'Weather Alerts',
    );
  }
}

Map<String, String> notificationcontent(
  String payload,
  AppLocalizations local,
) {
  switch (payload) {
    case "balance":
      return {
        'title': local.title_challenge_balance,
        'body': local.body_challenge_balance,
        'alert': local.alert_challenge_balance,
      };
    case "hi":
      return {
        'title': local.title_challenge_hi,
        'body': local.body_challenge_hi,
        'alert': local.alert_challenge_hi,
      };
    case "mini_orientiring":
      return {
        'title': local.title_challenge_mini_orientiring,
        'body': local.body_challenge_mini_orientiring,
        'alert': local.alert_challenge_mini_orientiring,
      };
    case "photo":
      return {
        'title': local.title_challenge_photo,
        'body': local.body_challenge_photo,
        'alert': local.alert_challenge_photo,
      };
    case "silent_walking":
      return {
        'title': local.title_challenge_silent_walking,
        'body': local.body_challenge_silent_walking,
        'alert': local.alert_challenge_silent_walking,
      };
    case "time":
      return {
        'title': local.title_challenge_time,
        'body': local.body_challenge_time,
        'alert': local.alert_challenge_time,
      };
    case "end_trekking_arrival":
      return {
        'title': local.title_notification_arrival,
        'body': local.body_notification_arrival,
        'alert': local.alert_notification_arrival,
      };
    case "weather_alert":
      return {
        'title': "Weather alert",
        'body': "A weather alert has been detected for one of your selected trekkings.",
        'alert': "A weather alert has been detected for one of your selected trekkings.",
      };
    default:
      return {'title': "", 'body': ""};
  }
}
