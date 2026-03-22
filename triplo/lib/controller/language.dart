import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller responsible for managing the application's locale and language settings.
/// It handles language switching and ensures the selected language persists across app restarts.
class Language extends ChangeNotifier {
  Locale _locale = const Locale('en');

  /// Returns the current [Locale] of the application.
  Locale get locale => _locale;

  Language();

  /// Key used for storing the language code in the device's local storage.
  static const String _kLocaleCodeKey = "locale_code";

  /// Loads the saved locale from [SharedPreferences] (local disk). 
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleCodeKey);

    // If no language is saved, we stick with the default
    if (code == null || code.isEmpty) return;

    final loaded = Locale(code);
    // Avoid unnecessary UI rebuilds if the locale hasn't changed
    if (_locale == loaded) return;

    _locale = loaded;
    notifyListeners();
  }

  /// Updates the application's [Locale] and saves it permanently to the disk.
  /// [locale] The new locale to apply (e.g., Locale('it') or Locale('en')).
  /// Notifies all listening widgets to rebuild with the new language.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Persist the language code (e.g., 'it', 'en') to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCodeKey, locale.languageCode);
  }
}