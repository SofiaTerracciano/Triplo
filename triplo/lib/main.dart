import 'package:flutter/material.dart';
import 'package:triplo/pages/login_page/LoginPage.dart';
import 'pages/home-page.dart';
import 'pages/splash-screen.dart';

void main() {
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
      home: LoginPage(),
    );
  }
}
