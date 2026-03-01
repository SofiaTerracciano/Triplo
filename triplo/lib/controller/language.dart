import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Language extends ChangeNotifier {
  static const _kLocaleCodeKey = "locale_code";

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // Carica la lingua salvata (da chiamare all'avvio)
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleCodeKey);

    if (code == null || code.isEmpty) return;

    final loaded = Locale(code);
    if (_locale == loaded) return;

    _locale = loaded;
    notifyListeners();
  }

  // Imposta e salva
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCodeKey, locale.languageCode);
  }
}