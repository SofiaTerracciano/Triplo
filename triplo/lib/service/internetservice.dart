import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:triplo/controller/API.dart';



class InternetService extends ChangeNotifier {
  final API api;
  final Duration checkEvery;
  final Duration offlineThreshold;

  InternetService({
    required this.api,
    this.checkEvery = const Duration(seconds: 3),
    this.offlineThreshold = const Duration(seconds: 6),
  });

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _pollTimer;
  Timer? _offlineTimer;

  void start() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(checkEvery, (_) => _tick());
    _tick(); // check immediato
  }

  Future<void> _tick() async {
    final ok = await api.hasInternet();

    if (ok) {
      _offlineTimer?.cancel();
      _setOnline(true);
      return;
    }

    // se cade, aspetta offlineThreshold prima di segnare offline
    if (_offlineTimer?.isActive == true) return;

    _offlineTimer = Timer(offlineThreshold, () async {
      final stillOk = await api.hasInternet();
      if (!stillOk) _setOnline(false);
    });
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _offlineTimer?.cancel();
    super.dispose();
  }
}