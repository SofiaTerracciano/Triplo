import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../controller/servicecontroller.dart';

class InternetService extends ChangeNotifier with WidgetsBindingObserver {
  final ServiceController servicecontroller;
  final Duration checkEvery;
  final Duration offlineThreshold;
  final Duration resumeGracePeriod;

  InternetService({
    required this.servicecontroller,
    this.checkEvery = const Duration(seconds: 3),
    this.offlineThreshold = const Duration(seconds: 6),
    this.resumeGracePeriod = const Duration(seconds: 4),
  });

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Timer? _pollTimer;
  Timer? _offlineTimer;
  Timer? _resumeTimer;
  bool _started = false;
  bool _checking = false;
  bool _isForeground = true;
  bool _resumeWaiting = false;

  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(checkEvery, (_) => _tick());

    _tick();
  }

  Future<void> _tick() async {
    if (!_started) return;
    if (!_isForeground) return;
    if (_resumeWaiting) return;
    if (_checking) return;

    _checking = true;

    try {
      final ok = await servicecontroller.hasInternet();

      if (ok) {
        _offlineTimer?.cancel();
        _setOnline(true);
        return;
      }

      if (_offlineTimer?.isActive == true) return;

      _offlineTimer = Timer(offlineThreshold, () async {
        if (!_started || !_isForeground || _resumeWaiting) return;

        final stillOk = await servicecontroller.hasInternet();
        if (!stillOk) {
          _setOnline(false);
        } else {
          _setOnline(true);
        }
      });
    } finally {
      _checking = false;
    }
  }

  void forceRecheck() {
    _offlineTimer?.cancel();
    _resumeTimer?.cancel();
    _tick();
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;

    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      _resumeWaiting = true;

      _offlineTimer?.cancel();
      _resumeTimer?.cancel();

      _resumeTimer = Timer(resumeGracePeriod, () {
        _resumeWaiting = false;
        _tick();
      });
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
      _offlineTimer?.cancel();
      _resumeTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _offlineTimer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }
}