import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'search-page.dart';
import 'setting-page.dart';
import 'user-page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'trekking-page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ZoomAwareMap extends StatefulWidget {
  final MapController mapController;
  final List<Map<String, dynamic>> routes;

  const ZoomAwareMap({
    required this.mapController,
    required this.routes,
    super.key,
  });

  @override
  _ZoomAwareMapState createState() => _ZoomAwareMapState();
}

class _ZoomAwareMapState extends State<ZoomAwareMap> {
  double currentZoom = 12.0;
  LatLng currentCenter = LatLng(46.230, 10.831);
  bool showRecenter = false;

  final LatLngBounds bounds = LatLngBounds(
    LatLng(46.20699, 10.80702),
    LatLng(46.24699, 10.84702),
  );

  late final MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // Ascolta tutti gli eventi della mappa
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

  @override
  Widget build(BuildContext context) {
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
              urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),

            // Polylines solo zoom >= 20
            if (currentZoom >= 12)
              TappablePolylineLayer(
                polylineCulling: false,
                polylines: widget.routes
                    .map(
                      (r) => TaggedPolyline(
                        tag: r['name'],
                        points: List<LatLng>.from(r['points']),
                        strokeWidth: 5.0,
                        color: r['color'],
                      ),
                    )
                    .toList(),
                onTap: (tappedPolylines, tapPosition) {
                  final tapped = tappedPolylines.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrekkingPage(routeName: tapped.tag!),
                    ),
                  );
                },
              ),

            // Marker unico quando zoom < 20
            if (currentZoom < 12)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(46.230, 10.831),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Pulsante Riposizionami
        if (showRecenter)
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton.extended(
              heroTag: "recenter",
              backgroundColor: Colors.white,
              icon: const Icon(Icons.my_location, color: Colors.black),
              label: const Text("Move me"),
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  late final MapController mapController;

  // Center initiale della mappa
  final LatLng mapInitialCenter = const LatLng(46.230, 10.831);

  // Limiti massimi della mappa
  final LatLngBounds bounds = LatLngBounds(
    LatLng(46.199, 10.753),
    LatLng(46.257, 10.887),
  );

  @override
  void initState() {
    super.initState();

    mapController = MapController();

    // Listener per verificare zoom e posizione
    mapController.mapEventStream.listen((event) {
      if (event is MapEventMove || event is MapEventMoveEnd) {
        setState(() {});
      }
    });
  }

  // Predefined routes with their details (da mettere quelli veri)
  final List<Map<String, dynamic>> _routes = [
    // Dividere i percorsi a seconda delle difficoltà, quindi blu/azzurroi facile, rosso media, nero difficile
    {
      'name': 'Sentiero del Grostè',
      'color': Colors.blueAccent,
      'points': [
        LatLng(46.2285, 10.8225), // Starting point Grostè
        LatLng(46.2320, 10.8290),
        LatLng(46.2365, 10.8355),
        LatLng(46.2390, 10.8420),
      ],
    },
    {
      'name': 'Giro del Lago Nambino',
      'color': Colors.red,
      'points': [
        LatLng(46.2240, 10.8195), // Starting point Lago Nambino
        LatLng(46.2215, 10.8260),
        LatLng(46.2190, 10.8310),
        LatLng(46.2210, 10.8370),
      ],
    },
    {
      'name': 'Rifugio Vallesinella',
      'color': Colors.black,
      'points': [
        LatLng(46.2290, 10.8300), // Starting point Rifugio Vallesinella
        LatLng(46.2270, 10.8350),
        LatLng(46.2260, 10.8360),
        LatLng(46.2220, 10.8430),
        LatLng(46.2180, 10.8490),
        LatLng(46.2160, 10.8550),
      ],
    },
  ];

  // Page titles for AppBar
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Home', style: optionStyle),
    Text('Profile', style: optionStyle),
    Text('Search', style: optionStyle),
    Text('Settings', style: optionStyle),
  ];

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: _widgetOptions[_selectedIndex],
        centerTitle: true, // Forced center the title
      ),

      body: ZoomAwareMap(mapController: mapController, routes: _routes),

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
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endFloat, // Positioning the button to the bottom right
      //Drawer to control the navigation among pages
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.greenAccent),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.home_page_title, style: optionStyle),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppLocalizations.of(context)!.profile_page_title, style: optionStyle),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(AppLocalizations.of(context)!.search_page_title, style: optionStyle),
              selected: _selectedIndex == 2,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings_page_title, style: optionStyle),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
