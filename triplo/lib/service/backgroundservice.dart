import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/API.dart';

class BackgroundService with WidgetsBindingObserver {
  final BuildContext context;

  Timer? _timer;
  bool _running = false;

  BackgroundService(this.context);
  void start() {
    debugPrint("BackgroundService started");
    WidgetsBinding.instance.addObserver(this);

    // primo check
    _run();

    // check periodico
    _timer = Timer.periodic(
      const Duration(minutes: 2),
          (_) => _run(),
    );
  }



  Future<void> _run() async {
    debugPrint("BackgroundService running check");
    if (_running) return;
    _running = true;

    try {
      final trekkingController = context.read<TrekkingController>();
      final api = context.read<API>();

      await trekkingController.checkSubscribedWeatherAlerts(api);
    } catch (e) {
      // opzionale debug
      // debugPrint("BackgroundService error: $e");
    } finally {
      _running = false;
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run(); // check immediato quando torni nell’app
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}