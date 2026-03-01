import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';
import '../pages/login.dart';

class PairingService extends StatefulWidget {
  final Widget child;
  const PairingService({super.key, required this.child});

  @override
  State<PairingService> createState() => _PairingServiceState();
}

class _PairingServiceState extends State<PairingService> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();

    // avvio una volta sola, dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<UserController>();

      // evita doppio avvio se per qualche motivo initState viene rieseguito (hot reload ecc.)
      if (_bootstrapped) return;
      _bootstrapped = true;

      try {
        final alreadyPaired = await ctrl.restoreWatchPairing();
        if (!mounted) return;

        if (!alreadyPaired) {
          await ctrl.startWatchPairing(forceNew: true);
        }
      } catch (_) {
        // opzionale: gestisci/logga se vuoi
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, ctrl, _) {
        final uid = ctrl.effectiveUid;

        // se non paired => pagina QR
        if (uid == null) return const LoginPage();

        // paired => pagina richiesta
        return widget.child;
      },
    );
  }
}