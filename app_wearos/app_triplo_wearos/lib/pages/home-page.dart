import 'package:app_triplo_wearos/controller/API.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/pages/trekking-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController mapController = MapController();
  // Madonna di Campiglio center
  final LatLng campiglioCenter = const LatLng(46.230, 10.831);
  // Initial zoom level
  double currentZoom = 13.0;

  final api = API();

  // Inizialization: loading of data directly without login and listen to map events for zoom level updates
  //(since on watch we want to show subito the map with i trekking) --> capire però come fare e cosa perchè mobile devi avere il login
  @override
  void initState() {
    super.initState();
    _loadDataDirectly();

    // Listen to map events to update zoom level
    mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {
          currentZoom = mapController.camera.zoom;
        });
      }
    });
  }

  Future<void> _loadDataDirectly() async {
    // Chiamiamo direttamente il load del controller
    await context.read<TrekkingController>().loadTrekking(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: campiglioCenter,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                InteractiveFlag.drag,
              ), 
            ),
            children: [
              TileLayer(
                urlTemplate: api.openTopoMapTile(),
                subdomains: api.openTopoMapSubdomains(),
              ),

              // Show polylines only if zoom is sufficient
              if (currentZoom >= 12.5)
                TappablePolylineLayer(
                  polylines: trekkingController.allTrekkings.map((t) {
                    return TaggedPolyline(
                      tag: t.documentId,
                      points: t.points,
                      strokeWidth: 3,
                      color: difficultyToColor(t.difficulty_level),
                    );
                  }).toList(),
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

              // Show markers only if zoom is low to avoid clutter
              if (currentZoom < 12.5)
                MarkerLayer(
                  markers: trekkingController.allTrekkings
                      .map(
                        (t) => Marker(
                          point: t.starting_point,
                          width: 35,
                          height: 35,
                          child: GestureDetector(
                            onTap: () {
                              final routeID = t.documentId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TrekkingPage(trekkingId: routeID),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.location_on,
                              size: 35,
                              color: difficultyToColor(t.difficulty_level),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),

          // Recenter button
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: _watchCircleButton(Icons.my_location, () {
                mapController.move(campiglioCenter, 13);
              }, size: 25),
            ),
          ),

          // Zoom buttons
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom -
                  _watchCircleButton(Icons.remove, () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom - 1,
                    );
                  }, size: 25),
                  const SizedBox(width: 4),
                  // Zoom +
                  _watchCircleButton(Icons.add, () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom + 1,
                    );
                  }, size: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for circular buttons on watch
  Widget _watchCircleButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      ),
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
