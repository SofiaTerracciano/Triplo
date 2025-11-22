import 'package:latlong2/latlong.dart';
class Trekking {
  String _name;
  String _difficulty_level;
  double _distance;
  double _estimated_time;
  double _elevation_gain;
  LatLng _starting_point;
  LatLng _ending_point;
  String _starting_point_name;
  String _ending_point_name;
  String _info;
  String _description;
  String _refreshment_point; // da fare poi interattivo
  bool _pic_nic_area;
  bool _family_firendly;

  Trekking({
    required String name,
    required String difficultyLevel,
    required double distance,
    required double estimatedTime,
    required double elevationGain,
    required LatLng startingPoint,
    LatLng? endingPoint,
    String? startingPointName,
    String? endingPointName,
    String? info,
    String? description,
    String? refreshmentPoint,
    bool picNicArea = false,
    bool familyFirendly = false,
  })  : _name = name,
       _difficulty_level = difficultyLevel,
       _distance = distance,
       _estimated_time = estimatedTime,
       _elevation_gain = elevationGain,
       _starting_point = startingPoint,
       _ending_point = endingPoint ?? startingPoint,
       _starting_point_name = startingPointName ?? '',
       _ending_point_name = endingPointName ?? '',
       _info = info ?? '',
       _description = description ?? '',
       _refreshment_point = refreshmentPoint ?? '',
       _pic_nic_area = picNicArea,
       _family_firendly = familyFirendly;

  //Getters
  String get name => _name;
  String get difficulty_level => difficulty_level;
  double get distance => _distance;
  double get estimated_time => _estimated_time;
  double get elevation_gain => _elevation_gain;
  LatLng get starting_point => _starting_point;
  String get starting_point_name => _starting_point_name;
  String get ending_point_name => _ending_point_name;
  String get info => _info;
  String get description => _description;
  String get refreshment_point => _refreshment_point;
  bool get pic_nic_area => _pic_nic_area;
  bool get family_firendly => _family_firendly;

  //Setters
  set name(String name) => _name = name;
  set difficulty_level(String difficultyLevel) => _difficulty_level = difficultyLevel;
  set distance(double distance) => _distance = distance;
  set estimated_time(double estimatedTime) => _estimated_time = estimatedTime;
  set elevation_gain(double elevationGain) => _elevation_gain = elevationGain;
  set starting_point(LatLng startingPoint) => _starting_point = startingPoint;
  set ending_point(LatLng endingPoint) => _ending_point = endingPoint;
  set starting_point_name(String startingPointName) => _starting_point_name = startingPointName;
  set ending_point_name(String endingPointName) => _ending_point_name = endingPointName;
  set info(String info) => _info = info;
  set description(String description) => _description = description;
  set refreshment_point(String refreshmentPoint) => _refreshment_point = refreshmentPoint;
  set pic_nic_area(bool picNicArea) => _pic_nic_area = picNicArea;
  set family_firendly(bool familyFirendly) => _family_firendly = familyFirendly;

}