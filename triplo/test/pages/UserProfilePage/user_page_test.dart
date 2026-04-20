import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';
import 'package:triplo/service/memory.dart';
import 'user_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserController>(),
  MockSpec<DiaryController>(),
  MockSpec<TrekkingController>(),
  MockSpec<ServiceController>(),
  MockSpec<MemoryService>(),
])

void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;
  late MockTrekkingController mockTrekkingController;
  late MockServiceController mockServiceController;
  late MockMemoryService mockMemoryService;

  Users makeUser({
    String uid = 'uid-1',
    String username = 'testuser',
    String level = 'Beginner',
    String? photoProfile,
  }) =>
      Users(
        uid: uid,
        username: username,
        name: 'Mario',
        surname: 'Rossi',
        email: 'mario@test.com',
        birthdate: DateTime(1990, 1, 1),
        followers: const [],
        following: const [],
        publicDiaryPages: const [],
        privateDiaryPages: const [],
        savedTrekkings: const [],
        level: level,
        advanced: 0,
        intermediate: 0,
        photoProfile: photoProfile,
      );

  Diary makeDiary({
    required String id,
    required String name,
    String date = '2024-01-01',
    bool isPublic = true,
  }) =>
      Diary(
        diaryId: id,
        userId: 'uid-1',
        trekkigName: name,
        date: date,
        duration: 0,
        friends: const [],
        photos: const [],
        challenges: const [],
        refreshmentPoint: '',
        mood: const [],
        notes: '',
        isPublic: isPublic,
      );

  Trekking makeTrekking({required String id, required String name}) =>
      Trekking(
        documentId: id,
        name: name,
        mapPhoto: '',
        difficultyLevel: 'easy',
        distance: 0,
        estimatedTime: 0,
        elevationGain: 0,
        upGain: false,
        downGain: false,
        startingPoint: const LatLng(0, 0),
        endingPoint: const LatLng(0, 0),
        points: const [],
        startingPointName: '',
        endingPointName: '',
        info: const [],
        endingPointPhoto: '',
        description: const [],
        picNicArea: false,
        familyFirendly: false,
      );

  Widget buildWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekkingController),
        Provider<ServiceController>.value(value: mockServiceController),
        ChangeNotifierProvider<Language>(
          create: (_) => Language(memoryService: mockMemoryService),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/login': (_) => const Scaffold(body: Text('LoginPage')),
        },
        home: const UserPage(),
      ),
    );
  }

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
    mockTrekkingController = MockTrekkingController();
    mockServiceController = MockServiceController();
    mockMemoryService = MockMemoryService();
    when(mockUserController.isLoading).thenReturn(false);
    when(mockUserController.currentUser).thenReturn(makeUser());
    when(mockTrekkingController.getTrekkingById(any))
      .thenReturn(makeTrekking(id: 't1', name: 'Via Francigena'));
  });

  group('Loading state', () {
    testWidgets('mostra CircularProgressIndicator quando isLoading è true',
        (tester) async {
      when(mockUserController.isLoading).thenReturn(true);
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Avatar', () {
    testWidgets('mostra Icons.person quando photoProfile è null',
        (tester) async {
      when(mockUserController.currentUser)
          .thenReturn(makeUser(photoProfile: null));

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra Icons.person quando photoProfile è stringa vuota',
        (tester) async {
      when(mockUserController.currentUser)
          .thenReturn(makeUser(photoProfile: ''));

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('usa NetworkImage quando photoProfile è un URL valido',
        (tester) async {
      const url = 'https://example.com/photo.png';
      when(mockUserController.currentUser)
          .thenReturn(makeUser(photoProfile: url));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is NetworkImageLoadException) return;
        originalOnError?.call(d);
      };

      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      FlutterError.onError = originalOnError;

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<NetworkImage>());
      expect((avatar.backgroundImage as NetworkImage).url, url);
      expect(find.byIcon(Icons.person), findsNothing);
    });
  });

  group('Level badge', () {
    for (final entry in {
      'Beginner': Colors.lightBlue,
      'Intermediate': Colors.red,
      'Advanced': const Color.fromARGB(255, 135, 1, 162),
    }.entries) {
      testWidgets('livello ${entry.key} ha il colore corretto', (tester) async {
        when(mockUserController.currentUser)
            .thenReturn(makeUser(level: entry.key));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        final richTexts = tester.widgetList<RichText>(find.byType(RichText));
        final hasColor = richTexts.any((rt) {
          final span = rt.text;
          if (span is TextSpan && span.children != null) {
            return span.children!.any((child) =>
                child is TextSpan && child.style?.color == entry.value);
          }
          return false;
        });
        expect(hasColor, isTrue,
            reason:
                'Il livello ${entry.key} dovrebbe avere colore ${entry.value}');
      });
    }
  });

  group('Followers / Following count', () {
    testWidgets('mostra il conteggio corretto dei followers', (tester) async {
      when(mockUserController.getFollowers('uid-1')).thenAnswer((_) async => [
            makeUser(uid: 'f1', username: 'f1'),
            makeUser(uid: 'f2', username: 'f2'),
          ]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('mostra il conteggio corretto dei following', (tester) async {
      when(mockUserController.getFollowing('uid-1')).thenAnswer((_) async => [
            makeUser(uid: 'g1', username: 'g1'),
          ]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('tap su followers naviga a UsersList', (tester) async {
      when(mockUserController.getFollowers('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final gestures = find.byType(GestureDetector);
      await tester.tap(gestures.first);
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
    });

    testWidgets('tap su following naviga a UsersList', (tester) async {
      when(mockUserController.getFollowing('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final gestures = find.byType(GestureDetector);
      await tester.tap(gestures.at(1));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
    });
  });

  group('Total diaries count', () {
    testWidgets('mostra la somma di diari pubblici e privati', (tester) async {
      when(mockDiaryController.getPublicDiaries('uid-1')).thenAnswer((_) async =>
          [makeDiary(id: 'd1', name: 'T1'), makeDiary(id: 'd2', name: 'T2')]);
      when(mockDiaryController.getPrivateDiaries('uid-1')).thenAnswer(
          (_) async => [makeDiary(id: 'd3', name: 'T3', isPublic: false)]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('3'), findsWidgets);
    });

    testWidgets('mostra 0 quando non ci sono diari', (tester) async {
      when(mockDiaryController.getPublicDiaries('uid-1'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPrivateDiaries('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });
  });

  group('Tab 1 - Diari pubblici', () {
    testWidgets('mostra CircularProgressIndicator durante il caricamento',
        (tester) async {
      final completer = Completer<List<Diary>>();
      when(mockDiaryController.getPublicDiaries(any))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('mostra label empty quando non ci sono diari pubblici',
        (tester) async {
      when(mockDiaryController.getPublicDiaries('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('mostra la lista dei diari pubblici con nome e data',
        (tester) async {
      when(mockDiaryController.getPublicDiaries('uid-1')).thenAnswer(
          (_) async =>
              [makeDiary(id: 'd1', name: 'Trekking Alpi', date: '2024-06-01')]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Trekking Alpi'), findsOneWidget);
      expect(find.text('2024-06-01'), findsOneWidget);
    });

    testWidgets('tap su un diario pubblico naviga a DiaryPage', (tester) async {
      when(mockDiaryController.getPublicDiaries('uid-1')).thenAnswer(
          (_) async => [makeDiary(id: 'd1', name: 'Trekking Alpi')]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trekking Alpi'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
    });
  });

  group('Tab 2 - Diari privati', () {
    Future<void> goToTab2(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.lock));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra label empty quando non ci sono diari privati',
        (tester) async {
      when(mockDiaryController.getPrivateDiaries('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab2(tester);

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('mostra la lista dei diari privati con nome e data',
        (tester) async {
      when(mockDiaryController.getPrivateDiaries('uid-1')).thenAnswer(
          (_) async => [
                makeDiary(
                    id: 'd2',
                    name: 'Diario Segreto',
                    date: '2024-03-10',
                    isPublic: false)
              ]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab2(tester);

      expect(find.text('Diario Segreto'), findsOneWidget);
      expect(find.text('2024-03-10'), findsOneWidget);
    });

    testWidgets('tap su un diario privato naviga a DiaryPage', (tester) async {
      when(mockDiaryController.getPrivateDiaries('uid-1')).thenAnswer(
          (_) async => [
                makeDiary(id: 'd2', name: 'Diario Segreto', isPublic: false)
              ]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab2(tester);

      await tester.tap(find.text('Diario Segreto'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
    });
  });

  group('Tab 3 - Trekking salvati', () {
    Future<void> goToTab3(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra label empty quando non ci sono trekking salvati',
        (tester) async {
      when(mockTrekkingController.getSavedTrekkings('uid-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab3(tester);

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('mostra la lista dei trekking salvati', (tester) async {
      when(mockTrekkingController.getSavedTrekkings('uid-1')).thenAnswer(
          (_) async => [makeTrekking(id: 't1', name: 'Via Francigena')]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab3(tester);

      expect(find.text('Via Francigena'), findsOneWidget);
    });

    testWidgets('tap su un trekking salvato naviga a TrekkingPage',
        (tester) async {
      when(mockTrekkingController.getSavedTrekkings('uid-1')).thenAnswer(
          (_) async => [makeTrekking(id: 't1', name: 'Via Francigena')]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await goToTab3(tester);

      await tester.tap(find.text('Via Francigena'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);
    });
  });

  testWidgets('mostra schermata not logged quando user è null', (tester) async {
    when(mockUserController.currentUser).thenReturn(null);
    when(mockUserController.isLoading).thenReturn(false);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_off), findsOneWidget);
    expect(find.textContaining('login'), findsWidgets);
  });

  testWidgets('tap su go_to_login_button naviga a /login', (tester) async {
    when(mockUserController.currentUser).thenReturn(null);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('LoginPage'), findsOneWidget);
  });

  testWidgets('tap su logout chiama logout e naviga a login', (tester) async {
    when(mockUserController.logout()).thenAnswer((_) async {});

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout)); 
    await tester.pumpAndSettle();

    verify(mockUserController.logout()).called(1);
    expect(find.text('LoginPage'), findsOneWidget);
  });

  testWidgets('tap su share non crasha', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.share));
    await tester.pump();

    expect(true, isTrue);
  });

  testWidgets('bottom navigation funziona', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final icons = [
      Icons.home,
      Icons.search,
      Icons.settings,
      Icons.emoji_events,
      Icons.explore, 
    ];

    for (final icon in icons) {
      if (find.byIcon(icon).evaluate().isEmpty) continue;

      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}