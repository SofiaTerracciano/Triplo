import 'package:flutter/material.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';

/// Page used to request a password reset link.
/// This page only handles input validation and UI.
class ForgottenPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgottenPasswordPage({super.key});
  /// Validates the email and calls the controller method.
  Future<void> _submit(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }

    final controller = Provider.of<UserController>(context, listen: false);

    try {
      /// Delegates the Firebase call to the UserController
      await controller.sendPasswordReset(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent! Check your email."),
        ),
      );

      Navigator.pop(context); // go back to login
    } catch (e) {
      String message = "Error: $e";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }





  /** UI for the Forgotten Password Page */
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
                    onPressed: () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Send reset link",
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