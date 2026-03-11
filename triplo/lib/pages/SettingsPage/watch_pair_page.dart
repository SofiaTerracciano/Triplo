import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WatchPairScannerPage extends StatefulWidget {
  const WatchPairScannerPage({super.key});

  @override
  State<WatchPairScannerPage> createState() => _WatchPairScannerPageState();
}

class _WatchPairScannerPageState extends State<WatchPairScannerPage> {
  bool _handled = false;
  String? _error;


  ({String watchId, String token}) _extractPair(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != "triplo" || uri.host != "watch-pair") {
      throw const FormatException("QR non valido");
    }

    final seg = uri.pathSegments;
    if (seg.isEmpty) throw const FormatException("watchId mancante");

    final watchId = seg.first.trim();
    if (watchId.isEmpty) throw const FormatException("watchId mancante");

    final token = uri.queryParameters['t']?.trim();
    if (token == null || token.isEmpty) {
      throw const FormatException("token mancante");
    }

    return (watchId: watchId, token: token);
  }

  Future<void> _approvePair({
    required String watchId,
    required String token,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = "Devi essere loggato sul telefono.");
      return;
    }

    final ref = FirebaseFirestore.instance.collection('watch_pair').doc(watchId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception("watch_pair non trovato (watchId=$watchId)");
      }

      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final qrToken = data['qrToken'] as String?;
      final expiresAt = data['expiresAt'] as Timestamp?;

      if (status != 'waiting') {
        throw Exception("QR non in waiting (status=$status)");
      }
      if (qrToken != token) {
        throw Exception("Token non valido / QR rigenerato");
      }
      if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception("QR scaduto");
      }

      // Coerente con le rules: aggiorna SOLO status e uid
      tx.update(ref, {
        'status': 'approved',
        'uid': user.uid,
      });
    });

    if (!mounted) return;
    Navigator.pop(context, true); // pairing completato
  }

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
                final pair = _extractPair(raw);
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
                  await _approvePair(watchId: watchId, token: token);
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