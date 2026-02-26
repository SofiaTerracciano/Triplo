import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../controller/user.dart';
import 'user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String? _pairId;
  bool _creating = false;
  String? _error;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserController>().startWatchPairing();
    });
  }


  @override
  void dispose() {
    context.read<UserController>().stopWatchPairing();
    super.dispose();
  }

  Future<void> _startPairing() async {
    if (_creating) return;

    setState(() {
      _creating = true;
      _error = null;
    });

    // pulisci listener vecchio
    await _sub?.cancel();
    _sub = null;

    final pairId = _uuid.v4();
    setState(() => _pairId = pairId);

    try {
      await _db.collection('watch_pair').doc(pairId).set({
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'wearos',
      });

      // ascolta approvazione da telefono
      _sub = _db.collection('watch_pair').doc(pairId).snapshots().listen(
            (doc) async {
          final data = doc.data();
          if (data == null) return;

          final status = data['status'] as String?;
          final token = data['customToken'] as String?;

          if (status == 'approved' && token != null && token.isNotEmpty) {
            // fai login nel tuo UserController (aggiungeremo sotto la funzione)
            final userController = context.read<UserController>();
            await userController.loginWithCustomToken(token);
            // quando currentUser diventa != null, build() ti porterà su UserPage
          }

          if (status == 'expired') {
            if (!mounted) return;
            setState(() => _error = "QR scaduto, rigenera.");
          }
        },
      );
    } catch (e) {
      setState(() => _error = "Errore pairing: $e");
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    if (userController.currentUser != null) {
      return UserPage();
    }

    final pairId = userController.pairId;
    final creating = userController.pairing;
    final error = userController.pairingError;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Login"),


                  if (creating) const CircularProgressIndicator(),

                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if (pairId != null) ...[
                    const SizedBox(height: 10),
                    QrImageView(
                      data: pairId,
                      version: QrVersions.auto,
                      size: 120,
                    ),
                    const SizedBox(height: 10),

                    // FIX overflow
                    SizedBox(
                      width: 160,
                      child: Text(
                        pairId,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: creating
                        ? null
                        : () => context.read<UserController>().startWatchPairing(),
                    child: const Text("Rigenera QR"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}