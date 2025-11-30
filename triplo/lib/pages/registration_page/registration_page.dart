import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';

import '../user-page.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';


/**
 * Registration page for creating a new Triplo profile, handles UI and validation.
 */
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<StatefulWidget> createState() => _RegistrationPageState();
}






/**
 * Handles the registration by:
 * 1. Validating the fields
 * 2. Delegating the actual registration to UserController.register()
 * 3. Navigating the user after successful registration
 */
class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
 TextEditingController();

  bool _isLoading = false;



  /** Validates the fields and delegates registration to the controller for the user.*/
  Future<void> _register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in every field")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final controller = Provider.of<UserController>(context, listen: false);

    try {
      await controller.register(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserPage(onLocaleChanged: (l) {})),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /** UI for the Registration Page */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Register on the Triplo application',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 24),

                BoxField(
                  label: 'email',
                  isEmail: true,
                  controller: emailController,
                ),

                const SizedBox(height: 16),

                BoxField(
                  label: 'password',
                  isPassword: true,
                  controller: passwordController,
                ),

                const SizedBox(height: 16),

                BoxField(
                  label: 'confirm password',
                  isPassword: true,
                  controller: confirmPasswordController,
                ),

                const SizedBox(height: 30),




                Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _register(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text("Register", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Back to login button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Go back to login page',
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
