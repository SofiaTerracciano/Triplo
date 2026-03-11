import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';

import '../HomePage/home-page.dart';
import '../SearchPage/search-page.dart';
import '../SettingsPage/setting-page.dart';
import '../trekkingPage/challenges-page.dart';

class CompassAltitudePage extends StatefulWidget {
  const CompassAltitudePage({super.key});

  @override
  State<CompassAltitudePage> createState() => _CompassAltitudePageState();
}

class _CompassAltitudePageState extends State<CompassAltitudePage> {

  StreamSubscription<Position>? _positionSub;

  double? _altitude;
  Position? _position;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() => _error = "Location services disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _error = "Location permission denied");
      return;
    }

    _positionSub = Geolocator.getPositionStream().listen((position) {

      if (!mounted) return;

      setState(() {
        _altitude = position.altitude;
        _position = position;
      });

    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String _direction(double heading) {

    const directions = [
      'N','NE','E','SE','S','SW','W','NW'
    ];

    final index = ((heading + 22.5) ~/ 45) % 8;

    return directions[index];
  }

  @override
  Widget build(BuildContext context) {

    final local = AppLocalizations.of(context)!;

    return Scaffold(

      appBar: AppBar(
        title: Text(local.navigation_page_title),
        centerTitle: true,
      ),

      drawer: _buildDrawer(context),

      body: _error != null
          ? Center(child: Text(_error!))
          : StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final heading = snapshot.data!.heading ?? 0;

          final direction = _direction(heading);

          return ListView(

            padding: const EdgeInsets.all(16),

            children: [

              /// COMPASS CARD
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                elevation: 4,

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      Text(
                        "${heading.toStringAsFixed(0)}° $direction",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// BUSSOLA
                      SizedBox(
                        height: 250,
                        width: 250,

                        child: Transform.rotate(
                          angle: (-heading * (pi / 180)),

                          child: Image.asset(
                            "images/Bussola.png",
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ALTITUDE CARD
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      const Icon(Icons.terrain, size: 32),

                      const SizedBox(height: 6),

                      Text(
                        _altitude != null
                            ? "${_altitude!.toStringAsFixed(1)} m"
                            : "Calculating altitude...",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Divider(),

                      const SizedBox(height: 12),

                      const Icon(Icons.location_on),

                      const SizedBox(height: 6),

                      Text(
                        _position != null
                            ? "${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}"
                            : "Loading coordinates...",
                        textAlign: TextAlign.center,
                      ),

                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  // Drawer
  Drawer _buildDrawer(BuildContext context) {

    final local = AppLocalizations.of(context)!;

    const optionStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    );

    return Drawer(

      child: ListView(
        padding: EdgeInsets.zero,

        children: [

          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.shrink(),
          ),

          ListTile(
            leading: Icon(Icons.home,
                color: Theme.of(context).colorScheme.primary),
            title: Text(local.home_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MyHomePage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.person,
                color: Theme.of(context).colorScheme.primary),
            title: Text(local.profile_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => UserPage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.search,
                color: Theme.of(context).colorScheme.primary),
            title: Text(local.search_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SearchPage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.primary),
            title: Text(local.settings_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SettingPage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.emoji_events,
                color: Theme.of(context).colorScheme.primary),
            title: Text(local.challeng_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ChallengesPage()),
              );
            },
          ),

        ],
      ),
    );
  }
}