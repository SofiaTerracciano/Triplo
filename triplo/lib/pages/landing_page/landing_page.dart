import 'package:flutter/material.dart';
// Import delle pagine
import 'package:triplo/pages/home-page.dart';
import 'package:triplo/pages/search-page.dart';
import 'package:triplo/pages/setting-page.dart';
import 'package:triplo/pages/user-page.dart';

// Import da sottocartella Login_Page
import 'package:triplo/pages/login_page/LoginPage.dart';

// Import da sottocartella geowatch
import 'package:triplo/pages/geowatch/geowatch.dart';

// Import della pagina admin che carica i punti
import 'package:triplo/update_points.dart';

import '../../update_user_index.dart';

class Landing_Page extends StatefulWidget {

  const Landing_Page({
    super.key,
  });

  @override
  State<Landing_Page> createState() => _Landing_PageState();
}

class _Landing_PageState extends State<Landing_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landing Page (Debug)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNavButton(
            context,
            'Home Page',
            MyHomePage(),
          ),
          _buildNavButton(
            context,
            'Search Page',
            SearchPage(),
          ),
          _buildNavButton(
            context,
            'Setting Page',
            SettingPage(),
          ),
          // _buildNavButton(context, 'Splash Screen',  SplashScreen(onLocaleChanged: widget.onLocaleChanged)),
          _buildNavButton(
            context,
            'User Page',
            UserPage(),
          ),
          _buildNavButton(
            context, 
            'Login Page', 
            LoginPage(),
          ),
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
                MaterialPageRoute(builder: (_) => const AdminUploadPage()),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => updateUsersIndex(),
            child: Text("Update Users Index"),
          )
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
