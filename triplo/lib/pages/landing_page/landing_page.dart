import 'package:flutter/material.dart';
import 'package:triplo/pages/home-page.dart';


// Import delle pagine
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/search-page.dart';
import 'package:triplo/pages/setting-page.dart';
import 'package:triplo/pages/splash-screen.dart';
import 'package:triplo/pages/trekking-page.dart';
import 'package:triplo/pages/user-page.dart';


// Import da sottocartella Login_Page
import 'package:triplo/pages/Login_Page/LoginPage.dart';


// Import da sottocartella geowatch
import 'package:triplo/pages/geowatch/geowatch.dart';


class Landing_Page extends StatelessWidget {
  const Landing_Page({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page (Debug)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNavButton(context, 'Home Page', const MyHomePage()),
          _buildNavButton(context, 'Search Page', const SearchPage()),
          _buildNavButton(context, 'Setting Page', const SettingPage()),
          _buildNavButton(context, 'Splash Screen', const SplashScreen()),
          _buildNavButton(context, 'User Page', const UserPage()),
          _buildNavButton(context, 'Login Page', LoginPage()),
          _buildNavButton(context, 'GeoWatch', GeoWatchPage()),
        ],
      ),
    );
  }


  Widget _buildNavButton(BuildContext context, String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        child: Text(label),
      ),
    );
  }
}