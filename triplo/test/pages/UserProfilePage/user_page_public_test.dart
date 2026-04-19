import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/pages/UserProfilePage/user-page-public.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'user_page_public_test.mocks.dart';

@GenerateNiceMocks([MockSpec<UserController>(), MockSpec<DiaryController>()])
void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;

  // ---------------------------------------------------------------------------
  // FACTORIES
  // ---------------------------------------------------------------------------

  Users makeUser({String uid = 'u1', String username = 'test'}) {
    return Users(
      uid: uid,
      username: username,
      name: 'Mario',
      surname: 'Rossi',
      email: 'test@test.com',
      birthdate: DateTime(1990),
      followers: const [],
      following: const [],
      publicDiaryPages: const [],
      privateDiaryPages: const [],
      savedTrekkings: const [],
      level: 'Beginner',
      advanced: 0,
      intermediate: 0,
    );
  }

  Diary makeDiary({
    required String id,
    required String name,
    String date = '2024-01-01',
  }) {
    return Diary(
      diaryId: id,
      userId: 'u1',
      trekkigName: name,
      date: date,
      duration: 0,
      friends: const [],
      photos: const [],
      challenges: const [],
      refreshmentPoint: '',
      mood: const [],
      notes: '',
      isPublic: true,
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  Widget buildWidget({String userId = 'u1'}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(
          value: mockDiaryController,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UserPagePublic(userId: userId),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SETUP
  // ---------------------------------------------------------------------------

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
  });

  // ---------------------------------------------------------------------------
  // TEST
  // ---------------------------------------------------------------------------

  group('UserPagePublic', () {
    // -----------------------------------------------------------------------
    // USER NULL
    // -----------------------------------------------------------------------

    testWidgets('mostra user_not_found quando user è null', (tester) async {
      when(mockUserController.getUserById(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // RENDER BASE
    // -----------------------------------------------------------------------

    testWidgets('mostra username utente', (tester) async {
      final user = makeUser();

      when(mockUserController.getUserById(any)).thenAnswer((_) async => user);

      when(
        mockDiaryController.getPublicDiaries(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(user.username), findsWidgets);
    });

    testWidgets('tap following naviga', (tester) async {
      final user = makeUser(uid: 'u2');

      when(mockUserController.getUserById(any)).thenAnswer((_) async => user);

      when(
        mockDiaryController.getPublicDiaries(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget(userId: 'u2'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Following').at(1));
      await tester.pumpAndSettle();

      expect(find.byType(UserPagePublic), findsNothing);
    });

    // -----------------------------------------------------------------------
    // DIARIES LIST
    // -----------------------------------------------------------------------

    testWidgets('mostra lista diari', (tester) async {
      final user = makeUser(uid: 'u2');

      when(mockUserController.getUserById(any)).thenAnswer((_) async => user);

      when(
        mockDiaryController.getPublicDiaries('u2'),
      ).thenAnswer((_) async => [makeDiary(id: 'd1', name: 'Diario 1')]);

      await tester.pumpWidget(buildWidget(userId: 'u2'));
      await tester.pumpAndSettle();

      expect(find.text('Diario 1'), findsOneWidget);
    });
  });
}
