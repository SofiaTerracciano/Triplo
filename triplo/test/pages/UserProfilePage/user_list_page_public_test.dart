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
import 'package:triplo/pages/UserProfilePage/user-list-page-public.dart';
import 'user_list_page_public_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserController>(),
  MockSpec<DiaryController>(),
])

void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;

  Widget buildWidget({required String listName, required String userId}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UsersListPublic(listName: listName, userId: userId),
      ),
    );
  }

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

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
  });

  group('Loading state', () {
    testWidgets('mostra CircularProgressIndicator durante il caricamento',
        (tester) async {
      final completer = Completer<List<Users>>();
      when(mockUserController.getFollowers(any))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('Empty state', () {
    testWidgets('mostra label quando la lista followers è vuota',
        (tester) async {
      when(mockUserController.getFollowers('u1')).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('mostra label quando la lista following è vuota',
        (tester) async {
      when(mockUserController.getFollowing('u1')).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget(listName: 'Following', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('List rendering', () {
    testWidgets('renderizza un ListTile per ogni follower', (tester) async {
      final users = [
        makeUser(uid: 'a', username: 'alice'),
        makeUser(uid: 'b', username: 'bob'),
        makeUser(uid: 'c', username: 'carol'),
      ];
      when(mockUserController.getFollowers('u1'))
          .thenAnswer((_) async => users);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('carol'), findsOneWidget);
    });

    testWidgets('renderizza un ListTile per ogni following', (tester) async {
      final users = [
        makeUser(uid: 'd', username: 'dave'),
        makeUser(uid: 'e', username: 'eve'),
      ];
      when(mockUserController.getFollowing('u2'))
          .thenAnswer((_) async => users);

      await tester.pumpWidget(buildWidget(listName: 'Following', userId: 'u2'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('dave'), findsOneWidget);
      expect(find.text('eve'), findsOneWidget);
    });

    testWidgets('il titolo AppBar corrisponde a listName="Follower"',
        (tester) async {
      when(mockUserController.getFollowers('u1')).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Follower'), findsOneWidget);
    });

    testWidgets('il titolo AppBar corrisponde a listName="Following"',
        (tester) async {
      when(mockUserController.getFollowing('u1')).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget(listName: 'Following', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Following'), findsOneWidget);
    });
  });

  group('Avatar rendering', () {
    testWidgets('mostra Icons.person quando photoProfile è null',
        (tester) async {
      when(mockUserController.getFollowers('u1')).thenAnswer((_) async =>
          [makeUser(uid: 'a', username: 'alice', photoProfile: null)]);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra Icons.person quando photoProfile è stringa vuota',
        (tester) async {
      when(mockUserController.getFollowers('u1')).thenAnswer((_) async =>
          [makeUser(uid: 'a', username: 'alice', photoProfile: '')]);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('usa NetworkImage quando photoProfile ha un URL valido',
        (tester) async {
      const url = 'https://example.com/avatar.png';
      when(mockUserController.getFollowers('u1')).thenAnswer((_) async =>
          [makeUser(uid: 'a', username: 'alice', photoProfile: url)]);

      // Sopprimi solo gli errori HTTP delle immagini — attesi in ambiente test.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
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
    testWidgets(
        'chiama getFollowers con userId corretto quando listName è "Follower"',
        (tester) async {
      when(mockUserController.getFollowers('uid-123'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          buildWidget(listName: 'Follower', userId: 'uid-123'));
      await tester.pumpAndSettle();

      verify(mockUserController.getFollowers('uid-123')).called(1);
      verifyNever(mockUserController.getFollowing(any));
    });

    testWidgets(
        'chiama getFollowing con userId corretto quando listName non è "Follower"',
        (tester) async {
      when(mockUserController.getFollowing('uid-456'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          buildWidget(listName: 'Following', userId: 'uid-456'));
      await tester.pumpAndSettle();

      verify(mockUserController.getFollowing('uid-456')).called(1);
      verifyNever(mockUserController.getFollowers(any));
    });
  });

  group('Navigation', () {
    testWidgets('il tap su un ListTile naviga verso UserPagePublic',
        (tester) async {
      final user = makeUser(uid: 'nav-uid', username: 'navUser');
      when(mockUserController.getFollowers('u1'))
          .thenAnswer((_) async => [user]);

      when(mockUserController.getUserById('nav-uid'))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildWidget(listName: 'Follower', userId: 'u1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(UsersListPublic), findsNothing);
    });
  });
}