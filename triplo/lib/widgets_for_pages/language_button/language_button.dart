import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';

class LanguageButton extends StatelessWidget {
  final Future<void> Function(Locale) onLocaleSelected;

  const LanguageButton({super.key, required this.onLocaleSelected});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(local.language_selection_label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTile(context, "🇬🇧", "English", const Locale('en')),
          _langTile(context, "🇮🇹", "Italiano", const Locale('it')),
          _langTile(context, "🇪🇸", "Español", const Locale('es')),
          _langTile(context, "🇩🇪", "Deutsch", const Locale('de')),
          _langTile(context, "🇫🇷", "Français", const Locale('fr')),
        ],
      ),
    );
  }

  Widget _langTile(
      BuildContext context,
      String flag,
      String name,
      Locale locale,
      ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      onTap: () async {
        await onLocaleSelected(locale);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}