import 'package:flutter/material.dart';


import '../service/OSservice.dart';

class Language extends ChangeNotifier {


  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  final OSService os;


  Language({required this.os});



  Future<void> loadSavedLocale() async {
    final code = await os.loadLocaleCode();

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

    await os.saveLocaleCode(locale.languageCode);
  }
}