import 'package:flutter/material.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/challenges-page.dart';
import '../GeowatchPage/Navigation.dart';
import '../SearchPage/search-page.dart';
import '../SettingsPage/setting-page.dart';
import '../UserProfilePage/user-page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import '../trekkingPage/trekking-page.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:provider/provider.dart';

// Home page widget with map and navigation drawer --> main landing page after login
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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

  // Initial center of the map (Madonna di Campiglio)
  final LatLng mapInitialCenter = const LatLng(46.230, 10.831);
  @override
  void initState() {
    super.initState();
    mapController = MapController();

    Future.microtask(() {
      context.read<TrekkingController>().loadTrekking();
    });
  }


  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          local.home_page_title, 
          style: optionStyle
        ),
        centerTitle: true, // Forced center the title
      ),

      // Main map body
      body: ZoomAwareMap(mapController: mapController),

      // Zoom buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom In button
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
          // Zoom out button
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.shrink(),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.home_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.profile_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.search_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.settings_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.emoji_events,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.challeng_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ChallengesPage()),
                );
              },
            ),

            // Navigation page
            ListTile(
              leading: Icon(
                Icons.explore,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(local.navigation_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => CompassAltitudePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget that updates its content based on the zoom level
class ZoomAwareMap extends StatefulWidget {
  final MapController mapController;

  const ZoomAwareMap({super.key, required this.mapController});

  @override
  _ZoomAwareMapState createState() => _ZoomAwareMapState();
}

class _ZoomAwareMapState extends State<ZoomAwareMap> {
  double currentZoom = 12.0;
  LatLng currentCenter = LatLng(46.230, 10.831);
  bool showRecenter = false;
  //final api = API();

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
    final trekkingController = context.watch<TrekkingController>();
    return trekkingController.allTrekkings.map((t) {
      return TaggedPolyline(
        tag: t.documentId,
        points: t.points,
        strokeWidth: 3,
        color: difficultyToColor(t.difficulty_level),
      );
    }).toList();
  }

  // Function to get markers for each trekking start point
  List<Marker> getMarkers() {
    final trekkingController = context.watch<TrekkingController>();
    return trekkingController.allTrekkings.map((t) {
      final markerColor = difficultyToColor(t.difficulty_level);

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
                builder: (context) => TrekkingPage(trekkingId: routeID),
              ),
            );
          },
          child: Icon(Icons.place, color: markerColor, size: 40),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final api = context.read<API>();
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: currentCenter,
            initialZoom: currentZoom,
             interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ), 
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
                      builder: (context) => TrekkingPage(trekkingId: routeID),
                    ),
                  );
                },
              ),

            // Markers for each trekking start point (only at low zoom)
            if (currentZoom < 12) MarkerLayer(markers: getMarkers()),
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
      return const Color.fromARGB(255, 135, 1, 162);
    default:
      return Colors.blueGrey; // fallback
  }
}
