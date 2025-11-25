import 'user.dart';
import 'trekking.dart';

class Diary {
  final String diaryId;

  String routeId;               // <-- SOLO ID del trekking
  DateTime date;
  double duration;
  List<Users> friends;
  List<String> photos;
  List<String> challenges;
  String refreshmentPoint;
  String mood;
  String notes;

  Diary({
    required this.diaryId,
    required this.routeId,
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
      "RouteId": routeId,
      "Date": date.toIso8601String(),
      "Duration": duration,
      "Friends": friends.map((f) => f.toMap()).toList(),
      "Photos": photos,
      "Challenges": challenges,
      "Refreshment_point": refreshmentPoint,
      "Mood": mood,
      "Notes": notes,
    };
  }

  factory Diary.fromMap(Map<String, dynamic> map, {required String diaryId}) {
    return Diary(
      diaryId: diaryId,
      routeId: map["RouteId"],               // solo ID del trekking
      date: DateTime.parse(map["Date"]),
      duration: (map["Duration"] as num).toDouble(),
      friends: (map["Friends"] as List)
          .map((f) => Users.fromMap(f))
          .toList(),
      photos: List<String>.from(map["Photos"]),
      challenges: List<String>.from(map["Challenges"]),
      refreshmentPoint: map["Refreshment_point"],
      mood: map["Mood"],
      notes: map["Notes"],
    );
  }
}
