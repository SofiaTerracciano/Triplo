import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/service/notification.dart';

class BackgroundService with WidgetsBindingObserver {
  final BuildContext context;

  Timer? _timer;
  bool _running = false;

  final Set<String> _shownAlertKeys = {};

  BackgroundService(this.context);

  void start() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint("BackgroundService started");

    _run();

    _timer = Timer.periodic(
      const Duration(minutes: 12),
          (_) => _run(),
    );
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    try {
      debugPrint("BackgroundService running check");

      final trekkingController = context.read<TrekkingController>();
      final api = context.read<API>();
      final notification = context.read<NotificationService>();

      final trekkings = await trekkingController.getWeatherAlertTrekkings();
      debugPrint("Subscribed trekkings: ${trekkings.length}");


      for (final trekking in trekkings) {
        debugPrint("Checking trekking: ${trekking.name} (${trekking.documentId})");

        final target = trekking.starting_point ?? trekking.ending_point;
        if (target == null) continue;

        final real = await api.weatherbitAlerts(
          target.latitude,
          target.longitude,
        );

        final mock = await api.mockAlerts();

        final alerts = [...real, ...mock];
        debugPrint("Alerts found for ${trekking.name}: ${alerts.length}");

        for (final alert in alerts) {
          final alertKey = _buildAlertKey(trekking.documentId, alert);

          if (_shownAlertKeys.contains(alertKey)) {
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

          _shownAlertKeys.add(alertKey);
          debugPrint("Notification shown for ${trekking.name}: $alertKey");
        }
      }
    } catch (e) {
      debugPrint("BackgroundService error: $e");
    } finally {
      _running = false;
    }
  }

  String _buildAlertKey(String trekkingId, Map<String, dynamic> alert) {
    final event = (alert['event'] ?? '').toString();
    final headline = (alert['headline'] ?? '').toString();
    final start = (alert['start'] ?? '').toString();
    final end = (alert['end'] ?? '').toString();

    return '$trekkingId|$event|$headline|$start|$end';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}