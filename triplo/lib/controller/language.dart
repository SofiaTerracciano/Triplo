import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa questo

class Language extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // Rimuoviamo il parametro os dal costruttore
  Language();

  static const String _kLocaleCodeKey = "locale_code";

  // Carica la lingua salvata nelle SharedPreferences
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleCodeKey);

    if (code == null || code.isEmpty) return;

    final loaded = Locale(code);
    if (_locale == loaded) return;

    _locale = loaded;
    notifyListeners();
  }

  // Imposta la nuova lingua e la salva permanentemente
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Salva il codice lingua (es: 'it', 'en') sul disco
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCodeKey, locale.languageCode);
  }
}