import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/internetservice.dart';
import 'navigation.dart';

class OfflineWatchPage extends StatelessWidget {
  const OfflineWatchPage({super.key});
  @override
  Widget build(BuildContext context) {
    final internet = context.read<InternetService>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(height: 10),
              const Text(
                "Offline mode",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Internet connection is not currently available.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: internet.forceRecheck,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
