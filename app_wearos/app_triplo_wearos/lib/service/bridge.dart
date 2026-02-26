/*
import 'dart:convert';
import 'package:flutter/services.dart';

class WatchBridge {
  static const _ch = MethodChannel('triplo/wear');

  // invia richiesta al telefono (dal watch) o al watch (dal phone)
  static Future<void> send(String path, Map<String, dynamic> data) async {
    await _ch.invokeMethod('sendMessage', {
      'path': path,
      'data': jsonEncode(data),
    });
  }

  // stream di messaggi in arrivo
  static const _event = EventChannel('triplo/wear_events');

  static Stream<Map<String, dynamic>> messages() async* {
    await for (final e in _event.receiveBroadcastStream()) {
      final map = Map<String, dynamic>.from(e as Map);
      final data = jsonDecode(map['data'] as String) as Map<String, dynamic>;
      yield {
        'path': map['path'],
        'data': data,
      };
    }
  }
}

 */