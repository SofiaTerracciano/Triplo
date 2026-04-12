import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/model/diary.dart';

Diary buildDiary({
  String diaryId = 'diary_1',
  String userId = 'uid_1',
  String trekkingName = 'Monte Bello',
  String date = '2024-06-15',
  double duration = 4.5,
  List<String>? friends,
  List<String>? photos,
  List<String>? challenges,
  String refreshmentPoint = 'Bar Alpino',
  List<String>? mood,
  String notes = 'Bellissima giornata!',
  bool isPublic = true,
}) {
  return Diary(
    diaryId: diaryId,
    userId: userId,
    trekkigName: trekkingName,
    date: date,
    duration: duration,
    friends: friends ?? ['Luigi', 'Anna'],
    photos: photos ?? ['https://example.com/photo1.jpg'],
    challenges: challenges ?? ['Tratto esposto'],
    refreshmentPoint: refreshmentPoint,
    mood: mood ?? ['Felice', 'Stanco'],
    notes: notes,
    isPublic: isPublic,
  );
}

Map<String, dynamic> buildFirestoreMap({
  String userId = 'uid_1',
  String trekkingName = 'Monte Bello',
  String date = '2024-06-15',
  double duration = 4.5,
  List<String> friends = const ['Luigi', 'Anna'],
  List<String> photos = const ['https://example.com/photo1.jpg'],
  List<String> challenges = const ['Tratto esposto'],
  String refreshmentPoint = 'Bar Alpino',
  List<String> mood = const ['Felice', 'Stanco'],
  String notes = 'Bellissima giornata!',
  bool isPublic = true,
}) {
  return {
    'UserId': userId,
    'Trekking_name': trekkingName,
    'Date': date,
    'Duration': duration,
    'Friends': friends,
    'Photos': photos,
    'Challenges': challenges,
    'Refreshment_point': refreshmentPoint,
    'Mood': mood,
    'Notes': notes,
    'Is_public': isPublic,
  };
}

void main() {

  group('Constructor & Getters', () {
    test('stores all fields correctly', () {
      final d = buildDiary();

      expect(d.diaryId, 'diary_1');
      expect(d.userId, 'uid_1');
      expect(d.trekkigName, 'Monte Bello');
      expect(d.date, '2024-06-15');
      expect(d.duration, 4.5);
      expect(d.friends, ['Luigi', 'Anna']);
      expect(d.photos, ['https://example.com/photo1.jpg']);
      expect(d.challenges, ['Tratto esposto']);
      expect(d.refreshmentPoint, 'Bar Alpino');
      expect(d.mood, ['Felice', 'Stanco']);
      expect(d.notes, 'Bellissima giornata!');
      expect(d.isPublic, isTrue);
    });

    test('accepts empty lists for friends, photos, challenges, mood', () {
      final d = buildDiary(
        friends: [],
        photos: [],
        challenges: [],
        mood: [],
      );

      expect(d.friends, isEmpty);
      expect(d.photos, isEmpty);
      expect(d.challenges, isEmpty);
      expect(d.mood, isEmpty);
    });

    test('accepts isPublic false', () {
      final d = buildDiary(isPublic: false);
      expect(d.isPublic, isFalse);
    });
  });

  group('Setters', () {
    test('userId setter works', () {
      final d = buildDiary();
      d.userId = 'uid_2';
      expect(d.userId, 'uid_2');
    });

    test('trekkigName setter works', () {
      final d = buildDiary();
      d.trekkigName = 'Lago Azzurro';
      expect(d.trekkigName, 'Lago Azzurro');
    });

    test('date setter works', () {
      final d = buildDiary();
      d.date = '2025-01-01';
      expect(d.date, '2025-01-01');
    });

    test('duration setter works', () {
      final d = buildDiary();
      d.duration = 7.0;
      expect(d.duration, 7.0);
    });

    test('friends setter replaces list', () {
      final d = buildDiary();
      d.friends = ['Marco'];
      expect(d.friends, ['Marco']);
    });

    test('photos setter replaces list', () {
      final d = buildDiary();
      d.photos = ['https://example.com/new.jpg'];
      expect(d.photos, ['https://example.com/new.jpg']);
    });

    test('challenges setter replaces list', () {
      final d = buildDiary();
      d.challenges = ['Neve', 'Vento'];
      expect(d.challenges, ['Neve', 'Vento']);
    });

    test('refreshmentPoint setter works', () {
      final d = buildDiary();
      d.refreshmentPoint = 'Rifugio della Vetta';
      expect(d.refreshmentPoint, 'Rifugio della Vetta');
    });

    test('mood setter replaces list', () {
      final d = buildDiary();
      d.mood = ['Euforico'];
      expect(d.mood, ['Euforico']);
    });

    test('notes setter works', () {
      final d = buildDiary();
      d.notes = 'Note aggiornate';
      expect(d.notes, 'Note aggiornate');
    });

    test('isPublic setter works', () {
      final d = buildDiary(isPublic: true);
      d.isPublic = false;
      expect(d.isPublic, isFalse);
    });
  });

  group('toMap()', () {
    test('produces correct scalar values', () {
      final d = buildDiary();
      final map = d.toMap();

      expect(map['UserId'], 'uid_1');
      expect(map['Trekking_name'], 'Monte Bello');
      expect(map['Date'], '2024-06-15');
      expect(map['Duration'], 4.5);
      expect(map['Refreshment_point'], 'Bar Alpino');
      expect(map['Notes'], 'Bellissima giornata!');
      expect(map['Is_public'], isTrue);
    });

    test('diaryId is NOT included in toMap output', () {
      final d = buildDiary();
      final map = d.toMap();
      expect(map.containsKey('diaryId'), isFalse);
      expect(map.containsKey('DiaryId'), isFalse);
    });

    test('friends list is serialized correctly', () {
      final d = buildDiary(friends: ['Luigi', 'Anna']);
      expect(d.toMap()['Friends'], ['Luigi', 'Anna']);
    });

    test('photos list is serialized correctly', () {
      final d = buildDiary(photos: ['https://example.com/a.jpg']);
      expect(d.toMap()['Photos'], ['https://example.com/a.jpg']);
    });

    test('challenges list is serialized correctly', () {
      final d = buildDiary(challenges: ['Ghiaccio']);
      expect(d.toMap()['Challenges'], ['Ghiaccio']);
    });

    test('mood list is serialized correctly', () {
      final d = buildDiary(mood: ['Stanco', 'Soddisfatto']);
      expect(d.toMap()['Mood'], ['Stanco', 'Soddisfatto']);
    });

    test('empty lists serialize to empty lists', () {
      final d = buildDiary(friends: [], photos: [], challenges: [], mood: []);
      final map = d.toMap();

      expect(map['Friends'], isEmpty);
      expect(map['Photos'], isEmpty);
      expect(map['Challenges'], isEmpty);
      expect(map['Mood'], isEmpty);
    });

    test('isPublic false is serialized correctly', () {
      final d = buildDiary(isPublic: false);
      expect(d.toMap()['Is_public'], isFalse);
    });
  });

  group('fromMap()', () {
    test('parses all scalar fields correctly', () {
      final d = Diary.fromMap(buildFirestoreMap(), diaryId: 'diary_1');

      expect(d.diaryId, 'diary_1');
      expect(d.userId, 'uid_1');
      expect(d.trekkigName, 'Monte Bello');
      expect(d.date, '2024-06-15');
      expect(d.duration, 4.5);
      expect(d.refreshmentPoint, 'Bar Alpino');
      expect(d.notes, 'Bellissima giornata!');
      expect(d.isPublic, isTrue);
    });

    test('parses friends as List<String>', () {
      final d = Diary.fromMap(buildFirestoreMap(), diaryId: 'diary_1');
      expect(d.friends, ['Luigi', 'Anna']);
    });

    test('parses photos as List<String>', () {
      final d = Diary.fromMap(buildFirestoreMap(), diaryId: 'diary_1');
      expect(d.photos, ['https://example.com/photo1.jpg']);
    });

    test('parses challenges as List<String>', () {
      final d = Diary.fromMap(buildFirestoreMap(), diaryId: 'diary_1');
      expect(d.challenges, ['Tratto esposto']);
    });

    test('parses mood as List<String>', () {
      final d = Diary.fromMap(buildFirestoreMap(), diaryId: 'diary_1');
      expect(d.mood, ['Felice', 'Stanco']);
    });

    test('duration parsed from int (Firestore may store int)', () {
      final map = buildFirestoreMap();
      map['Duration'] = 3;
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.duration, 3.0);
      expect(d.duration, isA<double>());
    });

    test('defaults userId to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('UserId');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.userId, '');
    });

    test('defaults trekkigName to "Unknown Trek" when missing', () {
      final map = buildFirestoreMap();
      map.remove('Trekking_name');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.trekkigName, 'Unknown Trek');
    });

    test('defaults date to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Date');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.date, '');
    });

    test('defaults duration to 0.0 when missing', () {
      final map = buildFirestoreMap();
      map.remove('Duration');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.duration, 0.0);
    });

    test('defaults refreshmentPoint to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Refreshment_point');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.refreshmentPoint, '');
    });

    test('defaults notes to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Notes');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.notes, '');
    });

    test('defaults isPublic to false when missing', () {
      final map = buildFirestoreMap();
      map.remove('Is_public');
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.isPublic, isFalse);
    });

    test('defaults photos to empty list when null', () {
      final map = buildFirestoreMap();
      map['Photos'] = null;
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.photos, isEmpty);
    });

    test('defaults challenges to empty list when null', () {
      final map = buildFirestoreMap();
      map['Challenges'] = null;
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.challenges, isEmpty);
    });

    test('defaults mood to empty list when null', () {
      final map = buildFirestoreMap();
      map['Mood'] = null;
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.mood, isEmpty);
    });

    test('defaults friends to empty list when null', () {
      final map = buildFirestoreMap();
      map['Friends'] = null;
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.friends, isEmpty);
    });

    test('converts dynamic list items to String for photos', () {
      final map = buildFirestoreMap();
      map['Photos'] = [123, true, 'foto.jpg'];
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.photos, ['123', 'true', 'foto.jpg']);
    });

    test('converts dynamic list items to String for challenges', () {
      final map = buildFirestoreMap();
      map['Challenges'] = [42, 'Neve'];
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.challenges, ['42', 'Neve']);
    });

    test('converts dynamic list items to String for mood', () {
      final map = buildFirestoreMap();
      map['Mood'] = [true, 'Felice'];
      final d = Diary.fromMap(map, diaryId: 'diary_1');
      expect(d.mood, ['true', 'Felice']);
    });
  });

  group('Round-trip toMap() → fromMap()', () {
    test('all fields survive serialization round-trip', () {
      final original = buildDiary(
        friends: ['Luigi', 'Anna'],
        photos: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        challenges: ['Ghiaccio', 'Vento'],
        mood: ['Felice'],
        isPublic: false,
      );

      final map = original.toMap();
      final restored = Diary.fromMap(map, diaryId: original.diaryId);

      expect(restored.diaryId, original.diaryId);
      expect(restored.userId, original.userId);
      expect(restored.trekkigName, original.trekkigName);
      expect(restored.date, original.date);
      expect(restored.duration, original.duration);
      expect(restored.friends, original.friends);
      expect(restored.photos, original.photos);
      expect(restored.challenges, original.challenges);
      expect(restored.refreshmentPoint, original.refreshmentPoint);
      expect(restored.mood, original.mood);
      expect(restored.notes, original.notes);
      expect(restored.isPublic, original.isPublic);
    });

    test('empty lists survive round-trip', () {
      final original = buildDiary(
        friends: [],
        photos: [],
        challenges: [],
        mood: [],
      );

      final map = original.toMap();
      final restored = Diary.fromMap(map, diaryId: original.diaryId);

      expect(restored.friends, isEmpty);
      expect(restored.photos, isEmpty);
      expect(restored.challenges, isEmpty);
      expect(restored.mood, isEmpty);
    });
  });
}