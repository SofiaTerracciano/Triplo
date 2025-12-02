import 'user.dart';
import 'trekking.dart';

class Diary {
  final String diaryId;

  String userId;
  String trekkigName;
  String date;
  double duration;
  List<String> friends;
  List<String> photos;
  List<String> challenges;
  String refreshmentPoint;
  String mood;
  String notes;

  Diary({
    required this.diaryId,
    required this.userId,
    required this.trekkigName,
    required this.date,
    required this.duration,
    required this.friends,
    required this.photos,
    required this.challenges,
    required this.refreshmentPoint,
    required this.mood,
    required this.notes,
  });

  // SERIALIZZAZIONE
  Map<String, dynamic> toMap() {
    return {
      "UserId": userId,
      "RouteId": trekkigName,
      "Date": date, // la metteremo noi il giusto layout
      "Duration": duration,
      "Friends": friends,
      "Photos": photos,
      "Challenges": challenges,
      "Refreshment_point": refreshmentPoint,
      "Mood": mood,
      "Notes": notes,
    };
  }
  /*
  factory Diary.fromMap(Map<String, dynamic> map, {required String diaryId}) {
    return Diary(
      diaryId: diaryId,
      routeId: map["RouteId"],               // solo ID del trekking
      date: DateTime.parse(map["Date"]),
      duration: (map["Duration"] as num).toDouble(),
      friends: List<String>.from(map["Friends"] ?? []),
      photos: List<String>.from(map["Photos"]),
      challenges: List<String>.from(map["Challenges"]),
      refreshmentPoint: map["Refreshment_point"],
      mood: map["Mood"],
      notes: map["Notes"],
    );
  }
 */

  factory Diary.fromMap(Map<String, dynamic> map, {required String diaryId}) {
    return Diary(
      diaryId: diaryId,
      userId: map["UserId"],
      trekkigName: map["Trekking_name"],
      date: map["Date"],
      duration: (map["Duration"] as num).toDouble(),
      friends: List<String>.from(map["Friends"] ?? []),
      photos: List<String>.from(map["Photos"] ?? []),
      challenges: List<String>.from(map["Challenges"] ?? []),
      refreshmentPoint: map["Refreshment_point"] ?? "",
      mood: map["Mood"] ?? "",
      notes: map["Notes"] ?? "",
    );
  }
}
