import 'package:app_triplo_wearos/pages/login.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const TriploWatchApp());
}

class TriploWatchApp extends StatelessWidget {
  const TriploWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WatchLoginPage(),
    );
  }
}
