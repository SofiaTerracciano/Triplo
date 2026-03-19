import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language controller for localization --> manage app language
class Language extends ChangeNotifier {
  // Current locale, default to English
  Locale _locale = const Locale('en');

  // Getter for current locale
  Locale get locale => _locale;

  Language();

  static const String _kLocaleCodeKey = "locale_code";

  // Set a new locale and notify listeners
  void setLocale(Locale locale) {
    if (_locale == locale) 
      return;
    
    _locale = locale;

    notifyListeners();
  }

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
}