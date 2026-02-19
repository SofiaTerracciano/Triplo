import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/service/notification.dart';

class ObserverService {
  final API api;
  final NotificationService notificationService;

  Timer? _timer;

  ObserverService({
    required this.api,
    required this.notificationService,
  });

  void start(LatLng position) {
    _timer = Timer.periodic(
      const Duration(minutes: 15),
          (_) => check(position),
    );
  }

  Future<void> check(LatLng pos) async {
    final alerts =
    await api.weatherbitAlerts(pos.latitude, pos.longitude);

    if (alerts.isNotEmpty) {
      final first = alerts.first;

      notificationService.showAlertNotification(
        first["event"] ?? "Weather alert",
        first["description"] ?? "",
      );
    }
  }

  void stop() {
    _timer?.cancel();
  }
}
