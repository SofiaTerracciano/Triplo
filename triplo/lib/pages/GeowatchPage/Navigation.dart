import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import '../../controller/servicecontroller.dart';
import '../HomePage/home-page.dart';
import '../SearchPage/search-page.dart';
import '../SettingsPage/setting-page.dart';


class CompassAltitudePage extends StatefulWidget {
  const CompassAltitudePage({super.key});


  @override
  State<CompassAltitudePage> createState() => _CompassAltitudePageState();
}

/*class _CompassAltitudePageState extends State<CompassAltitudePage> {*/
class _CompassAltitudePageState extends State<CompassAltitudePage> with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionSub;

  double? _altitude;
  Position? _position;
  String? _error;
  bool _isChecking = true;
  /*@override
  void initState() {
    super.initState();
    _initLocation();
  }*/
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  @override
  void dispose() {
    // 2. Rimuovi l'observer e cancella lo stream per evitare memory leak
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 3. Se l'utente torna nell'app (es. dopo aver cambiato i permessi nelle impostazioni)
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isChecking = true;
      });
      _initLocation();
    }
  }

  /*Future<void> _initLocation() async {
    await PermissionService.askPermissionsOnce();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _error = "GPS_DISABLED";
          _isChecking = false;
        });
      }
      return;
    }

    PermissionStatus status = await Permission.location.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _error = "PERMISSION_DENIED";
          _isChecking = false;
        });
      }
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _altitude = position.altitude;
        _position = position;
        _error = null;
        _isChecking = false;
      });
    });
  }*/
  Future<void> _initLocation() async {
    final servicecontroller = context.read<ServiceController>();

    final state = await servicecontroller.loadNavigationLocation();

    if (!mounted) return;

    if (state.error != null) {
      await _positionSub?.cancel();
      setState(() {
        _altitude = null;
        _position = null;
        _error = state.error;
        _isChecking = state.isChecking;
      });
      return;
    }

    await _positionSub?.cancel();

    _positionSub = servicecontroller.navigationPositionStream().listen((position) {
      if (!mounted) return;

      setState(() {
        _altitude = position.altitude;
        _position = position;
        _error = null;
        _isChecking = false;
      });
    });
  }

  /*@override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }*/

  String _direction(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) ~/ 45) % 8;
    return directions[index];
  }

  Widget _buildErrorState(String errorType, AppLocalizations local) {
    String title = errorType == "GPS_DISABLED"
        ? local.gps_disabled_message
        : local.permission_denied;

    String message = errorType == "GPS_DISABLED"
        ? local.gps_disabled
        : local.permission_denied_message;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off,
              size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final servicecontroller = context.read<ServiceController>();

              if (errorType == "GPS_DISABLED") {
                await servicecontroller.openGpsSettings();
              } else {
                await servicecontroller.openPermissionSettings();
              }
            },
            child: Text(local.open_settings_button),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.navigation_page_title),
        centerTitle: true,
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(_error!, local)
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                  child: StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final heading = snapshot.data!.heading ?? 0;
                      final direction = _direction(heading);
                      final primary = Theme.of(context).colorScheme.primary;

                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [

                              /// ---------------- COMPASS CARD ----------------
                              Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                                  child: Column(
                                    children: [

                                      Icon(Icons.explore, size: 34, color: primary),

                                      const SizedBox(height: 8),

                                      Text(
                                        "${heading.toStringAsFixed(0)}°  $direction",
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: primary,
                                        ),
                                      ),

                                      const SizedBox(height: 30),

                                      /// COMPASS CIRCLE
                                      Container(
                                        height: 260,
                                        width: 260,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primary,
                                            width: 5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 12,
                                              spreadRadius: 3,
                                            )
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Transform.rotate(
                                            angle: (-heading * (pi / 180)),
                                            child: Image.asset("images/compass.png"),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// ---------------- ALTITUDE CARD ----------------
                              Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                                  child: Column(
                                    children: [

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.terrain, color: primary, size: 28),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                        _altitude != null
                                            ? "${_altitude!.toStringAsFixed(1)} m"
                                            : "-- m",
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      Divider(
                                        thickness: 1.2,
                                        color: primary.withOpacity(0.3),
                                      ),

                                      const SizedBox(height: 20),

                                      Icon(Icons.location_on, color: primary),

                                      const SizedBox(height: 6),

                                      Text(
                                        _position != null
                                            ? "${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}"
                                            : local.loading_coordinates,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
              ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primary),
              child: const SizedBox.shrink(),
            ),
            ListTile(
              leading: Icon(Icons.home, color: primary),
              title: Text(local.home_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => MyHomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: primary),
              title: Text(local.profile_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => UserPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: primary),
              title: Text(local.search_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SearchPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: primary),
              title: Text(local.settings_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SettingPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events, color: primary),
              title: Text(local.challeng_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ChallengesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.explore, color: primary),
              title: Text(local.navigation_page_title, style: optionStyle),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}