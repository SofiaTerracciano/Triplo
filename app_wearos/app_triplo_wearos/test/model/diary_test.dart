import 'package:app_triplo_wearos/model/diary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper per creare un diary base
  Diary makeDiary({
    String diaryId = 'diary1',
    String userId = 'user1',
    String trekkingName = 'Monte Rosa',
    String date = '2024-06-01',
    double duration = 3.5,
    List<String>? friends,
    List<String>? challenges,
    bool isPublic = true,
  }) {
    return Diary(
      diaryId: diaryId,
      userId: userId,
      trekkigName: trekkingName,
      date: date,
      duration: duration,
      friends: friends ?? [],
      challenges: challenges ?? [],
      isPublic: isPublic,
    );
  }

  group('Diary - costruttore e getter', () {
    test('crea diary con valori corretti', () {
      final diary = makeDiary();
      expect(diary.diaryId, 'diary1');
      expect(diary.userId, 'user1');
      expect(diary.trekkigName, 'Monte Rosa');
      expect(diary.date, '2024-06-01');
      expect(diary.duration, 3.5);
      expect(diary.isPublic, true);
    });

    test('liste vuote di default', () {
      final diary = makeDiary();
      expect(diary.friends, isEmpty);
      expect(diary.challenges, isEmpty);
    });

    test('crea diary privato', () {
      final diary = makeDiary(isPublic: false);
      expect(diary.isPublic, false);
    });

    test('crea diary con amici e sfide', () {
      final diary = makeDiary(
        friends: ['user2', 'user3'],
        challenges: ['challenge1'],
      );
      expect(diary.friends, ['user2', 'user3']);
      expect(diary.challenges, ['challenge1']);
    });
  });

  group('Diary - toMap', () {
    test('toMap contiene tutti i campi', () {
      final diary = makeDiary();
      final map = diary.toMap();
      expect(map['UserId'], 'user1');
      expect(map['Trekking_name'], 'Monte Rosa');
      expect(map['Date'], '2024-06-01');
      expect(map['Duration'], 3.5);
      expect(map['Is_public'], true);
      expect(map['Friends'], isEmpty);
      expect(map['Challenges'], isEmpty);
    });

    test('toMap serializza friends e challenges', () {
      final diary = makeDiary(
        friends: ['user2', 'user3'],
        challenges: ['challenge1', 'challenge2'],
      );
      final map = diary.toMap();
      expect(map['Friends'], ['user2', 'user3']);
      expect(map['Challenges'], ['challenge1', 'challenge2']);
    });

    test('toMap non include diaryId', () {
      final diary = makeDiary();
      final map = diary.toMap();
      expect(map.containsKey('diaryId'), false);
    });
  });

  group('Diary - fromMap', () {
    test('fromMap crea diary con campi base', () {
      final map = {
        'UserId': 'user1',
        'Trekking_name': 'Monte Rosa',
        'Date': '2024-06-01',
        'Duration': 3.5,
        'Friends': ['user2'],
        'Challenges': ['challenge1'],
        'Is_public': true,
      };
      final diary = Diary.fromMap(map, diaryId: 'diary1');
      expect(diary.diaryId, 'diary1');
      expect(diary.userId, 'user1');
      expect(diary.trekkigName, 'Monte Rosa');
      expect(diary.date, '2024-06-01');
      expect(diary.duration, 3.5);
      expect(diary.isPublic, true);
      expect(diary.friends, ['user2']);
      expect(diary.challenges, ['challenge1']);
    });

    test('fromMap gestisce campi mancanti con valori di default', () {
      final diary = Diary.fromMap({}, diaryId: 'diary2');
      expect(diary.userId, '');
      expect(diary.trekkigName, 'Unknown Trek');
      expect(diary.date, '');
      expect(diary.duration, 0.0);
      expect(diary.isPublic, false);
      expect(diary.friends, isEmpty);
      expect(diary.challenges, isEmpty);
    });

    test('fromMap converte challenges da List<dynamic> a List<String>', () {
      final map = {
        'Challenges': [1, 2, 3],
      };
      final diary = Diary.fromMap(map, diaryId: 'diary3');
      expect(diary.challenges, ['1', '2', '3']);
    });

    test('fromMap gestisce duration come int', () {
      final map = {'Duration': 2};
      final diary = Diary.fromMap(map, diaryId: 'diary4');
      expect(diary.duration, 2.0);
    });
  });
}