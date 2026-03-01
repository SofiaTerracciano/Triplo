import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/user.dart';
import '../pages/home-page.dart';
import '../pages/user.dart';
import '../service/pairing_service.dart';
import '../widgets_for_pages/Navigation_Button.dart';
class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {

    final ctrl = context.watch<UserController>();
    final isPaired = ctrl.effectiveUid != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titolo piccolo (puoi rimuoverlo se vuoi super minimal)
                Text(
                  "Triplo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NavigationButton(
                      icon: Icons.home,
                      label: "Home",
                      color: const Color(0xFF2F80ED), // blu
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage()
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    NavigationButton(
                      icon: Icons.person,
                      label: "User",
                      color: const Color(0xFF27AE60), // verde
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PairingService(child: const UserPage()),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /*
                _RoundNavButton(
                  icon: Icons.star,
                  label: "Soon",
                  color: const Color(0xFFF2994A),
                  onTap: null,
                ),
                 */
              ],
            ),
          ),
        ),
      ),
    );
  }
}

