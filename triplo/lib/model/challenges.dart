class Challenges {
  final String documentId;

  List<String> _title;
  List<String> _description;
  String _photo;

  Challenges({
    required this.documentId,
    required List<String> title,
    required List<String> description,
    required String photo,
  }) : _title = title,
       _description = description,
       _photo = photo;
      

  // Getters
  String get photo => _photo;
  List<String> get title => _title;
  List<String> get description => _description;

 // Setters
  set photo(String value) => _photo = value;
  set title(List<String> value) => _title = value;
  set description(List<String> value) => _description = value;

  // Model --> Firestore
  Map<String, dynamic> toMap() {
    return {
      "Title": _title,
      "Photo": _photo,
      "Descrption": _description,
    };
  }

  // Firestore --> Model
  factory Challenges.fromMap(Map<String, dynamic> map, {required String docId}) {
    // Convert List<dynamic> to List<String> for description
    final List<String>  description = (map["Description"] as List<dynamic>?)
      ?.map((item) => item.toString()) 
      .toList() 
      ?? [];  

    // Convert List<dynamic> to List<String> for description
    final List<String>  title = (map["Title"] as List<dynamic>?)
      ?.map((item) => item.toString()) 
      .toList() 
      ?? []; 


    return Challenges(
      documentId: docId,
      title: title,
      photo: map["Photo"] ?? "",
      description: description,
    );
  }
}
