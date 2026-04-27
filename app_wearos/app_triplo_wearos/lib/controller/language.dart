import 'package:flutter/material.dart';
import '../service/OSservice/memory.dart';

// Language controller for localization --> manage app language
class Language extends ChangeNotifier {
  // Current locale, default to English
  Locale _locale = const Locale('en');

  final MemoryService _memoryService;

  // Getter for current locale
  Locale get locale => _locale;

  Language({MemoryService? memoryService})
      : _memoryService = memoryService ?? MemoryService();

  // Set a new locale and notify listeners
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    await _memoryService.saveLocale(locale.languageCode);
    notifyListeners();
  }

  // Carica la lingua salvata nel MemoryService
  Future<void> loadSavedLocale() async {
    final code = await _memoryService.getLocale();

    if (code == null || code.isEmpty) return;

    final loaded = Locale(code);
    if (_locale == loaded) return;

    _locale = loaded;
    notifyListeners();
  }
}