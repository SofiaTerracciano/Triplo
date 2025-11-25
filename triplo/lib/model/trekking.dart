import 'package:latlong2/latlong.dart';

class Trekking {
  final String documentId;

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
  String _refreshment_point;
  bool _pic_nic_area;
  bool _family_firendly;

  Trekking({
    required this.documentId,
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

  // Getters
  String get name => _name;
  String get difficulty_level => _difficulty_level; 
  double get distance => _distance;
  double get estimated_time => _estimated_time;
  double get elevation_gain => _elevation_gain;
  LatLng get starting_point => _starting_point;
  LatLng get ending_point => _ending_point;
  String get starting_point_name => _starting_point_name;
  String get ending_point_name => _ending_point_name;
  String get info => _info;
  String get description => _description;
  String get refreshment_point => _refreshment_point;
  bool get pic_nic_area => _pic_nic_area;
  bool get family_firendly => _family_firendly;

  // Mappa → Firestore
  Map<String, dynamic> toMap() {
    return {
      "Name": _name,
      "Difficulty_level": _difficulty_level,
      "Distance": _distance,
      "Estimated_time": _estimated_time,
      "Elevation_gain": _elevation_gain,
      "Starting_point": {
        "Latitudine": _starting_point.latitude,
        "Longitudine": _starting_point.longitude,
      },
      "Ending_point": {
        "Latitudine": _ending_point.latitude,
        "Longitudine": _ending_point.longitude,
      },
      "Starting_point_name": _starting_point_name,
      "Ending_point_name": _ending_point_name,
      "Info": _info,
      "Description": _description,
      "Refreshment_point": _refreshment_point,
      "Picnic_area": _pic_nic_area,
      "Family_friendly": _family_firendly,
    };
  }

  // Firestore → Model
  factory Trekking.fromMap(Map<String, dynamic> map, {required String docId}) {
    return Trekking(
      documentId: docId,
      name: map["Name"],
      difficultyLevel: map["Difficulty_level"],
      distance: (map["Distance"] as num).toDouble(),
      estimatedTime: (map["Estimated_time"] as num).toDouble(),
      elevationGain: (map["Elevation_gain"] as num).toDouble(),
      startingPoint: LatLng(
        map["Starting_point"]["Latitudine"],
        map["Starting_point"]["Longitudine"],
      ),
      endingPoint: LatLng(
        map["Ending_point"]["Latitudine"],
        map["Ending_point"]["Longitudine"],
      ),
      startingPointName: map["Starting_point_name"],
      endingPointName: map["Ending_point_name"],
      info: map["Info"],
      description: map["Description"],
      refreshmentPoint: map["Refreshment_point"],
      picNicArea: map["Picnic_area"],
      familyFirendly: map["Family_friendly"],
    );
  }
}
