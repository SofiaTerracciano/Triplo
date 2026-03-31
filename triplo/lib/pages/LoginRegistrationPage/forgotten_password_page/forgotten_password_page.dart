import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
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
    final local = AppLocalizations.of(context)!;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.email_required)),
      );
      return;
    }

    final controller = Provider.of<UserController>(context, listen: false);

    try {
      /// Delegates the Firebase call to the UserController
      await controller.sendPasswordReset(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.reset_link_sent),
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
    final local = AppLocalizations.of(context)!;

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
                  Text(
                    local.forgot_password_title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "${local.forgot_password_subtitle} \n ${local.enter_email_prompt}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  BoxField(
                      label: local.email_label,
                    isEmail: true,
                    controller: emailController,),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      local.send_reset_link_button,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      local.go_to_login_button,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
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