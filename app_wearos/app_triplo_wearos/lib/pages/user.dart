import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final user = userCtrl.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
  }
}