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
import '../challenges-page.dart';

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
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
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

                return Column(
                  children: [
                    // Compass section
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${heading.toStringAsFixed(0)}° $direction",
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Transform.rotate(
                                angle: (-heading * (pi / 180)),
                                child: Image.asset(
                                  "images/compass.png",
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback se l'immagine non viene trovata
                                    return Icon(Icons.explore, 
                                           size: 200, 
                                           color: Theme.of(context).colorScheme.primary);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Data section (altitude + coordinates)
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.terrain, size: 30),
                                const SizedBox(width: 10),
                                Text(
                                  _altitude != null
                                      ? "${_altitude!.toStringAsFixed(1)} m"
                                      : "--- m",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              _position != null
                                  ? "${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}"
                                  : "Loading coordinates...",
                              style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
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
  Widget _buildDrawer(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    const optionStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.shrink(),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            title: Text(local.home_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            title: Text(local.profile_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            title: Text(local.search_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            title: Text(local.settings_page_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
            title: Text(local.challeng_title, style: optionStyle),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ChallengesPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.explore, color: Theme.of(context).colorScheme.primary),
            title: Text(local.navigation_page_title, style: optionStyle),
            onTap: () {
              Navigator.pop(context); 
            },
          ),
        ],
      ),
    );
  }
}