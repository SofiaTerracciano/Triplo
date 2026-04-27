import 'dart:async';
import 'package:app_triplo_wearos/pages/UserProfilePage/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/model/user.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/pages/DiaryPage/diary_page.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';

@GenerateMocks([UserController, DiaryController])
import 'diary_page_test.mocks.dart';

Diary makeDiary({
  String diaryId = 'd1',
  String userId = 'u1',
  String trekkigName = 'Monte Rosa',
  String date = '2024-06-15',
  double duration = 90,
  List<String> friends = const [],
  List<String> challenges = const [],
  bool isPublic = true,
}) =>
    Diary(
      diaryId: diaryId,
      userId: userId,
      trekkigName: trekkigName,
      date: date,
      duration: duration,
      friends: friends,
      challenges: challenges,
      isPublic: isPublic,
    );

Users makeUser({
  String uid = 'user-1',
  String username = 'alpinist99',
  String name = 'Mario',
  String surname = 'Rossi',
  String email = 'test@test.com',
  String? photoProfile,
  String level = 'beginner',
  int advanced = 0,
  int intermediate = 0,
}) {
  return Users(
    uid: uid,
    username: username,
    name: name,
    surname: surname,
    email: email,
    birthdate: DateTime(2000, 1, 1),
    photoProfile: photoProfile,
    followers: const [],
    following: const [],
    publicDiaryPages: const [],
    privateDiaryPages: const [],
    savedTrekkings: const [],
    level: level,
    advanced: advanced,
    intermediate: intermediate,
  );
}

Widget buildTestApp({
  required MockUserController mockUserCtrl,
  required MockDiaryController mockDiaryCtrl,
  required Widget home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserController>.value(value: mockUserCtrl),
      ChangeNotifierProvider<DiaryController>.value(value: mockDiaryCtrl),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Future<void> pumpDiaryPage(
  WidgetTester tester,
  MockUserController mockUserCtrl,
  Diary diary, {
  required MockDiaryController mockDiaryCtrl,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      mockUserCtrl: mockUserCtrl,
      mockDiaryCtrl: mockDiaryCtrl,
      home: DiaryPage(diary: diary),
    ),
  );
}

void main() {
  late MockUserController mockCtrl;
  late MockDiaryController mockDiaryCtrl;

  setUp(() {
    mockCtrl = MockUserController();
    mockDiaryCtrl = MockDiaryController();
    when(mockDiaryCtrl.fetchDiaryById(any)).thenAnswer((_) async => []);
    when(mockDiaryCtrl.allDiaries).thenReturn([]);
  });

  group('Loading state', () {
    testWidgets('mostra CircularProgressIndicator mentre carica', (tester) async {
      final completer = Completer<Users?>();
      when(mockCtrl.getUserById(any)).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestApp(
          mockUserCtrl: mockCtrl,
          mockDiaryCtrl: mockDiaryCtrl,
          home: DiaryPage(diary: makeDiary()),
        ),
      );

      await tester.pump(Duration.zero);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(null);
      await tester.pumpAndSettle();
    });
  });

  group('Contenuto base', () {
    testWidgets('mostra nome trek e data', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.text('Monte Rosa'), findsOneWidget);
      expect(find.text('2024-06-15'), findsOneWidget);
    });

    testWidgets('durata < 60 → widget Text contiene "45" e "m" senza "h"', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(duration: 45),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('45') ?? false) &&
            (w.data?.contains('m') ?? false) &&
            !(w.data?.contains('h') ?? false)),
        findsOneWidget,
      );
    });

    testWidgets('durata >= 60 → widget Text contiene "h" e "30"', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(duration: 90),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('h') ?? false) &&
            (w.data?.contains('30') ?? false)),
        findsOneWidget,
      );
    });

    testWidgets('mostra username del owner', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser(username: 'bob'));

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.text('bob'), findsOneWidget);
    });

    testWidgets('owner con photoProfile non vuota – CircleAvatar presente, nessun crash',
        (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer(
        (_) async => makeUser(photoProfile: 'https://example.com/photo.jpg'),
      );

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException ||
            details.exception.toString().contains('statusCode: 400')) {
          errors.add(details);
        } else {
          originalOnError?.call(details);
        }
      };

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('owner con photoProfile null → Icon(Icons.person) nel CircleAvatar',
        (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer(
        (_) async => makeUser(photoProfile: null),
      );

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('owner con photoProfile stringa vuota → Icon(Icons.person)', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer(
        (_) async => makeUser(photoProfile: ''),
      );

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('owner null → nessun crash, nome trek visibile', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => null);

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.text('Monte Rosa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sezione Friends', () {
    testWidgets('non mostra la sezione se lista vuota', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(friends: []),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group), findsNothing);
    });

    testWidgets('mostra username degli amici e icona group', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());
      when(mockCtrl.getUserById('f1'))
          .thenAnswer((_) async => makeUser(uid: 'f1', username: 'charlie'));

      await pumpDiaryPage(tester, mockCtrl, makeDiary(friends: ['f1']),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.text('charlie'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('friend null → placeholder SizedBox, nessun crash', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());
      when(mockCtrl.getUserById('f1')).thenAnswer((_) async => null);

      await pumpDiaryPage(tester, mockCtrl, makeDiary(friends: ['f1']),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Sezione Challenges', () {
    testWidgets('non mostra la sezione se lista vuota', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(challenges: []),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });

    testWidgets('mostra icona emoji_events e fallback Icons.flag per asset mancante',
        (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(
        tester,
        mockCtrl,
        makeDiary(challenges: ['assets/bad_path.png']),
        mockDiaryCtrl: mockDiaryCtrl,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('mostra N icone fallback per N challenge con asset mancanti', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(
        tester,
        mockCtrl,
        makeDiary(challenges: ['assets/c1.png', 'assets/c2.png', 'assets/c3.png']),
        mockDiaryCtrl: mockDiaryCtrl,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsNWidgets(3));
    });
  });

  group('Back button', () {
    testWidgets('chiude DiaryPage e torna alla route precedente', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await tester.pumpWidget(
        buildTestApp(
          mockUserCtrl: mockCtrl,
          mockDiaryCtrl: mockDiaryCtrl,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => DiaryPage(diary: makeDiary())),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryPage), findsOneWidget);

      final backBtn = find.descendant(
        of: find.byType(DiaryPage),
        matching: find.byType(ElevatedButton),
      );

      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DiaryPage), findsNothing);
    });
  });

  group('Durata edge cases', () {
    testWidgets('duration = 60 → contiene "h" nel Text', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(duration: 60),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
            (w) => w is Text && (w.data?.contains('h') ?? false) && (w.data?.contains('1') ?? false)),
        findsOneWidget,
      );
    });

    testWidgets('duration = 0 → contiene "0" e "m" senza "h"', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(duration: 0),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('0') ?? false) &&
            (w.data?.contains('m') ?? false) &&
            !(w.data?.contains('h') ?? false)),
        findsOneWidget,
      );
    });
  });

  group('Nome trek lungo', () {
    testWidgets('nome di 200 caratteri non crasha (overflow ellipsis)', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());

      await pumpDiaryPage(tester, mockCtrl, makeDiary(trekkigName: 'A' * 200),
          mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Errore nel caricamento', () {
    testWidgets('eccezione in getUserById → non crasha, isLoading → false', (tester) async {
      when(mockCtrl.getUserById(any)).thenThrow(Exception('network error'));

      await pumpDiaryPage(tester, mockCtrl, makeDiary(), mockDiaryCtrl: mockDiaryCtrl);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Friends e Challenges simultanei', () {
    testWidgets('entrambe le sezioni visibili contemporaneamente', (tester) async {
      when(mockCtrl.getUserById('u1')).thenAnswer((_) async => makeUser());
      when(mockCtrl.getUserById('f2'))
          .thenAnswer((_) async => makeUser(uid: 'f2', username: 'eve'));

      await pumpDiaryPage(
        tester,
        mockCtrl,
        makeDiary(friends: ['f2'], challenges: ['assets/c1.png']),
        mockDiaryCtrl: mockDiaryCtrl,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('eve'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });
}