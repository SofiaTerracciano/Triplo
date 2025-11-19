import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';

class ForgottenPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgottenPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(

              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Forgot your password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter your email below and we’ll send you a link to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  BoxField(
                      label: 'email',
                    isEmail: true,
                    controller: emailController,),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();

                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email address'),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password reset link sent! Check your email.',
                            ),
                          ),
                        );
                        Navigator.pop(context); // Torna al login
                      } on FirebaseAuthException catch (e) {
                        String message;
                        switch (e.code) {
                          case 'user-not-found':
                            message = 'No user found with this email.';
                            break;
                          case 'invalid-email':
                            message = 'Invalid email address.';
                            break;
                          default:
                            message = 'Error: ${e.message}';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Send reset link',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                    ),
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