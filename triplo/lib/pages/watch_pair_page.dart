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

  String _extractPairId(String raw) {
    // supporta sia "pairId" puro sia "triplo://watch-pair/<id>"
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == "triplo") {
      // triplo://watch-pair/<pairId>
      if (uri.host == "watch-pair") {
        final seg = uri.pathSegments;
        if (seg.isNotEmpty) return seg.first;
      }
    }
    return raw.trim();
  }

  Future<void> _approvePair(String pairId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = "Devi essere loggato sul telefono.");
      return;
    }

    final ref = FirebaseFirestore.instance.collection('watch_pair').doc(pairId);

    final snap = await ref.get();
    if (!snap.exists) {
      setState(() => _error = "PairId non trovato: $pairId");
      return;
    }

    final data = snap.data() as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status != 'waiting') {
      setState(() => _error = "Questo QR non è in stato waiting (status=$status).");
      return;
    }

    await ref.update({
      'status': 'approved',
      'uid': user.uid,
      'approvedAt': FieldValue.serverTimestamp(),
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
              final pairId = _extractPairId(raw);

              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Connettere l'orologio?"),
                  content: Text("PairId:\n$pairId"),
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
                  await _approvePair(pairId);
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