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

// Import della pagina admin che carica i punti
import 'package:triplo/update_points.dart';

class Landing_Page extends StatelessWidget {
  const Landing_Page({super.key, required this.onLocaleChanged});
  final void Function(Locale) onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landing Page (Debug)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNavButton(context, 'Home Page', MyHomePage(onLocaleChanged: onLocaleChanged)),
          _buildNavButton(context, 'Search Page',  SearchPage(onLocaleChanged: onLocaleChanged)),
          _buildNavButton(context,'Setting Page', SettingPage(onLocaleChanged: onLocaleChanged),),
         // _buildNavButton(context, 'Splash Screen',  SplashScreen(onLocaleChanged: widget.onLocaleChanged)),
          _buildNavButton(context, 'User Page',  UserPage(onLocaleChanged: onLocaleChanged)),
          _buildNavButton(context, 'Login Page', LoginPage()),
          _buildNavButton(context, 'GeoWatch', GeoWatchPage()),
          
           // Bottone per caricare i punti trekking
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              "Carica punti trekking nel DB",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminUploadPage(),
                ),
              );
            },
          ),
          
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Text(label),
      ),
    );
  }
}
