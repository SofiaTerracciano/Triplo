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
  const MyHomePage({super.key, required this.onLocaleChanged});
   final void Function(Locale) onLocaleChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ZoomAwareMap extends StatefulWidget {
  final MapController mapController;
  final List<Map<String, dynamic>> routes;
  final void Function(Locale) onLocaleChanged;

  const ZoomAwareMap({
    super.key,
    required this.mapController,
    required this.routes,
    required this.onLocaleChanged,
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
                        TrekkingPage(
                          routeName: tapped.tag!,
                          onLocaleChanged: widget.onLocaleChanged
                          ),
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

class _MyHomePageState extends State<MyHomePage> {
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
        LatLng(46.173488, 10.738094),
        LatLng(46.173287, 10.737364),
        LatLng(46.172935, 10.737014),
        LatLng(46.172011, 10.735069),
        LatLng(46.171774, 10.734817),
        LatLng(46.171936, 10.734740),
        LatLng(46.171401, 10.729228),
        LatLng(46.171252, 10.729061),
        LatLng(46.170813, 10.727091),
        LatLng(46.170373, 10.726367),
        LatLng(46.170334, 10.725488),
        LatLng(46.169537, 10.723477),
        LatLng(46.169651, 10.723242),
        LatLng(46.169546, 10.722581),
        LatLng(46.168905, 10.721334),
        LatLng(46.168531, 10.721998),
        LatLng(46.168157, 10.721197),
        LatLng(46.168017, 10.719532),
        LatLng(46.168458, 10.717708),
        LatLng(46.168007, 10.716186),
        LatLng(46.168103, 10.716167),
        LatLng(46.168109, 10.715545),
        LatLng(46.168271, 10.715434),
        LatLng(46.168165, 10.714746),
        LatLng(46.168290, 10.714082),
        LatLng(46.168632, 10.714133),
        LatLng(46.168743, 10.714374),
        LatLng(46.168831, 10.714068),
        LatLng(46.168711, 10.713953),
        LatLng(46.168592, 10.714087),
        LatLng(46.168302, 10.714062),
        LatLng(46.167971, 10.712928),
        LatLng(46.167644, 10.712362),
        LatLng(46.167204, 10.712263),
        LatLng(46.166850, 10.711170),
        LatLng(46.166804, 10.709701),
        LatLng(46.166589, 10.709196),
        LatLng(46.166676, 10.708840),
        LatLng(46.166517, 10.708642),
        LatLng(46.166687, 10.708327),
        LatLng(46.166606, 10.708081),
        LatLng(46.166729, 10.707674),
        LatLng(46.166557, 10.706981),
        LatLng(46.166695, 10.706968),
        LatLng(46.166564, 10.706829),
        LatLng(46.167166, 10.706765),
        LatLng(46.166830, 10.706729),
        LatLng(46.166605, 10.706866),
        LatLng(46.166522, 10.706715),
        LatLng(46.166490, 10.706540),
        LatLng(46.166650, 10.706589),
        LatLng(46.166545, 10.706656),
        LatLng(46.166470, 10.706443),
        LatLng(46.166500, 10.706028),
        LatLng(46.166337, 10.705599),
        LatLng(46.166501, 10.705327),
        LatLng(46.166435, 10.704417),
        LatLng(46.166349, 10.704037),
        LatLng(46.166221, 10.704074),
        LatLng(46.166289, 10.703613),
        LatLng(46.166136, 10.703377),
        LatLng(46.166317, 10.703258),
        LatLng(46.166180, 10.703058),
        LatLng(46.166325, 10.702799),
        LatLng(46.166100, 10.703024),
        LatLng(46.166263, 10.703060),
        LatLng(46.166011, 10.702630),
        LatLng(46.165851, 10.701990),
        LatLng(46.165944, 10.701981),
        LatLng(46.165702, 10.701552),
        LatLng(46.165820, 10.701566),
        LatLng(46.165355, 10.700014),
        LatLng(46.165444, 10.699020),
        LatLng(46.165326, 10.698562),
        LatLng(46.165490, 10.698630),
        LatLng(46.165129, 10.698616),
        LatLng(46.165293, 10.698742),
        LatLng(46.165183, 10.698540),
        LatLng(46.165338, 10.698437),
        LatLng(46.165283, 10.697914),
        LatLng(46.164456, 10.695810),
        LatLng(46.164529, 10.695213),
        LatLng(46.164377, 10.694678),
        LatLng(46.164474, 10.694173),
        LatLng(46.164576, 10.694171),
        LatLng(46.164594, 10.693565),
        LatLng(46.164690, 10.693563),
        LatLng(46.164407, 10.693159),
        LatLng(46.164388, 10.693435),
        LatLng(46.164231, 10.693299),
        LatLng(46.164148, 10.693766),
        LatLng(46.164182, 10.693414),
        LatLng(46.164081, 10.693303),
        LatLng(46.164037, 10.693453),
        LatLng(46.163953, 10.693133)
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

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          local.home_page_title, 
          style: optionStyle
        ),
        centerTitle: true, // Forced center the title
      ),

      body: ZoomAwareMap(
        mapController: mapController, 
        routes: _routes,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positioning the button to the bottom right

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
              title: Text(
                local.home_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(onLocaleChanged: widget.onLocaleChanged)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                local.profile_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>  UserPage(onLocaleChanged: widget.onLocaleChanged)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(
                local.search_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage(onLocaleChanged: widget.onLocaleChanged)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                local.settings_page_title, 
                style: optionStyle
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage(onLocaleChanged: widget.onLocaleChanged)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Color difficultyToColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case "easy":
      return Colors.lightBlue;
    case "medium":
      return Colors.orange;
    case "hard":
      return Colors.red;
    default:
      return Colors.blueGrey; // fallback
  }
}
