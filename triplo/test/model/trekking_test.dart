import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triplo/model/trekking.dart';

void main() {
  group('Trekking full coverage tests', () {
    // Lista punti e valori iniziali
    final points = [LatLng(45.0, 7.0), LatLng(45.1, 7.1)];
    final challenges = ['Rock Climbing', 'River Crossing'];
    final info = ['Beautiful view', 'Moderate difficulty'];
    final description = ['Start at parking', 'Follow trail'];

    test('Constructor, getters and setters', () {
      // Costruttore completo
      final trekking = Trekking(
        documentId: 'doc1',
        name: 'Trail One',
        mapPhoto: 'map_photo.png',
        difficultyLevel: 'Medium',
        distance: 10.5,
        estimatedTime: 3.0,
        elevationGain: 500,
        upGain: true,
        downGain: true,
        startingPoint: points.first,
        endingPoint: points.last,
        points: points,
        startingPointName: 'Start',
        endingPointName: 'End',
        info: info,
        endingPointPhoto: 'end_photo.png',
        description: description,
        refreshmentPoint: 'Cafe',
        picNicArea: true,
        familyFirendly: false,
        challenges: challenges,
      );

      // Test getter
      expect(trekking.name, 'Trail One');
      expect(trekking.distance, 10.5);
      expect(trekking.upGain, true);
      expect(trekking.points, points);

      // Test setter
      trekking.name = 'New Trail';
      trekking.distance = 12.0;
      trekking.upGain = false;
      trekking.points = [LatLng(46.0, 8.0)];

      expect(trekking.name, 'New Trail');
      expect(trekking.distance, 12.0);
      expect(trekking.upGain, false);
      expect(trekking.points, [LatLng(46.0, 8.0)]);
    });

    test('toMap returns correct Firestore map', () {
      final trekking = Trekking(
        documentId: 'doc2',
        name: 'Trail Two',
        mapPhoto: 'map2.png',
        difficultyLevel: 'Hard',
        distance: 15.0,
        estimatedTime: 5.0,
        elevationGain: 800,
        upGain: true,
        downGain: false,
        startingPoint: points.first,
        endingPoint: points.last,
        points: points,
        startingPointName: 'Start2',
        endingPointName: 'End2',
        info: info,
        endingPointPhoto: 'end2.png',
        description: description,
        refreshmentPoint: 'Bar',
        picNicArea: false,
        familyFirendly: true,
        challenges: challenges,
      );

      final map = trekking.toMap();

      // Tutti i campi convertiti in map
      expect(map['Name'], trekking.name);
      expect(map['Map_photo'], trekking.mapPhoto);
      expect(map['Difficulty_level'], trekking.difficulty_level);
      expect(map['Distance'], trekking.distance);
      expect(map['Estimated_time'], trekking.estimated_time);
      expect(map['Elevation_gain'], trekking.elevation_gain);
      expect(map['Up_gain'], trekking.upGain);
      expect(map['Down_gain'], trekking.downGain);
      expect(map['Points'], isA<List<GeoPoint>>());
      expect(map['Starting_point_name'], trekking.starting_point_name);
      expect(map['Ending_point_name'], trekking.ending_point_name);
      expect(map['Info'], trekking.info);
      expect(map['Photo_ending_point'], trekking.endingPointPhoto);
      expect(map['Description'], trekking.description);
      expect(map['Refreshment_point'], trekking.refreshment_point);
      expect(map['Picnic_area'], trekking.pic_nic_area);
      expect(map['Family_friendly'], trekking.family_firendly);
      expect(map['Challenges'], trekking.challenges);
    });

    test('fromMap parses all fields correctly including nulls', () {
      // Mappa completa
      final mapFull = {
        "Name": 'Trail Three',
        "Map_photo": 'map3.png',
        "Difficulty_level": 'Easy',
        "Distance": 8.5,
        "Estimated_time": 2.5,
        "Elevation_gain": 200,
        "Up_gain": false,
        "Down_gain": true,
        "Points": [GeoPoint(45.2, 7.2), GeoPoint(45.3, 7.3)],
        "Starting_point_name": 'Start3',
        "Ending_point_name": 'End3',
        "Info": ['InfoA', 'InfoB'],
        "Photo_ending_point": 'end3.png',
        "Description": ['DescA', 'DescB'],
        "Refreshment_point": 'None',
        "Picnic_area": true,
        "Family_friendly": true,
        "Challenges": ['ChallengeA']
      };

      final tFull = Trekking.fromMap(mapFull, docId: 'docFull');
      expect(tFull.name, 'Trail Three');
      expect(tFull.distance, 8.5);
      expect(tFull.upGain, false);
      expect(tFull.points.first.latitude, 45.2);

      // Mappa vuota per coprire i default ?? []
      final mapEmpty = <String, dynamic>{};
      final tEmpty = Trekking.fromMap(mapEmpty, docId: 'docEmpty');

      expect(tEmpty.name, '');
      expect(tEmpty.distance, 0.0);
      expect(tEmpty.upGain, false);
      expect(tEmpty.points, []);
      expect(tEmpty.challenges, []);
      expect(tEmpty.refreshment_point, '');
    });

    test('fromMap handles numeric strings', () {
      final mapStrNumbers = {
        "Distance": '12.5',
        "Estimated_time": '4.0',
        "Elevation_gain": '300',
        "Points": [GeoPoint(45.5, 7.5)]
      };

      final t = Trekking.fromMap(mapStrNumbers, docId: 'docStr');
      expect(t.distance, 12.5);
      expect(t.estimated_time, 4.0);
      expect(t.elevation_gain, 300.0);
      expect(t.points.first.latitude, 45.5);
    });
  });
}