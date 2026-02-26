// Diary model
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
  List<String> mood;
  String notes;
  bool isPublic;

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
    required this.isPublic,
  });

  // Model --> Firestore
  Map<String, dynamic> toMap() {
    return {
      "UserId": userId,
      "Trekking_name": trekkigName,
      "Date": date,
      "Duration": duration,
      "Friends": friends,
      "Photos": photos,
      "Challenges": challenges,
      "Refreshment_point": refreshmentPoint,
      "Mood": mood,
      "Notes": notes,
      "Is_public": isPublic,
    };
  }

  // Firestore --> Model
  factory Diary.fromMap(Map<String, dynamic> map, {required String diaryId}) {
    // Convert List<dynamic> to List<String> for photos
    final List<String>  photos = (map["Photos"] as List<dynamic>?)
        ?.map((item) => item.toString())
        .toList()
        ?? [];

    // Convert List<dynamic> to List<String> for challenges
    final List<String>  challenges = (map["Challenges"] as List<dynamic>?)
        ?.map((item) => item.toString())
        .toList()
        ?? [];

    // Convert List<dynamic> to List<String> for mood
    final List<String>  mood = (map["Mood"] as List<dynamic>?)
        ?.map((item) => item.toString())
        .toList()
        ?? [];

    // Return the Diary instance
    return Diary(
      diaryId: diaryId,
      userId: map["UserId"] ?? "",
      trekkigName: map["Trekking_name"] ?? "Unknown Trek",
      date: map["Date"] ?? "",
      duration: (map["Duration"] ?? 0).toDouble(),
      friends: List<String>.from(map["Friends"] ?? []),
      photos: photos,
      challenges: challenges,
      refreshmentPoint: map["Refreshment_point"] ?? "",
      mood: mood,
      notes: map["Notes"] ?? "",
      isPublic: map["Is_public"] ?? false,
    );
  }
}