import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/SettingsPage/setting-page.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';


/**
 * Registration page for creating a new Triplo profile, handles UI and validation.
 */
class RegistrationPage extends StatefulWidget {

  const RegistrationPage({
    super.key,
  });

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /** Validates the fields and delegates registration to the controller for the user.*/
  Future<void> _register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final local = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.fill_all_fields)),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.passwords_not_match)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userController = context.read<UserController>();

    try {
      await userController.register(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.registration_success)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SettingPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${local.registration_failed} $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /** UI for the Registration Page */
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      key: const Key('registrationPage'),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  local.registration_title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 24),

                BoxField(
                  key: const Key('registrationEmailField'),
                  label: local.email_label,
                  isEmail: true,
                  controller: emailController,
                ),

                const SizedBox(height: 16),

                BoxField(
                  key: const Key('registrationPasswordField'),
                  label: local.password_label,
                  isPassword: true,
                  controller: passwordController,
                ),

                const SizedBox(height: 16),

                BoxField(
                  key: const Key('registrationConfirmPasswordField'),
                  label: local.confirm_password_label,
                  isPassword: true,
                  controller: confirmPasswordController,
                ),

                const SizedBox(height: 30),




                Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton(
                        key: const Key('registrationButton'),
                      onPressed: _isLoading ? null : () => _register(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(local.register_button, style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Back to login button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    local.back_to_login,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
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
