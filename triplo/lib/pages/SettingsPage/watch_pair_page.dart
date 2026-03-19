
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';

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
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(local.scan_qr_label)),
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
                setState(() => _error = "${local.not_valid_qr_label}: $e");
                _handled = false;
                return;
              }

              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(local.connect_watch_label),
                  content: Text("WatchId:\n$watchId"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(local.cancel_button_label),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(local.confirm_label),
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