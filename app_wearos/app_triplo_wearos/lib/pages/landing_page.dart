import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:flutter/material.dart';
import 'home-page.dart';
import 'login.dart';
import 'user.dart';

// Ma a cosa la usiamo sta pagina?
class DebugLandingPage extends StatelessWidget {
  const DebugLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [

            const Text(
              "DEBUG MENU",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>  HomePage()),
                );
              },
              child: const Text("Home Page"),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>  LoginPage()),
                );
              },
              child: const Text("Login Page"),
            ),

            const SizedBox(height: 8),



            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PairingService(child: UserPage())),
                );
              },
              child: const Text("User Page"),
            ),

          ],
        ),
      ),
    );
  }
}