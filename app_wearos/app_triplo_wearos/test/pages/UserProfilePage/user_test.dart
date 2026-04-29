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
import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/pages/UserProfilePage/user.dart';
import 'package:app_triplo_wearos/pages/PairingLoginPage/login.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'user_test.mocks.dart';

@GenerateMocks([UserController, DiaryController, PairingService])
void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;
  late MockPairingService mockPairingService;

  Users makeUser({
    required String uid,
    required String username,
    String? photoProfile,
    String level = 'Beginner',
    String name = 'Nome',
    String surname = 'Cognome',
    String email = 'test@example.com',
    int advanced = 0,
    int intermediate = 0,
  }) =>
      Users(
        uid: uid,
        username: username,
        name: name,
        surname: surname,
        email: email,
        birthdate: DateTime(2000, 1, 1),
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

  Diary makeDiary({
    required String diaryId,
    required bool isPublic,
    String userId = 'user-id',
    String trekkigName = 'Test Trek',
    String date = '2024-01-01',
    double duration = 1.0,
    List<String> friends = const [],
    List<String> challenges = const [],
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

  void stubPairingService({
    String? pairedUid = 'owner-uid',
    String? effectiveUid = 'owner-uid',
    String? qrPayload,
    bool pairing = false,
    String? pairingError,
    bool remoteLogoutActive = false,
  }) {
    when(mockPairingService.pairedUid).thenReturn(pairedUid);
    when(mockPairingService.effectiveUid).thenReturn(effectiveUid);
    when(mockPairingService.qrPayload).thenReturn(qrPayload);
    when(mockPairingService.pairing).thenReturn(pairing);
    when(mockPairingService.pairingError).thenReturn(pairingError);
    when(mockPairingService.remoteLogoutActive).thenReturn(remoteLogoutActive);
    when(mockPairingService.logoutWatch()).thenAnswer((_) async {});
    when(mockPairingService.startWatchPairing(forceNew: anyNamed('forceNew')))
        .thenAnswer((_) async {});
  }


  Widget buildSubject({String? uidOverride}) => MultiProvider(
        providers: [
          ChangeNotifierProvider<UserController>.value(value: mockUserController),
          ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
          ChangeNotifierProvider<PairingService>.value(value: mockPairingService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserPage(uidOverride: uidOverride),
        ),
      );


  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
    mockPairingService = MockPairingService();

    stubPairingService();

    when(mockUserController.getUserById(any))
        .thenAnswer((_) async => makeUser(uid: 'owner-uid', username: 'Io'));
    when(mockUserController.getFollowerUids(any))
        .thenAnswer((_) async => []);
    when(mockUserController.getFollowingUids(any))
        .thenAnswer((_) async => []);
    when(mockDiaryController.fetchDiaryById(any))
        .thenAnswer((_) async => []);
  });


  group('Profilo proprio', () {
    testWidgets('mostra LoginPage se effectiveUid è null (utente non loggato)',
        (tester) async {
      stubPairingService(
        pairedUid: null,
        effectiveUid: null,
        qrPayload: null,
        pairing: false,
        pairingError: null,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('mostra il pulsante logout nel profilo proprio', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('il pulsante logout chiama PairingService.logoutWatch',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockPairingService.logoutWatch()).called(1);
    });

    testWidgets('mostra sia diari pubblici che privati nel profilo proprio',
        (tester) async {
      when(mockDiaryController.fetchDiaryById('owner-uid')).thenAnswer(
        (_) async => [
          makeDiary(diaryId: 'd1', isPublic: true),
          makeDiary(diaryId: 'd2', isPublic: false),
        ],
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final ones = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data == '1')
          .toList();
      expect(ones.length, 2);
    });

    testWidgets('usa effectiveUid di PairingService come uid', (tester) async {
      stubPairingService(
        pairedUid: 'my-custom-uid',
        effectiveUid: 'my-custom-uid',
      );
      when(mockUserController.getUserById('my-custom-uid')).thenAnswer(
        (_) async => makeUser(uid: 'my-custom-uid', username: 'CustomMe'),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verify(mockUserController.getUserById('my-custom-uid'))
          .called(greaterThan(0));
    });
  });

  group('Profilo altrui', () {
    const otherUid = 'other-uid';

    setUp(() {
      when(mockUserController.getUserById(otherUid)).thenAnswer(
        (_) async => makeUser(uid: otherUid, username: 'Alice'),
      );
    });

    testWidgets('mostra il pulsante back nel profilo altrui', (tester) async {
      await tester.pumpWidget(buildSubject(uidOverride: otherUid));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('il pulsante back esegue Navigator.pop', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserController>.value(value: mockUserController),
            ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
            ChangeNotifierProvider<PairingService>.value(value: mockPairingService),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => UserPage(uidOverride: otherUid),
                  ),
                ),
                child: const Text('Apri profilo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri profilo'));
      await tester.pumpAndSettle();
      expect(find.byType(UserPage), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
      expect(find.text('Apri profilo'), findsOneWidget);
    });

    testWidgets('mostra solo i diari pubblici nel profilo altrui',
        (tester) async {
      when(mockDiaryController.fetchDiaryById(otherUid)).thenAnswer(
        (_) async => [
          makeDiary(diaryId: 'd1', isPublic: true),
          makeDiary(diaryId: 'd2', isPublic: false),
        ],
      );

      await tester.pumpWidget(buildSubject(uidOverride: otherUid));
      await tester.pumpAndSettle();

      final ones = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data == '1')
          .toList();
      expect(ones.length, 1);
    });

    testWidgets('non chiama logoutWatch nel profilo altrui', (tester) async {
      await tester.pumpWidget(buildSubject(uidOverride: otherUid));
      await tester.pumpAndSettle();

      verifyNever(mockPairingService.logoutWatch());
    });
  });


  group('Rendering utente', () {
    testWidgets('mostra CircularProgressIndicator mentre il future è in attesa',
        (tester) async {
      when(mockUserController.getUserById(any))
          .thenAnswer((_) => Completer<Users?>().future);

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets("mostra lo username dell'utente", (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Marco Rossi'),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      expect(find.text('Marco Rossi'), findsOneWidget);
    });

    testWidgets('mostra icona person quando photoProfile è stringa vuota',
        (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice', photoProfile: ''),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra icona person quando photoProfile è null', (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async =>
            makeUser(uid: 'u1', username: 'Alice', photoProfile: null),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('CircleAvatar del profilo ha radius 20', (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice'),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      final avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.radius, 20);
    });
  });

  group('Livello utente', () {
    Future<void> pumpWithLevel(WidgetTester tester, String level) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Test', level: level),
      );
      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();
    }

    testWidgets('colore lightBlue per Beginner', (tester) async {
      await pumpWithLevel(tester, 'Beginner');

      final levelText = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.style?.color == Colors.lightBlue,
            orElse: () =>
                throw TestFailure('Nessun Text con colore lightBlue'),
          );
      expect(levelText.style?.color, Colors.lightBlue);
    });

    testWidgets('colore rosso per Intermediate', (tester) async {
      await pumpWithLevel(tester, 'Intermediate');

      final levelText = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.style?.color == Colors.red,
            orElse: () =>
                throw TestFailure('Nessun Text con colore rosso'),
          );
      expect(levelText.style?.color, Colors.red);
    });

    testWidgets('colore viola per Advanced', (tester) async {
      await pumpWithLevel(tester, 'Advanced');

      const violetto = Color.fromARGB(255, 135, 1, 162);
      final levelText = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.style?.color == violetto,
            orElse: () =>
                throw TestFailure('Nessun Text con colore violetto'),
          );
      expect(levelText.style?.color, violetto);
    });

    testWidgets('mostra "-" per livello non riconosciuto', (tester) async {
      await pumpWithLevel(tester, 'livello_sconosciuto');
      expect(find.text('-'), findsOneWidget);
    });
  });

  group('Followers e following', () {
    const uid = 'u1';

    setUp(() {
      when(mockUserController.getUserById(uid)).thenAnswer(
        (_) async => makeUser(uid: uid, username: 'Alice'),
      );
    });

    testWidgets('mostra il conteggio corretto di followers', (tester) async {
      when(mockUserController.getFollowerUids(uid))
          .thenAnswer((_) async => ['f1', 'f2', 'f3']);

      await tester.pumpWidget(buildSubject(uidOverride: uid));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('mostra il conteggio corretto di following', (tester) async {
      when(mockUserController.getFollowingUids(uid))
          .thenAnswer((_) async => ['x1', 'x2']);

      await tester.pumpWidget(buildSubject(uidOverride: uid));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('mostra 0 per followers e following se le liste sono vuote',
        (tester) async {
      await tester.pumpWidget(buildSubject(uidOverride: uid));
      await tester.pumpAndSettle();

      final zeros = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data == '0')
          .toList();
      expect(zeros.length, greaterThanOrEqualTo(2));
    });

    testWidgets('tap sul bottone followers naviga verso UserListPage',
        (tester) async {
      when(mockUserController.getFollowerUids(uid))
          .thenAnswer((_) async => ['f1']);

      await tester.pumpWidget(buildSubject(uidOverride: uid));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(UserListPage), findsOneWidget);
    });
  });

  group('Interazione con i controller', () {
    testWidgets('chiama getUserById con uidOverride quando specificato',
        (tester) async {
      when(mockUserController.getUserById('target-uid')).thenAnswer(
        (_) async => makeUser(uid: 'target-uid', username: 'Target'),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'target-uid'));
      await tester.pumpAndSettle();

      verify(mockUserController.getUserById('target-uid'))
          .called(greaterThan(0));
      verifyNever(mockUserController.getUserById('owner-uid'));
    });

    testWidgets('chiama getUserById con effectiveUid quando uidOverride è null',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verify(mockUserController.getUserById('owner-uid'))
          .called(greaterThan(0));
    });

    testWidgets('chiama fetchDiaryById con il uid corretto', (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice'),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      verify(mockDiaryController.fetchDiaryById('u1')).called(greaterThan(0));
    });

    testWidgets(
        'chiama getFollowerUids e getFollowingUids con il uid corretto',
        (tester) async {
      when(mockUserController.getUserById('u1')).thenAnswer(
        (_) async => makeUser(uid: 'u1', username: 'Alice'),
      );

      await tester.pumpWidget(buildSubject(uidOverride: 'u1'));
      await tester.pumpAndSettle();

      verify(mockUserController.getFollowerUids('u1')).called(greaterThan(0));
      verify(mockUserController.getFollowingUids('u1')).called(greaterThan(0));
    });

    testWidgets('non chiama logoutWatch automaticamente al rendering',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verifyNever(mockPairingService.logoutWatch());
    });
  });
}