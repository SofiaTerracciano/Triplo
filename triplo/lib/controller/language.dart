import 'package:flutter/material.dart';
import '../service/memory.dart';

/// Controller responsible for managing the application's locale and language settings.
/// It handles language switching and delegates persistence to [MemoryService].
class Language extends ChangeNotifier {
  final MemoryService memoryService;

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Language({required this.memoryService});

  /// Loads the saved locale from local storage.
  Future<void> loadSavedLocale() async {
    final code = await memoryService.getSavedLocaleCode();

    if (code == null || code.isEmpty) return;

    final loaded = Locale(code);

    if (_locale == loaded) return;

    _locale = loaded;
    notifyListeners();
  }

  /// Updates the application's locale and saves it permanently.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    await memoryService.saveLocaleCode(locale.languageCode);
  }
}