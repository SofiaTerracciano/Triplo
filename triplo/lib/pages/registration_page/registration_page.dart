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

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<StatefulWidget> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

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
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();
                              final confirmPassword = confirmPasswordController
                                  .text
                                  .trim();
                              if (email.isEmpty ||
                                  password.isEmpty ||
                                  confirmPassword.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in every field'),
                                  ),
                                );
                                return;
                              }

                              if (password != confirmPassword) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Passwords do not match'),
                                  ),
                                );
                                return;
                              }
                              setState(() => _isLoading = true);

                              try {
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: email,
                                      password: password,
                                    );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration successful'),
                                  ),
                                );

                                //Navigator.pushReplacementNamed(context '/home');
                              } on FirebaseAuthException catch (e) {
                                String message;
                                switch (e.code) {
                                  case 'weak-password':
                                    message = 'Password is too weak';
                                    break;

                                  case 'email-already-in-use':
                                    message =
                                        'This email is already registered';
                                    break;

                                  case 'invalid email':
                                    message = 'Invalid email';
                                    break;

                                  default:
                                    message =
                                        'Registration failed : ${e.message}';
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Register',

                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
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
