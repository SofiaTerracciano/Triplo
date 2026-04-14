import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  static const routeName = "/offline";

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Aggiungi questo
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              
              children: [
                Image.asset(
                  'images/offline_mode.png',
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  local.offline_mode_label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  local.no_internet,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/navigation');
                  },
                  icon: const Icon(Icons.explore),
                  label: Text(local.navigation_page_title),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}