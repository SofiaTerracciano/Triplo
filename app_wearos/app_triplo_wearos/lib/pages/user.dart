import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();

    // Usa effectiveUid invece di currentUser
    final uid = userCtrl.effectiveUid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder(
      future: userCtrl.getUserById(uid),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.username),
                const SizedBox(height: 6),
                Text(user.level),
              ],
            ),
          ),
        );
      },
    );
  }
}