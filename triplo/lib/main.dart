import 'package:flutter/material.dart';
import 'package:triplo/pages/login_page/LoginPage.dart';
import 'pages/home-page.dart';
import 'pages/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triplo/pages/registration_page/registration_page.dart';
import 'firebase_options.dart';
import '/pages/login_page/LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triplo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      //home: const MyHomePage(),
      //home: const SplashScreen(),
      //home: RegistrationPage(),


      initialRoute: '/login',

      routes: {
        '/login' : (context) => LoginPage(),
        '/registration' : (context) => RegistrationPage(),

      },

    );
  }
}
