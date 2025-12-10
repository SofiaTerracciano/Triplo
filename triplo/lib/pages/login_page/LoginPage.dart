import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';
import 'package:triplo/controller/user.dart';
import '../user-page.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/diary.dart';

/**
 * Login Page for the Triplo App.
 * Email+password login + Google sign-in.
 */
class LoginPage extends StatefulWidget {
  final TrekkingController trekkingController;
  final DiaryController diaryController;
  final UserController userController;
  final void Function(Locale) onLocaleChanged;

  const LoginPage({
    super.key,
    required this.trekkingController,
    required this.diaryController,
    required this.userController,
    required this.onLocaleChanged,
  });

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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    final controller = Provider.of<UserController>(context, listen: false);
    try {
      await controller.login(email, password);
      final uid = controller.currentUser!.uid;
      print(uid);
      widget.diaryController.currentUser = controller.currentUser!;
      print(widget.diaryController.currentUser!.uid);
      print("following = ${widget.userController.currentUser!.following}");
      await widget.diaryController.loadPublicDiary(uid);
      await widget.diaryController.loadPrivateDiary(uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserPage(
            trekkingController: widget.trekkingController,
            userController: widget.userController,
            diaryController: widget.diaryController,
            onLocaleChanged: (l) {},
          ),
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged in")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
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
    final googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final controller = Provider.of<UserController>(context, listen: false);
      await controller.loginWithGoogle(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserPage(
            trekkingController: widget.trekkingController,
            userController: widget.userController,
            diaryController: widget.diaryController,
            onLocaleChanged: (l) {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google login failed: $e")));
    }
  }

  /** UI of the Login Page */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // horizontally
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('images/logo.png', height: 120),
                const SizedBox(height: 24),

                const Text(
                  'Welcome to the Triplo App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Please login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                // email
                BoxField(
                  label: 'email',
                  isEmail: true,
                  controller: emailController,
                ),
                const SizedBox(height: 16),

                // password
                BoxField(
                  label: 'password',
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
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Login',
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
                      label: const Text(
                        'Sign-in with Google',
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
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgotten_password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
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
