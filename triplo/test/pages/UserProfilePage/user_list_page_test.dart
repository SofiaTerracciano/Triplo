import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/UserProfilePage/users-list-page.dart';
import 'user_list_page_test.mocks.dart' show MockUserController, MockDiaryController;

@GenerateNiceMocks([
  MockSpec<UserController>(),
  MockSpec<DiaryController>(),
])

void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;

  Users makeCurrentUser() => Users(
        uid: 'current-uid',
        username: 'currentUser',
        name: 'Mario',
        surname: 'Rossi',
        email: 'mario@test.com',
        birthdate: DateTime(1990, 1, 1),
        followers: const [],
        following: const [],
        publicDiaryPages: const [],
        privateDiaryPages: const [],
        savedTrekkings: const [],
        level: 'beginner',
        advanced: 0,
        intermediate: 0,
      );

  Users makeUser({
    required String uid,
    required String username,
    String? photoProfile,
  }) =>
      Users(
        uid: uid,
        username: username,
        name: 'Nome',
        surname: 'Cognome',
        email: '$username@test.com',
        birthdate: DateTime(2000, 1, 1),
        followers: const [],
        following: const [],
        publicDiaryPages: const [],
        privateDiaryPages: const [],
        savedTrekkings: const [],
        level: 'beginner',
        advanced: 0,
        intermediate: 0,
        photoProfile: photoProfile,
      );

  Widget buildWidget(String listName) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UsersList(listName: listName),
      ),
    );
  }

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();

    when(mockUserController.currentUser).thenReturn(makeCurrentUser());
  });

  group('Loading state', () {
    testWidgets('mostra CircularProgressIndicator mentre il future è in attesa',
        (tester) async {
      final completer = Completer<List<Users>>();
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('Empty state', () {
    testWidgets('mostra "no users found" quando i followers sono vuoti',
        (tester) async {
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('mostra "no users found" quando i following sono vuoti',
        (tester) async {
      when(mockUserController.getFollowing('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Following'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('List rendering', () {
    testWidgets('renderizza username ed email per ogni follower',
        (tester) async {
      final users = [
        makeUser(uid: 'a', username: 'alice'),
        makeUser(uid: 'b', username: 'bob'),
      ];
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) async => users);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('alice@test.com'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('bob@test.com'), findsOneWidget);
    });

    testWidgets('renderizza username ed email per ogni following',
        (tester) async {
      final users = [
        makeUser(uid: 'c', username: 'carol'),
        makeUser(uid: 'd', username: 'dave'),
      ];
      when(mockUserController.getFollowing('current-uid'))
          .thenAnswer((_) async => users);

      await tester.pumpWidget(buildWidget('Following'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('carol'), findsOneWidget);
      expect(find.text('dave'), findsOneWidget);
    });

    testWidgets('il titolo AppBar corrisponde a "Follower"', (tester) async {
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Follower'), findsOneWidget);
    });

    testWidgets('il titolo AppBar corrisponde a "Following"', (tester) async {
      when(mockUserController.getFollowing('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Following'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Following'), findsOneWidget);
    });
  });

  group('Avatar rendering', () {
    testWidgets('mostra Icons.person quando photoProfile è null',
        (tester) async {
      when(mockUserController.getFollowers('current-uid')).thenAnswer(
          (_) async => [makeUser(uid: 'a', username: 'alice', photoProfile: null)]);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra Icons.person quando photoProfile è stringa vuota',
        (tester) async {
      when(mockUserController.getFollowers('current-uid')).thenAnswer(
          (_) async => [makeUser(uid: 'a', username: 'alice', photoProfile: '')]);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('usa NetworkImage quando photoProfile ha un URL valido',
        (tester) async {
      const url = 'https://example.com/avatar.png';
      when(mockUserController.getFollowers('current-uid')).thenAnswer(
          (_) async => [makeUser(uid: 'a', username: 'alice', photoProfile: url)]);

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      FlutterError.onError = originalOnError;

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<NetworkImage>());
      expect((avatar.backgroundImage as NetworkImage).url, url);
      expect(find.byIcon(Icons.person), findsNothing);
    });
  });

  group('Controller interaction', () {
    testWidgets('chiama getFollowers con uid del currentUser', (tester) async {
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      verify(mockUserController.getFollowers('current-uid')).called(1);
      verifyNever(mockUserController.getFollowing(any));
    });

    testWidgets('chiama getFollowing con uid del currentUser', (tester) async {
      when(mockUserController.getFollowing('current-uid'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget('Following'));
      await tester.pumpAndSettle();

      verify(mockUserController.getFollowing('current-uid')).called(1);
      verifyNever(mockUserController.getFollowers(any));
    });
  });

  group('Navigation', () {
    testWidgets('il tap su un ListTile naviga verso UserPagePublic',
        (tester) async {
      final user = makeUser(uid: 'nav-uid', username: 'navUser');
      when(mockUserController.getFollowers('current-uid'))
          .thenAnswer((_) async => [user]);
      when(mockUserController.getUserById('nav-uid'))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildWidget('Follower'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(UsersList), findsNothing);
    });
  });
}