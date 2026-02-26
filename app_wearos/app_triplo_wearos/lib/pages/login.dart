import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controller/user.dart';
import 'user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserController>().startWatchPairing();
    });
  }

  @override
  void dispose() {
    // chiude listener/timer nel controller
    context.read<UserController>().stopWatchPairing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    if (userController.currentUser != null || userController.pairedUid != null) {
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
                  const SizedBox(height: 10),

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
                      data: pairId, // oppure "triplo://watch-pair/$pairId"
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
                        : () => context
                        .read<UserController>()
                        .startWatchPairing(forceNew: true),
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