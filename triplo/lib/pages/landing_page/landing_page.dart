import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triplo/pages/diary-page.dart';

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

import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/user.dart';


import '../../update_user_index.dart';
import '../user_search_page/user_search_page.dart';

class Landing_Page extends StatefulWidget {
  final TrekkingController trekkingController;
  final DiaryController diaryController;
  final UserController userController;
  final void Function(Locale) onLocaleChanged;

  const Landing_Page({
    super.key,
    required this.trekkingController,
    required this.diaryController,
    required this.userController,
    required this.onLocaleChanged,
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
            MyHomePage(
              trekkingController: widget.trekkingController,
              userController: widget.userController,
              diaryController: widget.diaryController,
              onLocaleChanged: widget.onLocaleChanged
            ),
          ),
          _buildNavButton(
            context,
            'Search Page',
            SearchPage(
              trekkingController: widget.trekkingController,
              userController: widget.userController,
              diaryController: widget.diaryController,
              onLocaleChanged: widget.onLocaleChanged
            ),
          ),
          _buildNavButton(
            context,
            'Setting Page',
            SettingPage(
              trekkingController: widget.trekkingController,
              userController: widget.userController,
              diaryController: widget.diaryController,
              onLocaleChanged: widget.onLocaleChanged
            ),
          ),
          // _buildNavButton(context, 'Splash Screen',  SplashScreen(onLocaleChanged: widget.onLocaleChanged)),
          _buildNavButton(
            context,
            'User Page',
            UserPage(
              trekkingController: widget.trekkingController,
              userController: widget.userController,
              diaryController: widget.diaryController,
              onLocaleChanged: widget.onLocaleChanged),
          ),
          _buildNavButton(
            context, 
            'Login Page', 
            LoginPage(
              trekkingController: widget.trekkingController,
              userController: widget.userController,
              diaryController: widget.diaryController,
              onLocaleChanged: widget.onLocaleChanged
            ),
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
            child: Text("🔍 Cerca utenti"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserSearchPage(
                    userController: widget.userController, // <- PRIMA MANCAVA
                  ),
                ),
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
