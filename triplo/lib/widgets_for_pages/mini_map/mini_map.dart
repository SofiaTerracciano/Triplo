import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/servicecontroller.dart';

class Mini_Map extends StatelessWidget {
  final LatLng center;
  final TileProvider? tileProvider;

  const Mini_Map({
    Key? key,
    required this.center,
    this.tileProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final api = context.read<ServiceController>();

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
              tileProvider: tileProvider ?? CancellableNetworkTileProvider(),
              urlTemplate: api.googleSatelliteTile(),
              userAgentPackageName: "com.example.triplo",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 50,
                  height: 50,


                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}