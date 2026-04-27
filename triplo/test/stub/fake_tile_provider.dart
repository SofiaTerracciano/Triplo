import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class FakeTileProvider extends TileProvider {
  FakeTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return const AssetImage('images/blank_tile.png');
  }
}