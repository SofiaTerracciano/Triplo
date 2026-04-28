import 'dart:async';
import 'package:app_triplo_wearos/pages/UserProfilePage/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/model/user.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'user_list_page_test.mocks.dart';

@GenerateMocks([UserController, DiaryController])
void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;


  Users makeUser({
    required String uid,
    required String username,
    String? photoProfile,
    String name = 'Nome',
    String surname = 'Cognome',
    String email = 'test@example.com',
    DateTime? birthdate,
    String level = 'beginner',
    int advanced = 0,
    int intermediate = 0,
  }) =>
      Users(
        uid: uid,
        username: username,
        name: name,
        surname: surname,
        email: email,
        birthdate: birthdate ?? DateTime(2000, 1, 1),
        followers: const [],
        following: const [],
        publicDiaryPages: const [],
        privateDiaryPages: const [],
        savedTrekkings: const [],
        level: level,
        advanced: advanced,
        intermediate: intermediate,
        photoProfile: photoProfile,
      );

  Widget buildSubject({
    required String title,
    required List<String> uids,
  }) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserController>.value(value: mockUserController),
          ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserListPage(title: title, uids: uids),
        ),
      );

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
  });


  group('Rendering base', () {
    testWidgets('mostra il titolo passato come parametro', (tester) async {
      when(mockUserController.getUserById('u1'))
          .thenAnswer((_) async => makeUser(uid: 'u1', username: 'Alice'));

      await tester.pumpWidget(buildSubject(title: 'Followers', uids: ['u1']));
      await tester.pump();

      expect(find.text('Followers'), findsOneWidget);
    });

    testWidgets('mostra il pulsante back', (tester) async {
      when(mockUserController.getUserById('u1'))
          .thenAnswer((_) async => makeUser(uid: 'u1', username: 'Alice'));

      await tester.pumpWidget(buildSubject(title: 'Test', uids: ['u1']));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('con lista vuota non viene creata nessuna Card', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Vuoto', uids: []));
      await tester.pump();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('contiene una ListView', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'T', uids: []));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Lista utenti', () {
    testWidgets('mostra una Card per ogni uid', (tester) async {
      final users = [
        makeUser(uid: 'u1', username: 'Alice'),
        makeUser(uid: 'u2', username: 'Bob'),
        makeUser(uid: 'u3', username: 'Carlo'),
      ];
      for (final u in users) {
        when(mockUserController.getUserById(u.uid))
            .thenAnswer((_) async => u);
      }

      await tester.pumpWidget(
        buildSubject(title: 'Amici', uids: ['u1', 'u2', 'u3']),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('mostra lo username di ogni utente', (tester) async {
      when(mockUserController.getUserById('u1'))
          .thenAnswer((_) async => makeUser(uid: 'u1', username: 'Alice'));
      when(mockUserController.getUserById('u2'))
          .thenAnswer((_) async => makeUser(uid: 'u2', username: 'Bob'));

      await tester.pumpWidget(
        buildSubject(title: 'Lista', uids: ['u1', 'u2']),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('mostra un SizedBox placeholder mentre il future è in attesa',
        (tester) async {
      when(mockUserController.getUserById('u1'))
          .thenAnswer((_) => Completer<Users?>().future);

      await tester.pumpWidget(buildSubject(title: 'Loading', uids: ['u1']));
      await tester.pump(); 

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('non mostra Card se getUserById ritorna null', (tester) async {
      when(mockUserController.getUserById('u1'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildSubject(title: 'Null', uids: ['u1']));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });
  });

  group('Avatar utente', () {
    testWidgets('mostra icona person quando photoProfile è null', (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice', photoProfile: null),
      );

      await tester.pumpWidget(buildSubject(title: 'T', uids: ['u1']));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra icona person quando photoProfile è stringa vuota',
        (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice', photoProfile: ''),
      );

      await tester.pumpWidget(buildSubject(title: 'T', uids: ['u1']));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('CircleAvatar ha radius 12', (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice'),
      );

      await tester.pumpWidget(buildSubject(title: 'T', uids: ['u1']));
      await tester.pumpAndSettle();

      final avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.radius, 12);
    });
  });

  group('Navigazione', () {
    testWidgets(
        'pulsante back esegue Navigator.pop e torna alla route precedente',
        (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserController>.value(value: mockUserController),
            ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserListPage(title: 'Pop Test', uids: ['u1']),
                  ),
                ),
                child: const Text('Apri lista'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri lista'));
      await tester.pumpAndSettle();
      expect(find.byType(UserListPage), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(find.byType(UserListPage), findsNothing);
      expect(find.text('Apri lista'), findsOneWidget);
    });
  });


  group('Interazione con UserController', () {
    testWidgets('chiama getUserById esattamente una volta per ogni uid',
        (tester) async {
      const uids = ['u1', 'u2', 'u3'];
      for (final uid in uids) {
        when(mockUserController.getUserById(uid))
            .thenAnswer((_) async => makeUser(uid: uid, username: uid));
      }

      await tester.pumpWidget(buildSubject(title: 'Ctrl', uids: uids));
      await tester.pumpAndSettle();

      for (final uid in uids) {
        verify(mockUserController.getUserById(uid)).called(1);
      }
    });

    testWidgets('non chiama getUserById se la lista di uid è vuota',
        (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Empty', uids: []));
      await tester.pumpAndSettle();

      verifyNever(mockUserController.getUserById(any));
    });

    testWidgets('chiama getUserById con il uid corretto', (tester) async {
      when(mockUserController.getUserById('abc123')).thenAnswer(
        (_) async => makeUser(uid: 'abc123', username: 'Utente'),
      );

      await tester.pumpWidget(buildSubject(title: 'Uid', uids: ['abc123']));
      await tester.pumpAndSettle();

      verify(mockUserController.getUserById('abc123')).called(1);
      verifyNever(mockUserController.getUserById('altro'));
    });
  });
}