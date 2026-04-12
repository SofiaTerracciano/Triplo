import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'HomePage/home-page.dart';
import 'UserProfilePage/user.dart';
import '../service/pairing_service.dart';
import '../widgets_for_pages/Navigation_Button.dart';
import '../controller/language.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    //final ctrl = context.watch<UserController>();
    final languageController = context.watch<Language>();
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // Usiamo SingleChildScrollView per sicurezza, così se non ci sta puoi scrollare
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Triplo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13, // Leggermente più piccolo
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8), // Ridotto da 14
                // ROW PRINCIPALE: HOME E USER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NavigationButton(
                      icon: Icons.home,
                      label: local.home_label,
                      color: const Color(0xFF2F80ED),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HomePage()),
                        );
                      },
                    ),
                    const SizedBox(width: 10), // Ridotto da 14
                    NavigationButton(
                      icon: Icons.person,
                      label: local.user_label,
                      color: const Color(0xFF27AE60),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PairingGateway(child: const UserPage()),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 4), // Spazio minimo
                // BOTTONE LINGUA PICCOLO
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => LanguageDialog(
                        onLocaleSelected: (locale) async {
                          languageController.setLocale(locale);
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), // Aumentiamo l'area di tocco interna
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language,
                          size: 18,
                          color: Colors.orange.withOpacity(0.8),
                        ),
                        Text(
                          local.language_label,
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Popup dialog to select the language
class LanguageDialog extends StatelessWidget {
  final Future<void> Function(Locale) onLocaleSelected;

  const LanguageDialog({super.key, required this.onLocaleSelected});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.black, // Sfondo nero come il resto dell'app
      insetPadding: EdgeInsets.zero, // Occupa tutto lo spazio disponibile
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 20), // Spazio per la curvatura superiore
            Text(
              local.language_label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _langTile(context, "🇬🇧", "English", const Locale('en')),
                    _langTile(context, "🇮🇹", "Italiano", const Locale('it')),
                    _langTile(context, "🇪🇸", "Español", const Locale('es')),
                    _langTile(context, "🇩🇪", "Deutsch", const Locale('de')),
                    _langTile(context, "🇫🇷", "Français", const Locale('fr')),
                    const SizedBox(height: 20), // Spazio per la curvatura inferiore
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langTile(BuildContext context, String flag, String name, Locale locale) {
    return InkWell(
      onTap: () async {
        await onLocaleSelected(locale);
        Navigator.pop(context);
      },
      child: Padding(
        // Padding generoso per facilitare il tocco
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
