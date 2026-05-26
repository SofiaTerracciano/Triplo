import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  // ─── Helpers ────────────────────────────────────────────────────────────────

  Trekking buildTrekking({
    String documentId = 'doc1',
    String name = 'Monte Bello',
    String mapPhoto = 'https://example.com/map.jpg',
    String difficultyLevel = 'Medium',
    double distance = 12.5,
    double estimatedTime = 4.5,
    double elevationGain = 800.0,
    bool upGain = true,
    bool downGain = false,
    LatLng? startingPoint,
    LatLng? endingPoint,
    List<LatLng>? points,
    String startingPointName = 'Rifugio Alpino',
    String endingPointName = 'Vetta',
    List<String> info = const ['Portare acqua', 'Bastoncini consigliati'],
    String endingPointPhoto = 'https://example.com/summit.jpg',
    List<String> description = const ['Un bellissimo percorso.'],
    String? refreshmentPoint,
    bool picNicArea = true,
    bool familyFriendly = false,
    List<String>? challenges,
  }) {
    final start = startingPoint ?? const LatLng(45.0, 9.0);
    final end = endingPoint ?? const LatLng(45.1, 9.1);
    return Trekking(
      documentId: documentId,
      name: name,
      mapPhoto: mapPhoto,
      difficultyLevel: difficultyLevel,
      distance: distance,
      estimatedTime: estimatedTime,
      elevationGain: elevationGain,
      upGain: upGain,
      downGain: downGain,
      startingPoint: start,
      endingPoint: end,
      points: points ?? [start, const LatLng(45.05, 9.05), end],
      startingPointName: startingPointName,
      endingPointName: endingPointName,
      info: info,
      endingPointPhoto: endingPointPhoto,
      description: description,
      refreshmentPoint: refreshmentPoint,
      picNicArea: picNicArea,
      familyFirendly: familyFriendly,
      challenges: challenges,
    );
  }

  // ─── Constructor & Getters ──────────────────────────────────────────────────

  group('Constructor & Getters', () {
    test('stores all required fields correctly', () {
      final t = buildTrekking();

      expect(t.documentId, 'doc1');
      expect(t.name, 'Monte Bello');
      expect(t.mapPhoto, 'https://example.com/map.jpg');
      expect(t.difficulty_level, 'Medium');
      expect(t.distance, 12.5);
      expect(t.estimated_time, 4.5);
      expect(t.elevation_gain, 800.0);
      expect(t.upGain, isTrue);
      expect(t.downGain, isFalse);
      expect(t.starting_point, const LatLng(45.0, 9.0));
      expect(t.ending_point, const LatLng(45.1, 9.1));
      expect(t.starting_point_name, 'Rifugio Alpino');
      expect(t.ending_point_name, 'Vetta');
      expect(t.info, ['Portare acqua', 'Bastoncini consigliati']);
      expect(t.endingPointPhoto, 'https://example.com/summit.jpg');
      expect(t.description, ['Un bellissimo percorso.']);
      expect(t.pic_nic_area, isTrue);
      expect(t.family_firendly, isFalse);
    });

    test('refreshment_point defaults to empty string when null', () {
      final t = buildTrekking(refreshmentPoint: null);
      expect(t.refreshment_point, '');
    });

    test('refreshment_point is set when provided', () {
      final t = buildTrekking(refreshmentPoint: 'Bar del Lago');
      expect(t.refreshment_point, 'Bar del Lago');
    });

    test('challenges defaults to empty list when null', () {
      final t = buildTrekking(challenges: null);
      expect(t.challenges, isEmpty);
    });

    test('challenges is set when provided', () {
      final t = buildTrekking(challenges: ['Tratto esposto', 'Ghiaccio possibile']);
      expect(t.challenges, ['Tratto esposto', 'Ghiaccio possibile']);
    });

    test('points list is stored correctly', () {
      final pts = [
        const LatLng(45.0, 9.0),
        const LatLng(45.05, 9.05),
        const LatLng(45.1, 9.1),
      ];
      final t = buildTrekking(points: pts);
      expect(t.points, pts);
      expect(t.points.length, 3);
    });
  });

  // ─── Setters ────────────────────────────────────────────────────────────────

  group('Setters', () {
    test('name setter updates the name', () {
      final t = buildTrekking();
      t.name = 'Lago Azzurro';
      expect(t.name, 'Lago Azzurro');
    });

    test('difficulty_level setter works', () {
      final t = buildTrekking();
      t.difficulty_level = 'advanced';
      expect(t.difficulty_level, 'advanced');
    });

    test('distance setter works', () {
      final t = buildTrekking();
      t.distance = 20.0;
      expect(t.distance, 20.0);
    });

    test('estimated_time setter works', () {
      final t = buildTrekking();
      t.estimated_time = 6.0;
      expect(t.estimated_time, 6.0);
    });

    test('elevation_gain setter works', () {
      final t = buildTrekking();
      t.elevation_gain = 1200.0;
      expect(t.elevation_gain, 1200.0);
    });

    test('upGain and downGain setters work', () {
      final t = buildTrekking(upGain: true, downGain: false);
      t.upGain = false;
      t.downGain = true;
      expect(t.upGain, isFalse);
      expect(t.downGain, isTrue);
    });

    test('starting_point setter works', () {
      final t = buildTrekking();
      t.starting_point = const LatLng(46.0, 10.0);
      expect(t.starting_point, const LatLng(46.0, 10.0));
    });

    test('ending_point setter works', () {
      final t = buildTrekking();
      t.ending_point = const LatLng(46.5, 10.5);
      expect(t.ending_point, const LatLng(46.5, 10.5));
    });

    test('points setter replaces the list', () {
      final t = buildTrekking();
      final newPoints = [const LatLng(1.0, 1.0), const LatLng(2.0, 2.0)];
      t.points = newPoints;
      expect(t.points, newPoints);
    });

    test('info setter replaces the list', () {
      final t = buildTrekking();
      t.info = ['Nuova info'];
      expect(t.info, ['Nuova info']);
    });

    test('description setter replaces the list', () {
      final t = buildTrekking();
      t.description = ['Descrizione aggiornata.'];
      expect(t.description, ['Descrizione aggiornata.']);
    });

    test('challenges setter replaces the list', () {
      final t = buildTrekking();
      t.challenges = ['Valanga'];
      expect(t.challenges, ['Valanga']);
    });

    test('pic_nic_area setter works', () {
      final t = buildTrekking(picNicArea: false);
      t.pic_nic_area = true;
      expect(t.pic_nic_area, isTrue);
    });

    test('family_firendly setter works', () {
      final t = buildTrekking(familyFriendly: false);
      t.family_firendly = true;
      expect(t.family_firendly, isTrue);
    });

    test('refreshment_point setter works', () {
      final t = buildTrekking();
      t.refreshment_point = 'Chiosco della vetta';
      expect(t.refreshment_point, 'Chiosco della vetta');
    });

    test('mapPhoto setter works', () {
      final t = buildTrekking();
      t.mapPhoto = 'https://example.com/newmap.jpg';
      expect(t.mapPhoto, 'https://example.com/newmap.jpg');
    });

    test('endingPointPhoto setter works', () {
      final t = buildTrekking();
      t.endingPointPhoto = 'https://example.com/newphoto.jpg';
      expect(t.endingPointPhoto, 'https://example.com/newphoto.jpg');
    });
  });

  // ─── toMap() ────────────────────────────────────────────────────────────────

  group('toMap()', () {
    test('produces correct keys and scalar values', () {
      final t = buildTrekking();
      final map = t.toMap();

      expect(map['Name'], 'Monte Bello');
      expect(map['Map_photo'], 'https://example.com/map.jpg');
      expect(map['Difficulty_level'], 'Medium');
      expect(map['Distance'], 12.5);
      expect(map['Estimated_time'], 4.5);
      expect(map['Elevation_gain'], 800.0);
      expect(map['Up_gain'], isTrue);
      expect(map['Down_gain'], isFalse);
      expect(map['Starting_point_name'], 'Rifugio Alpino');
      expect(map['Ending_point_name'], 'Vetta');
      expect(map['Photo_ending_point'], 'https://example.com/summit.jpg');
      expect(map['Refreshment_point'], '');
      expect(map['Picnic_area'], isTrue);
      expect(map['Family_friendly'], isFalse);
    });

    test('converts points to List<GeoPoint>', () {
      final t = buildTrekking();
      final map = t.toMap();
      final points = map['Points'] as List;

      expect(points, isNotEmpty);
      expect(points.every((p) => p is GeoPoint), isTrue);
      expect((points.first as GeoPoint).latitude, 45.0);
      expect((points.first as GeoPoint).longitude, 9.0);
    });

    test('Info list is serialized as List<String>', () {
      final t = buildTrekking();
      final map = t.toMap();
      final info = map['Info'] as List;
      expect(info.every((e) => e is String), isTrue);
    });

    test('Description list is serialized as List<String>', () {
      final t = buildTrekking();
      final map = t.toMap();
      final desc = map['Description'] as List;
      expect(desc.every((e) => e is String), isTrue);
    });

    test('Challenges list is serialized correctly', () {
      final t = buildTrekking(challenges: ['Tratto esposto']);
      final map = t.toMap();
      expect(map['Challenges'], ['Tratto esposto']);
    });

    test('empty challenges serializes to empty list', () {
      final t = buildTrekking(challenges: null);
      final map = t.toMap();
      expect(map['Challenges'], isEmpty);
    });
  });

  // ─── fromMap() ──────────────────────────────────────────────────────────────

  group('fromMap()', () {
    Map<String, dynamic> buildFirestoreMap({
      String name = 'Monte Bello',
      String mapPhoto = 'https://example.com/map.jpg',
      String difficultyLevel = 'Medium',
      double distance = 12.5,
      double estimatedTime = 4.5,
      double elevationGain = 800.0,
      bool upGain = true,
      bool downGain = false,
      List<GeoPoint>? points,
      String startingPointName = 'Rifugio Alpino',
      String endingPointName = 'Vetta',
      List<String> info = const ['Info 1'],
      String endingPointPhoto = 'https://example.com/summit.jpg',
      List<String> description = const ['Descrizione.'],
      String refreshmentPoint = '',
      bool picnicArea = true,
      bool familyFriendly = false,
      List<String> challenges = const [],
    }) {
      return {
        'Name': name,
        'Map_photo': mapPhoto,
        'Difficulty_level': difficultyLevel,
        'Distance': distance,
        'Estimated_time': estimatedTime,
        'Elevation_gain': elevationGain,
        'Up_gain': upGain,
        'Down_gain': downGain,
        'Points': points ??
            [const GeoPoint(45.0, 9.0), const GeoPoint(45.05, 9.05), const GeoPoint(45.1, 9.1)],
        'Starting_point_name': startingPointName,
        'Ending_point_name': endingPointName,
        'Info': info,
        'Photo_ending_point': endingPointPhoto,
        'Description': description,
        'Refreshment_point': refreshmentPoint,
        'Picnic_area': picnicArea,
        'Family_friendly': familyFriendly,
        'Challenges': challenges,
      };
    }

    test('parses all scalar fields correctly', () {
      final t = Trekking.fromMap(buildFirestoreMap(), docId: 'doc1');

      expect(t.documentId, 'doc1');
      expect(t.name, 'Monte Bello');
      expect(t.mapPhoto, 'https://example.com/map.jpg');
      expect(t.difficulty_level, 'Medium');
      expect(t.distance, 12.5);
      expect(t.estimated_time, 4.5);
      expect(t.elevation_gain, 800.0);
      expect(t.upGain, isTrue);
      expect(t.downGain, isFalse);
      expect(t.starting_point_name, 'Rifugio Alpino');
      expect(t.ending_point_name, 'Vetta');
      expect(t.endingPointPhoto, 'https://example.com/summit.jpg');
      expect(t.refreshment_point, '');
      expect(t.pic_nic_area, isTrue);
      expect(t.family_firendly, isFalse);
    });

    test('converts GeoPoint list to LatLng correctly', () {
      final t = Trekking.fromMap(buildFirestoreMap(), docId: 'doc1');

      expect(t.points.length, 3);
      expect(t.points.first.latitude, 45.0);
      expect(t.points.first.longitude, 9.0);
      expect(t.starting_point, const LatLng(45.0, 9.0));
      expect(t.ending_point, const LatLng(45.1, 9.1));
    });

    test('parses Info and Description as List<String>', () {
      final t = Trekking.fromMap(
        buildFirestoreMap(info: ['Portare acqua'], description: ['Trekking impegnativo.']),
        docId: 'doc1',
      );
      expect(t.info, ['Portare acqua']);
      expect(t.description, ['Trekking impegnativo.']);
    });

    test('parses Challenges as List<String>', () {
      final t = Trekking.fromMap(
        buildFirestoreMap(challenges: ['Tratto esposto']),
        docId: 'doc1',
      );
      expect(t.challenges, ['Tratto esposto']);
    });

    test('defaults to empty list when Points is null', () {
      final map = buildFirestoreMap()..remove('Points');
      final t = Trekking.fromMap(map, docId: 'doc1');

      expect(t.points, isEmpty);
      expect(t.starting_point, const LatLng(0, 0));
      expect(t.ending_point, const LatLng(0, 0));
    });

    test('defaults to empty list when Info is null', () {
      final map = buildFirestoreMap();
      map['Info'] = null;
      final t = Trekking.fromMap(map, docId: 'doc1');
      expect(t.info, isEmpty);
    });

    test('defaults to empty list when Description is null', () {
      final map = buildFirestoreMap();
      map['Description'] = null;
      final t = Trekking.fromMap(map, docId: 'doc1');
      expect(t.description, isEmpty);
    });

    test('defaults to empty list when Challenges is null', () {
      final map = buildFirestoreMap();
      map['Challenges'] = null;
      final t = Trekking.fromMap(map, docId: 'doc1');
      expect(t.challenges, isEmpty);
    });

    test('handles missing optional fields with defaults', () {
      final map = buildFirestoreMap();
      map.remove('Refreshment_point');
      map.remove('Picnic_area');
      map.remove('Family_friendly');
      final t = Trekking.fromMap(map, docId: 'doc1');

      expect(t.refreshment_point, '');
      expect(t.pic_nic_area, isFalse);
      expect(t.family_firendly, isFalse);
    });

    test('_safeDouble handles int values', () {
      final map = buildFirestoreMap(distance: 10, estimatedTime: 3, elevationGain: 500);
      // Pass them as int to simulate Firestore storing integers
      map['Distance'] = 10;
      map['Estimated_time'] = 3;
      map['Elevation_gain'] = 500;
      final t = Trekking.fromMap(map, docId: 'doc1');

      expect(t.distance, 10.0);
      expect(t.estimated_time, 3.0);
      expect(t.elevation_gain, 500.0);
    });

    test('_safeDouble handles String values', () {
      final map = buildFirestoreMap();
      map['Distance'] = '7.5';
      map['Estimated_time'] = '2.0';
      map['Elevation_gain'] = '300.0';
      final t = Trekking.fromMap(map, docId: 'doc1');

      expect(t.distance, 7.5);
      expect(t.estimated_time, 2.0);
      expect(t.elevation_gain, 300.0);
    });

    test('_safeDouble returns 0.0 for invalid string', () {
      final map = buildFirestoreMap();
      map['Distance'] = 'non_un_numero';
      final t = Trekking.fromMap(map, docId: 'doc1');
      expect(t.distance, 0.0);
    });
  });

  // ─── Round-trip (toMap → fromMap) ───────────────────────────────────────────

  group('Round-trip toMap() → fromMap()', () {
    test('full object survives serialization round-trip', () {
      final original = buildTrekking(
        challenges: ['Ghiaccio', 'Vento forte'],
        refreshmentPoint: 'Bar Alpino',
        picNicArea: true,
        familyFriendly: true,
      );

      // toMap produces GeoPoints; fromMap reads GeoPoints — simulate the cycle
      final map = original.toMap();
      final restored = Trekking.fromMap(map, docId: original.documentId);

      expect(restored.documentId, original.documentId);
      expect(restored.name, original.name);
      expect(restored.difficulty_level, original.difficulty_level);
      expect(restored.distance, original.distance);
      expect(restored.estimated_time, original.estimated_time);
      expect(restored.elevation_gain, original.elevation_gain);
      expect(restored.upGain, original.upGain);
      expect(restored.downGain, original.downGain);
      expect(restored.starting_point_name, original.starting_point_name);
      expect(restored.ending_point_name, original.ending_point_name);
      expect(restored.info, original.info);
      expect(restored.description, original.description);
      expect(restored.refreshment_point, original.refreshment_point);
      expect(restored.pic_nic_area, original.pic_nic_area);
      expect(restored.family_firendly, original.family_firendly);
      expect(restored.challenges, original.challenges);
      expect(restored.points.length, original.points.length);
      expect(restored.points.first.latitude, original.points.first.latitude);
      expect(restored.points.last.longitude, original.points.last.longitude);
    });
  });
}