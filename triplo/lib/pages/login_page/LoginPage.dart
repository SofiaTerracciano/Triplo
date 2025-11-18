import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'package:triplo/widgets_for_pages/box_field/box_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

///Login Page for the Triplo App, allowing sign in with email and password and Google sign-in
class LoginPage extends StatelessWidget {
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  LoginPage({super.key});

  @override
  Widget build(BuildContext b) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Login'),),
      body: Center(
        //horizontally
        child: SingleChildScrollView(
          //a single widget can be scrolled
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, //vertically
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

                //email field
                BoxField(
                  label: 'email',
                  isEmail: true,
                  controller: emailcontroller,
                ),
                const SizedBox(height: 16),
                //password field
                BoxField(
                  label: 'password',
                  isPassword: true,
                  controller: passwordcontroller,
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = emailcontroller.text.trim();
                        final password = passwordcontroller.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(b).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in both fields'),
                            ),
                          );
                          return;
                        }

                        //Firebase
                        //ScaffoldMessenger.of(b).showSnackBar(
                        //SnackBar(content: Text('Logging in')),
                        //);
                        try {
                          await login(email, password);
                          ScaffoldMessenger.of(b).showSnackBar(
                            const SnackBar(content: Text('Logged in')),
                          );

                          //Navigator.pushReplacementNamed(b, '/home);
                        } on FirebaseAuthException catch (e) {
                          String message;
                          switch (e.code) {
                            case 'user-not-found':
                              message = 'No user is registered with this email';
                              break;
                            case 'wrong-password':
                              message = 'Wrong Password';
                              break;
                            default:
                              message = 'Login failed : ${e.message}';
                          }
                          ScaffoldMessenger.of(
                            b,
                          ).showSnackBar(SnackBar(content: Text(message)));
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
                      onPressed: () async {
                        await signInWithGoogle(b);
                        ScaffoldMessenger.of(b).showSnackBar(
                          const SnackBar(content: Text('Google sign-in')),
                        );
                      },
                      icon: Image.asset('images/google_logo.png'),
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

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(b, '/registration');
                    ScaffoldMessenger.of(
                      b,
                    ).showSnackBar(const SnackBar(content: Text('Sign-up')));
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
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

  ///Firebase email and password login
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Logged in');
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.message}');
      rethrow;
    }
  }

  Future<void> signInWithGoogle(BuildContext BB) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(BB).showSnackBar(
          const SnackBar(content: Text('Google sign-in cancelled')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      ScaffoldMessenger.of(BB).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${googleUser.displayName ?? 'User'}!'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(BB).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(BB).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }
}
