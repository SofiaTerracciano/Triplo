import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'package:triplo/widgets_for_pages/box_field/box_field.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/widgets_for_pages/language_button/language_button.dart';
import '../../../controller/language.dart';

import '../../UserProfilePage/user-page.dart';

import 'package:provider/provider.dart';

import 'package:triplo/controller/diary.dart';

/**
 * Login Page for the Triplo App.
 * Email+password login + Google sign-in.
 */
class LoginPage extends StatefulWidget {

  const LoginPage({
    super.key,});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /**
   * Attempts login using the provided email and password.
   * 1. Validate fields.
   * 2. Call UserController.login().
   * 3. Navigate to the UserPage on success.
   * 4. Show error messages using SnackBars.
   */
  Future<void> _loginEmailPwd(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final local = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.fill_fields_label)),
      );
      return;
    }

    final userController = context.read<UserController>();
    final diaryController = context.read<DiaryController>();
    //final trekkingController = context.read<TrekkingController>();
    try {
      await userController.login(email, password);
      //final uid = controller.currentUser!.uid;
      final user = userController.currentUser;
      if (user == null) {
        throw StateError("currentUser è null dopo il login");
      }
      //final uid = user.uid;
      //assign current user instance to _currentUser attribute of diaryController
      diaryController.currentUser = user;



      //await diaryController.loadPublicDiary(uid);
      //await diaryController.loadPrivateDiary(uid);
      /*
      trekkingController.loadTrekking().then((_) {
        setState(() {});
      });

       */

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserPage(),
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(local.login_success)));
    } catch (e) {
      debugPrint("Login error: $e\n");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${local.login_failed} : $e")));
    }
  }

  /**
   * Handles Google Sign-In in the UI.
   * Steps:
   * 1. Ask the user to choose a Google profile.
   * 2. Obtain GoogleAuth credentials.
   * 3. Pass credentials to UserController.loginWithGoogle().
   * 4. Navigate to the UserPage on success.
   */
  Future<void> _loginGoogle(BuildContext context) async {
    final controller = context.read<UserController>();

    debugPrint("UI: Google login button pressed");

    try {
      debugPrint("UI: calling UserController.loginWithGoogle()");
      await controller.loginWithGoogle();
      debugPrint("UI: UserController.loginWithGoogle() completed");

      debugPrint("UI: currentUser after Google login = ${controller.currentUser?.uid}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserPage(),
        ),
      );

      debugPrint("UI: navigation to UserPage completed");
    } catch (e, st) {
      debugPrint("UI: Google login failed");
      debugPrint("UI ERROR: $e");
      debugPrintStack(stackTrace: st);

      final local = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${local.google_login_failed}: $e")),
      );
    }
  }

  /** UI of the Login Page */
  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                language.locale.languageCode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => LanguageButton(
                  onLocaleSelected: context.read<Language>().setLocale,
                ),
              );
            },
          ),
        ],
      ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('images/Triplo_def.png', height: 120),
                const SizedBox(height: 24),

                Text(
                  local.welcome_label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                Text(
                  local.please_login_label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                // Email
                BoxField(
                  label: local.email_label,
                  isEmail: true,
                  controller: emailController,
                ),
                const SizedBox(height: 16),

                // password
                BoxField(
                  label: local.password_label,
                  isPassword: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 16),

                Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () => _loginEmailPwd(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        local.login_button,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Center(
                  child: SizedBox(
                    width: 250,
                    child: OutlinedButton.icon(
                      onPressed: () => _loginGoogle(context),
                      icon: Image.asset(
                        'images/google_logo.png',
                        width: 18,
                        height: 18,
                      ),
                      label: Text(
                        local.google_signin_button,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/registration'),
                  child: Text(
                    "${local.no_account_label} ${local.signup_label}",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgotten_password'),
                  child: Text(
                    local.forgot_password_label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }
}