import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../controller/servicecontroller.dart';
import '../controller/trekking.dart';
import 'OSservice/memory.dart';
import 'OSservice/notification.dart';

class BackgroundService with WidgetsBindingObserver {
  final BuildContext context;
  Timer? _timer;
  bool _running = false;

  BackgroundService(this.context);

  void start() {
    try {
      WidgetsBinding.instance.addObserver(this);
      debugPrint("BackgroundService started");

      unawaited(_run());

      _timer = Timer.periodic(
        const Duration(seconds: 60),
            (_) {
          unawaited(_run());
        },
      );
    } catch (e, st) {
      debugPrint("BackgroundService start error: $e");
      debugPrint("$st");
    }
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    try {
      debugPrint("BackgroundService running check");

      final trekkingController = context.read<TrekkingController>();
      final api = context.read<ServiceController>();
      final notification = context.read<NotificationService>();
      final memory = context.read<MemoryService>();

      await BackgroundServiceLogic.run(
        trekkingController: trekkingController,
        api: api,
        notification: notification,
        memory: memory,
      );
    } catch (e) {
      debugPrint("BackgroundService error: $e");
    } finally {
      _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_run());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}

class BackgroundServiceLogic {
  static Future<void> run({
    required TrekkingController trekkingController,
    required ServiceController api,
    required NotificationService notification,
    required MemoryService memory,
  }) async {
    debugPrint("BackgroundServiceLogic running");
    if (trekkingController.uid == null) {
      debugPrint("BackgroundService skipped: pairing uid not ready");
      return;
    }

    final trekkings = await trekkingController.getWeatherAlertTrekkings();
    debugPrint("Subscribed trekkings: ${trekkings.length}");

    for (final trekking in trekkings) {
      final target = trekking.starting_point ?? trekking.ending_point;
      if (target == null) continue;

      List<Map<String, dynamic>> real = [];
      List<Map<String, dynamic>> mock = [];

      try {
        real = await api.weatherbitAlerts(
          target.latitude,
          target.longitude,
        );
      } catch (e) {
        debugPrint("Real alerts error for ${trekking.name}: $e");
      }

      try {
        mock = await api.mockAlerts();
      } catch (e) {
        debugPrint("Mock alerts error for ${trekking.name}: $e");
      }

      final alerts = [...real, ...mock];
      debugPrint("Alerts found for ${trekking.name}: ${alerts.length}");

      for (final alert in alerts) {
        final alertKey = _buildAlertKey(trekking.documentId, alert);

        final alreadyShown = await memory.hasShownWeatherAlertKey(alertKey);
        if (alreadyShown) {
          debugPrint("Skipping duplicate alert: $alertKey");
          continue;
        }

        final title =
        (alert['event'] ?? alert['title'] ?? 'Weather alert').toString();

        final body = 'Alert for ${trekking.name}';

        await notification.showWeatherNotification(
          id: alertKey.hashCode,
          title: title,
          body: body,
        );

        await memory.addShownWeatherAlertKey(alertKey);
        debugPrint("Notification shown for ${trekking.name}: $alertKey");
      }
    }
  }

  static String _buildAlertKey(String trekkingId, Map<String, dynamic> alert) {
    final event = (alert['event'] ?? '').toString();
    final headline = (alert['headline'] ?? '').toString();
    final start = (alert['start'] ?? '').toString();
    final end = (alert['end'] ?? '').toString();

    return '$trekkingId|$event|$headline|$start|$end';
  }
}