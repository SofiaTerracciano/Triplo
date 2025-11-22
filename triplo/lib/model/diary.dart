class Diary {
  String _route; //title of the diary --> route done
  DateTime _date;
  double _estimated_time;
  List _friends;
  String? _photo;
  String? _challengers;
  String _refreshment_point;
  String _mood; 
  String _notes;

  Diary({
    required String route,
    required DateTime date,
    required double estimated_time,
    required List friends,
    String? photo,
    String? challengers,
    required String refreshment_point,
    required String mood,
    required String notes,
  })  : _route = route,
        _date = date,
        _estimated_time = estimated_time,
        _friends = friends,
        _photo = photo,
        _challengers = challengers,
        _refreshment_point = refreshment_point,
        _mood = mood,
        _notes = notes;
  
  // Getters
  String get route => _route;
  DateTime get date => _date;
  double get estimatedTime => _estimated_time;
  List get friends => _friends;
  String? get photo => _photo;
  String? get challengers => _challengers;
  String get refreshmentPoint => _refreshment_point;
  String get mood => _mood;
  String get notes => _notes;

  // Setters
  set route(String route) => _route = route;
  set date(DateTime date) => _date = date;
  set estimatedTime(double estimatedTime) => _estimated_time = estimatedTime;
  set friends(List friends) => _friends = friends;
  set photo(String? photo) => _photo = photo;
  set challengers(String? challengers) => _challengers = challengers;
  set refreshmentPoint(String refreshmentPoint) => _refreshment_point = refreshmentPoint;
  set mood(String mood) => _mood = mood;
  set notes(String notes) => _notes = notes;
}
