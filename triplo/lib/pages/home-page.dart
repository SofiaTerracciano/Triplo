import 'package:flutter/material.dart';
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

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

    return Scaffold(
      appBar: AppBar(
        title: _widgetOptions[_selectedIndex],
        centerTitle: true, // Forced center the title
      ),

      body: FlutterMap(
        // FlutterMap widget to show a map
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(
            46.230,
            10.831,
          ), // Center in Madonna di Campiglio
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            // TileLayer to load map tiles
            urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.tua.app',
          ),

          // Functionality to tap on polylines
          TappablePolylineLayer(
            polylineCulling: false,
            polylines: _routes
                .map(
                  (r) => TaggedPolyline( // TaggedPolyline to identify each route
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
                  builder: (context) => TrekkingPage(routeName: tapped.tag!), // Navigate to TrekkingPage with route name
                ),
              );
            },
          ),

          MarkerLayer(
            // MarkerLayer to show markers on the map
            markers: [
              Marker(
                point: LatLng(46.2300, 10.8310), // Centro Madonna di Campiglio
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              Marker(
                point: LatLng(46.2285, 10.8225), // Grostè
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.outlined_flag,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              Marker(
                point: LatLng(46.2240, 10.8195), // Lago Nambino
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.outlined_flag,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              Marker(
                point: LatLng(46.2290, 10.8300), // Rifugio Vallesinella
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.outlined_flag,
                  color: Colors.green,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
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
              mapController.move(
                mapController.center, 
                mapController.zoom + 1);
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: Colors.black),
            onPressed: () {
              mapController.move(
                mapController.center, 
                mapController.zoom - 1);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positioning the button to the bottom right

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
              title: const Text('Home', style: optionStyle),
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
              title: const Text('Profile', style: optionStyle),
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
              title: const Text('Search', style: optionStyle),
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
              title: const Text('Settings', style: optionStyle),
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
