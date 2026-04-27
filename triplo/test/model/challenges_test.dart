import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/model/challenges.dart';

Challenges buildChallenges({
  String documentId = 'challenge_1',
  List<String>? title,
  List<String>? description,
  String photo = 'https://example.com/challenge.jpg',
}) {
  return Challenges(
    documentId: documentId,
    title: title ?? ['Titolo IT', 'Title EN'],
    description: description ?? ['Descrizione IT', 'Description EN'],
    photo: photo,
  );
}

Map<String, dynamic> buildFirestoreMap({
  List<String> title = const ['Titolo IT', 'Title EN'],
  List<String> description = const ['Descrizione IT', 'Description EN'],
  String photo = 'https://example.com/challenge.jpg',
}) {
  return {
    'Title': title,
    'Description': description,
    'Photo': photo,
  };
}

void main() {

  group('Constructor & Getters', () {
    test('stores all fields correctly', () {
      final c = buildChallenges();

      expect(c.documentId, 'challenge_1');
      expect(c.title, ['Titolo IT', 'Title EN']);
      expect(c.description, ['Descrizione IT', 'Description EN']);
      expect(c.photo, 'https://example.com/challenge.jpg');
    });

    test('accepts empty title list', () {
      final c = buildChallenges(title: []);
      expect(c.title, isEmpty);
    });

    test('accepts empty description list', () {
      final c = buildChallenges(description: []);
      expect(c.description, isEmpty);
    });

    test('accepts empty photo string', () {
      final c = buildChallenges(photo: '');
      expect(c.photo, '');
    });
  });

  group('Setters', () {
    test('photo setter works', () {
      final c = buildChallenges();
      c.photo = 'https://example.com/new.jpg';
      expect(c.photo, 'https://example.com/new.jpg');
    });

    test('title setter replaces list', () {
      final c = buildChallenges();
      c.title = ['Nuovo Titolo'];
      expect(c.title, ['Nuovo Titolo']);
    });

    test('description setter replaces list', () {
      final c = buildChallenges();
      c.description = ['Nuova Descrizione'];
      expect(c.description, ['Nuova Descrizione']);
    });

    test('title setter accepts empty list', () {
      final c = buildChallenges();
      c.title = [];
      expect(c.title, isEmpty);
    });

    test('description setter accepts empty list', () {
      final c = buildChallenges();
      c.description = [];
      expect(c.description, isEmpty);
    });
  });

  group('toMap()', () {
    test('produces correct keys and values', () {
      final c = buildChallenges();
      final map = c.toMap();

      expect(map['Title'], ['Titolo IT', 'Title EN']);
      expect(map['Photo'], 'https://example.com/challenge.jpg');
      expect(map['Description'], ['Descrizione IT', 'Description EN']);
    });

    test('documentId is NOT included in toMap output', () {
      final c = buildChallenges();
      final map = c.toMap();
      expect(map.containsKey('documentId'), isFalse);
      expect(map.containsKey('DocumentId'), isFalse);
    });

    test('description key is "Description"', () {
      final c = buildChallenges();
      final map = c.toMap();

      expect(map.containsKey('Description'), isTrue);
      expect(map.containsKey('Descrption'), isFalse);
    });

    test('empty title serializes to empty list', () {
      final c = buildChallenges(title: []);
      expect(c.toMap()['Title'], isEmpty);
    });

    test('empty description serializes to empty list', () {
      final c = buildChallenges(description: []);
      expect(c.toMap()['Description'], isEmpty);
    });

    test('photo serializes correctly', () {
      final c = buildChallenges(photo: '');
      expect(c.toMap()['Photo'], '');
    });
  });

  group('fromMap()', () {
    test('parses all fields correctly', () {
      final c = Challenges.fromMap(buildFirestoreMap(), docId: 'challenge_1');

      expect(c.documentId, 'challenge_1');
      expect(c.title, ['Titolo IT', 'Title EN']);
      expect(c.description, ['Descrizione IT', 'Description EN']);
      expect(c.photo, 'https://example.com/challenge.jpg');
    });

    test('defaults photo to empty string when missing', () {
      final map = buildFirestoreMap();
      map.remove('Photo');
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.photo, '');
    });

    test('defaults title to empty list when null', () {
      final map = buildFirestoreMap();
      map['Title'] = null;
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.title, isEmpty);
    });

    test('defaults description to empty list when null', () {
      final map = buildFirestoreMap();
      map['Description'] = null;
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.description, isEmpty);
    });

    test('defaults title to empty list when missing', () {
      final map = buildFirestoreMap();
      map.remove('Title');
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.title, isEmpty);
    });

    test('defaults description to empty list when missing', () {
      final map = buildFirestoreMap();
      map.remove('Description');
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.description, isEmpty);
    });

    test('converts dynamic items to String for title', () {
      final map = buildFirestoreMap();
      map['Title'] = [42, true, 'Testo'];
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.title, ['42', 'true', 'Testo']);
    });

    test('converts dynamic items to String for description', () {
      final map = buildFirestoreMap();
      map['Description'] = [99, false, 'Descrizione'];
      final c = Challenges.fromMap(map, docId: 'challenge_1');
      expect(c.description, ['99', 'false', 'Descrizione']);
    });
  });

  group('Round-trip toMap() → fromMap()', () {
    test('title and photo survive round-trip', () {
      final original = buildChallenges(
        title: ['Titolo IT', 'Title EN'],
        photo: 'https://example.com/photo.jpg',
      );

      final map = original.toMap();
      final restored = Challenges.fromMap(map, docId: original.documentId);

      expect(restored.documentId, original.documentId);
      expect(restored.title, original.title);
      expect(restored.photo, original.photo);
    });

    test('description survives round-trip', () {
      final original = buildChallenges(description: ['Descrizione IT']);
      final map = original.toMap();
      final restored = Challenges.fromMap(map, docId: original.documentId);

      expect(restored.description, original.description);
    });
  });
}