import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controller/user.dart';
import 'user.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    if (userController.pairedUid != null || userController.currentUser != null) {
      return const UserPage();
    }

    final payload = userController.qrPayload;
    final creating = userController.pairing;
    final error = userController.pairingError;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Connetti",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (creating) ...[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (error != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (payload != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 110,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(
                          width: 160,
                          child: Text(
                            "Scansiona con il telefono",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Generazione QR…",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 12),

                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: creating
                              ? null
                              : () => context
                              .read<UserController>()
                              .startWatchPairing(forceNew: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text("New QR"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}