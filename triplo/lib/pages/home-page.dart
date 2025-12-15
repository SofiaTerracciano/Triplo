import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/challenges-page.dart';
import 'search-page.dart';
import 'setting-page.dart';
import 'user-page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'trekking-page.dart';
import 'package:triplo/controller/trekking.dart';

class MyHomePage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final TrekkingController trekkingController;
  final DiaryController diaryController;
  final UserController userController;

  const MyHomePage({
    super.key,
    required this.onLocaleChanged,
    required this.diaryController,
    required this.trekkingController,
    required this.userController
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  late MapController mapController;

  // Initial center of the map
  final LatLng mapInitialCenter = const LatLng(46.230, 10.831);

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.home_page_title, style: optionStyle),
        centerTitle: true, // Forced center the title
      ),

      // Main map body
      body: ZoomAwareMap(
        mapController: mapController,
        trekkingController: widget.trekkingController,
        userController: widget.userController,
        diaryController: widget.diaryController,
        onLocaleChanged: widget.onLocaleChanged,
      ),

      // Zoom buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoomIn",
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom + 1);
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: Colors.black),
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom - 1);
            },
          ),
        ],
      ),
      // Positioning the button to the bottom right
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 

      //Drawer to control the navigation among pages
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.greenAccent),
              child: Text(
                local.menu_title,
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(local.home_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(
                      onLocaleChanged: widget.onLocaleChanged,
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
                      userController: widget.userController,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(local.profile_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserPage(
                          onLocaleChanged: widget.onLocaleChanged,
                          userController: widget.userController,
                          diaryController: widget.diaryController,
                          trekkingController: widget.trekkingController,
                        ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(local.search_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(
                      diaryController: widget.diaryController,
                      trekkingController: widget.trekkingController,
                      userController: widget.userController,
                      onLocaleChanged: widget.onLocaleChanged,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(local.settings_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingPage(
                          onLocaleChanged: widget.onLocaleChanged, 
                          trekkingController: widget.trekkingController, 
                          userController: widget.userController, 
                          diaryController: widget.diaryController,
                        ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text(local.challeng_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChallengesPage(
                          onLocaleChanged: widget.onLocaleChanged,
                          trekkingController: widget.trekkingController,
                          userController: widget.userController,
                          diaryController: widget.diaryController,
                        ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

// Widget that updates its content based on the zoom level
class ZoomAwareMap extends StatefulWidget {
  final MapController mapController;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;
  final void Function(Locale) onLocaleChanged;

  const ZoomAwareMap({
    super.key,
    required this.mapController,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
    required this.onLocaleChanged,
  });

  @override
  _ZoomAwareMapState createState() => _ZoomAwareMapState();
}

class _ZoomAwareMapState extends State<ZoomAwareMap> {
  double currentZoom = 12.0;
  LatLng currentCenter = LatLng(46.230, 10.831);
  bool showRecenter = false;
  final api = API();

  // Bounds of the map area
  final LatLngBounds bounds = LatLngBounds(
    LatLng(46.20699, 10.80702),
    LatLng(46.24699, 10.84702),
  );

  late final MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // Listener to verify zoom changes
    widget.mapController.mapEventStream.listen((event) {
      if (event is MapEventMove || event is MapEventMoveEnd) {
        setState(() {
          currentZoom = widget.mapController.zoom;
          currentCenter = widget.mapController.center;
          showRecenter = !bounds.contains(currentCenter);
        });
      }
    });
  }

  // Function to get polylines for each trekking route
  List<TaggedPolyline> getPolylines() {
    return widget.trekkingController.allTrekkings.map((t) {
      return TaggedPolyline(
        tag: t.documentId,
        points: t.points,
        strokeWidth: 5,
        color: difficultyToColor(t.difficulty_level),
      );
    }).toList();
  }

  // Function to get markers for each trekking start point
  List<Marker> getMarkers() {
    return widget.trekkingController.allTrekkings.map((t) {
      return Marker(
        point: t.starting_point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            final routeID = t.documentId;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrekkingPage(
                  trekkingId: routeID,
                  trekkingController: widget.trekkingController,
                  userController: widget.userController,
                  diaryController: widget.diaryController,
                  onLocaleChanged: widget.onLocaleChanged,
                ),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.red, size: 40),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: currentCenter,
            initialZoom: currentZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: api.openTopoMapTile(),
              subdomains: api.openTopoMapSubdomains(),
            ),

            // Polylines only at high zoom of all trekkings available
            if (currentZoom >= 12)
              TappablePolylineLayer(
                polylineCulling: false,
                polylines: getPolylines(),
                onTap: (tapped, pos) {
                  final routeID = tapped.first.tag as String;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrekkingPage(
                        trekkingId: routeID,
                        trekkingController: widget.trekkingController,
                        userController: widget.userController,
                        diaryController: widget.diaryController,
                        onLocaleChanged: widget.onLocaleChanged,
                      ),
                    ),
                  );
                },
              ),

            // Markers for each trekking start point (only at low zoom)
            if (currentZoom < 12) 
              MarkerLayer(markers: getMarkers()),
          ],
        ),

        // Move to center button
        if (showRecenter)
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton.extended(
              heroTag: "recenter",
              backgroundColor: Colors.white,
              icon: const Icon(Icons.my_location, color: Colors.black),
              label: Text(local.repositioning_button_label),
              onPressed: () {
                widget.mapController.move(LatLng(46.230, 10.831), 12);
                setState(() => showRecenter = false);
              },
            ),
          ),
      ],
    );
  }
}

// Function to convert difficulty level to color
Color difficultyToColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case "easy":
      return Colors.lightBlue;
    case "intermediate":
      return Colors.red;
    case "hard":
      return Colors.black;
    default:
      return Colors.blueGrey; // fallback
  }
}
