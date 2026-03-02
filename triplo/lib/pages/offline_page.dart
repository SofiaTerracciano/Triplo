import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  static const routeName = "/offline";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              const Text(
                "Offline mode",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "No internet connection. ",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}