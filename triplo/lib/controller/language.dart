import 'package:flutter/material.dart';

// Language controller for localization --> manage app language
class Language extends ChangeNotifier {
  // Current locale, default to English
  Locale _locale = const Locale('en');

  // Getter for current locale
  Locale get locale => _locale;

  // Set a new locale and notify listeners
  void setLocale(Locale locale) {
    if (_locale == locale) 
      return;
    
    _locale = locale;

    notifyListeners();
  }
}