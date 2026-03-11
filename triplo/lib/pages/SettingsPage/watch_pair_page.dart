
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../controller/user.dart';

class WatchPairScannerPage extends StatefulWidget {
  const WatchPairScannerPage({super.key});

  @override
  State<WatchPairScannerPage> createState() => _WatchPairScannerPageState();
}

class _WatchPairScannerPageState extends State<WatchPairScannerPage> {
  bool _handled = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan watch QR")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_handled) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;

              _handled = true;

              late final String watchId;
              late final String token;

              try {
                final pair = context.read<UserController>().extractWatchPair(raw);
                watchId = pair.watchId;
                token = pair.token;
              } catch (e) {
                if (!mounted) return;
                setState(() => _error = "QR non valido: $e");
                _handled = false;
                return;
              }

              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Connettere l'orologio?"),
                  content: Text("WatchId:\n$watchId"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Annulla"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Approva"),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                try {
                  await context.read<UserController>().approveWatchPair(
                    watchId: watchId,
                    token: token,
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _error = "Errore approvazione: $e");
                  _handled = false; // consenti nuovo scan
                }
              } else {
                _handled = false; // consenti nuovo scan
              }
            },
          ),

          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}