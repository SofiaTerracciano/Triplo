import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Trekking {
  final String documentId;

  String _name;
  String _mapPhoto;
  String _difficulty_level;
  double _distance;
  double _estimated_time;
  double _elevation_gain;
  bool _upGain;
  bool _downGain;
  LatLng _starting_point;
  LatLng _ending_point;
  List<LatLng> _points;
  String _starting_point_name;
  String _ending_point_name;
  List<String> _info;
  String _endingPointPhoto;
  List<String> _description;
  String _refreshment_point;
  bool _pic_nic_area;
  bool _family_firendly;
  List<String> _challenges;

  Trekking({
    required this.documentId,
    required String name,
    required String mapPhoto,
    required String difficultyLevel,
    required double distance,
    required double estimatedTime,
    required double elevationGain,
    required bool upGain,
    required bool downGain,
    required LatLng startingPoint,
    required LatLng endingPoint,
    required List<LatLng> points,
    required String startingPointName,
    required String endingPointName,
    required List<String> info,
    required String endingPointPhoto,
    required List<String> description,
    String? refreshmentPoint,
    required bool picNicArea,
    required bool familyFirendly,
    List<String>? challenges,
  }) : _name = name,
       _mapPhoto = mapPhoto,
       _difficulty_level = difficultyLevel,
       _distance = distance,
       _estimated_time = estimatedTime,
       _elevation_gain = elevationGain,
       _upGain = upGain,
       _downGain = downGain,
       _starting_point = startingPoint,
       _ending_point = endingPoint,
       _points = points,
       _starting_point_name = startingPointName,
       _ending_point_name = endingPointName,
       _info = info,
       _endingPointPhoto = endingPointPhoto,
       _description = description,
       _refreshment_point = refreshmentPoint ?? '',
       _pic_nic_area = picNicArea,
       _family_firendly = familyFirendly,
       _challenges = challenges ?? [];
      

  // Getters
  String get name => _name;
  String get mapPhoto => _mapPhoto;
  String get difficulty_level => _difficulty_level;
  double get distance => _distance;
  double get estimated_time => _estimated_time;
  double get elevation_gain => _elevation_gain;
  bool get upGain => _upGain;
  bool get downGain => _downGain;
  LatLng get starting_point => _starting_point;
  LatLng get ending_point => _ending_point;
  List<LatLng> get points => _points;
  String get starting_point_name => _starting_point_name;
  String get ending_point_name => _ending_point_name;
  List<String> get info => _info;
  String get endingPointPhoto => _endingPointPhoto;
  List<String> get description => _description;
  String get refreshment_point => _refreshment_point;
  bool get pic_nic_area => _pic_nic_area;
  bool get family_firendly => _family_firendly;
  List<String> get challenges => _challenges;

 // Setters
  set name(String value) => _name = value;
  set mapPhoto(String value) => _mapPhoto = value;
  set difficulty_level(String value) => _difficulty_level = value;
  set distance(double value) => _distance = value;
  set estimated_time(double value) => _estimated_time = value;
  set elevation_gain(double value) => _elevation_gain = value;
  set upGain(bool value) => _upGain = value;
  set downGain(bool value) => _downGain = value;
  set starting_point(LatLng value) => _starting_point = value;
  set ending_point(LatLng value) => _ending_point = value;
  set points(List<LatLng> value) => _points = value;
  set starting_point_name(String value) => _starting_point_name = value;
  set ending_point_name(String value) => _ending_point_name = value;
  set info(List<String> value) => _info = value;
  set endingPointPhoto(String value) => _endingPointPhoto = value;
  set description(List<String> value) => _description = value;
  set refreshment_point(String value) => _refreshment_point = value;
  set pic_nic_area(bool value) => _pic_nic_area = value;
  set family_firendly(bool value) => _family_firendly = value;
  set challenges(List<String> value) => _challenges = value;

  // Model --> Firestore
  Map<String, dynamic> toMap() {
    return {
      "Name": _name,
      "Map_photo": _mapPhoto,
      "Difficulty_level": _difficulty_level,
      "Distance": _distance,
      "Estimated_time": _estimated_time,
      "Elevation_gain": _elevation_gain,
      "Up_gain": _upGain,
      "Down_gain": _downGain,
      "Points": _points.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      "Starting_point_name": _starting_point_name,
      "Ending_point_name": _ending_point_name,
      "Info": _info.map((i) => i.toString()).toList(),
      "Photo_ending_point": _endingPointPhoto,
      "Description": _description.map((i) => i.toString()).toList(),
      "Refreshment_point": _refreshment_point,
      "Picnic_area": _pic_nic_area,
      "Family_friendly": _family_firendly,
      "Challenges": _challenges.map((i) => i.toString()).toList(),
    };
  }

  // Firestore --> Model
  factory Trekking.fromMap(Map<String, dynamic> map, {required String docId}) {
    // Convert Firestore GeoPoint to LatLng
    //List<LatLng> pts = (map["Points"] as List<dynamic>)
    //  .map((p) => LatLng((p as GeoPoint).latitude, p.longitude))
    //  .toList();


    final pts = (map["Points"] as List<dynamic>?)
        ?.map((p) => LatLng((p as GeoPoint).latitude, p.longitude))
        .toList() ?? [];

    double _safeDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Create Trekking instance
    return Trekking(
      documentId: docId,
      name: map["Name"] ?? "",
      mapPhoto: map["Map_photo"] ?? "",
      difficultyLevel: map["Difficulty_level"] ?? "",
      //distance: (map["Distance"] ?? 0).toDouble(),
      //estimatedTime: (map["Estimated_time"] ?? 0).toDouble(),
      //elevationGain: (map["Elevation_gain"] ?? 0).toDouble(),
      distance: _safeDouble(map["Distance"]),
      estimatedTime: _safeDouble(map["Estimated_time"]),
      elevationGain: _safeDouble(map["Elevation_gain"]),
      upGain: map["Up_gain"] ?? false,
      downGain: map["Down_gain"] ?? false,
      startingPoint: pts.isNotEmpty ? pts.first : const LatLng(0,0),
      endingPoint: pts.isNotEmpty ? pts.last : const LatLng(0,0),
      points: pts,
      startingPointName: map["Starting_point_name"] ?? "",
      endingPointName: map["Ending_point_name"] ?? "",
      info: (map["Info"] as List?)?.map((e)=>e.toString()).toList() ?? [],
      endingPointPhoto: map["Photo_ending_point"] ?? "",
      description: (map["Description"] as List?)?.map((e)=>e.toString()).toList() ?? [],
      refreshmentPoint: map["Refreshment_point"] ?? "",
      picNicArea: map["Picnic_area"] ?? false,
      familyFirendly: map["Family_friendly"] ?? false,
      challenges: (map["Challenges"] as List?)?.map((e)=>e.toString()).toList() ?? [],
    );
  }
}
