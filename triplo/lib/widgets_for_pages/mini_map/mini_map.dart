import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Mini_Map extends StatelessWidget {
  final LatLng center;

  const Mini_Map({Key? key, required this.center}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          key: ValueKey(center),
          options: MapOptions(
            initialCenter: center,
            initialZoom: 10,
            interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
              userAgentPackageName: "com.example.triplo",
            ),
            MarkerLayer(markers: [
              Marker(
                point: center,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_pin,
                    color: Colors.blue, size: 40),
              )
            ])
          ],
        ),
      ),
    );
  }
}
