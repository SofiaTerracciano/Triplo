import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/service/notification.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/geo.dart';
import 'package:triplo/service/permission.dart';
import 'package:triplo/firebase_options.dart';

const String weatherCheckTask = 'weatherCheckTask';

class BackgroundService with WidgetsBindingObserver {
  final BuildContext context;
  Timer? _timer;
  bool _running = false;

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
      _run();
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
    required API api,
    required NotificationService notification,
    required MemoryService memory,
  }) async {
    debugPrint("BackgroundServiceLogic running");

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
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != weatherCheckTask) {
      return Future.value(true);
    }
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final memory = MemoryService();
      final geo = GeoService();
      final permission = PermissionService();

      final api = API(
        geo: geo,
        memory: memory,
        permission: permission,
      );

      final notification = NotificationService();
      await notification.init();

      final trekkingController = TrekkingController(
        memory: memory,
        notification: notification,
        trekkings: [],
      );

      await BackgroundServiceLogic.run(
        trekkingController: trekkingController,
        api: api,
        notification: notification,
        memory: memory,
      );
    } catch (e) {
      debugPrint("Workmanager background error: $e");
    }

    return Future.value(true);
  });
}