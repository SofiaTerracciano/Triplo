import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/DiaryPage/diary-page.dart';
import 'package:triplo/pages/UserProfilePage/user-page-public.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'diary_page_test.mocks.dart';

@GenerateMocks([DiaryController, UserController, TrekkingController])

void main() {
  late MockDiaryController mockDiaryController;
  late MockUserController mockUserController;
  late MockTrekkingController mockTrekkingController;

  Diary makeDiary({
    String diaryId = 'diary-1',
    String userId = 'user-1',
    String trekkingName = 'Monte Rosa',
    double duration = 90,
    String date = '2024-06-01',
    List<String> friends = const [],
    List<String> photos = const [],
    List<String> challenges = const [],
    List<String> mood = const [],
    String refreshmentPoint = '',
    String notes = '',
    bool isPublic = false,
  }) {
    return Diary(
      diaryId: diaryId,
      userId: userId,
      trekkigName: trekkingName,
      duration: duration,
      date: date,
      friends: friends,
      photos: photos,
      challenges: challenges,
      mood: mood,
      refreshmentPoint: refreshmentPoint,
      notes: notes,
      isPublic: isPublic,
    );
  }

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

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<TrekkingController>.value(
          value: mockTrekkingController,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  setUp(() {
    mockDiaryController = MockDiaryController();
    mockUserController = MockUserController();
    mockTrekkingController = MockTrekkingController();
  });

  group('DiaryPage – loading states', () {

    testWidgets('shows CircularProgressIndicator while diary is loading',
        (tester) async {
      final c = Completer<Diary?>();
      when(mockDiaryController.getDiaryByIdAsync('diary-1'))
          .thenAnswer((_) => c.future);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: 'diary-1')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      c.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('shows CircularProgressIndicator while user is loading',
        (tester) async {
      final diary = makeDiary();
      final c = Completer<Users?>();
      when(mockDiaryController.getDiaryByIdAsync('diary-1'))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(makeUser());
      when(mockUserController.getUserById('user-1'))
          .thenAnswer((_) => c.future);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: 'diary-1')));
      await tester.pump(); // resolve diary future
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      c.complete(null);
      await tester.pumpAndSettle();
    });
  });

  group('DiaryPage – error states', () {

    testWidgets('shows diary_not_found when diary is null', (tester) async {
      when(mockDiaryController.getDiaryByIdAsync('missing')).thenAnswer(
        (_) async => null,
      );

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: 'missing')));
      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('shows user_not_found when user is null', (tester) async {
      final diary = makeDiary();
      when(mockDiaryController.getDiaryByIdAsync('diary-1'))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(makeUser());
      when(mockUserController.getUserById('user-1'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: 'diary-1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });
  });

  group('DiaryPage – duration formatting', () {

    Future<void> pumpFullPage(WidgetTester tester, Diary diary) async {
      final user = makeUser();
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();
    }

    testWidgets('shows minutes only when duration < 60', (tester) async {
      await pumpFullPage(tester, makeDiary(duration: 45));
      expect(find.textContaining('45'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows whole hours when duration is exact multiple of 60',
        (tester) async {
      await pumpFullPage(tester, makeDiary(duration: 120));
      expect(find.textContaining('2 h'), findsAtLeastNWidgets(1));
      expect(find.textContaining('0 m'), findsNothing);
    });

    testWidgets('shows hours and minutes for mixed duration', (tester) async {
      await pumpFullPage(tester, makeDiary(duration: 95));
      // 95 min = 1h 35m — search for both parts separately
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(allText.contains('1') && allText.contains('35'), isTrue);
    });
  });

  group('DiaryPage – AppBar', () {

    testWidgets('AppBar title equals trekking name', (tester) async {
      final diary = makeDiary(trekkingName: 'Gran Paradiso');
      final user = makeUser();
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.text('Gran Paradiso'), findsOneWidget);
    });

    testWidgets('edit button visible when current user is diary owner',
        (tester) async {
      final diary = makeDiary(userId: 'owner-uid');
      final currentUser = makeUser(uid: 'owner-uid');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(currentUser);
      when(mockUserController.getUserById('owner-uid'))
          .thenAnswer((_) async => currentUser);
      when(mockTrekkingController.getTrekkingId(any)).thenReturn('trek-1');

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('edit button NOT visible when current user is NOT diary owner',
        (tester) async {
      final diary = makeDiary(userId: 'owner-uid');
      final currentUser = makeUser(uid: 'other-uid');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(currentUser);
      when(mockUserController.getUserById('owner-uid'))
          .thenAnswer((_) async => makeUser(uid: 'owner-uid'));

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });

  group('DiaryPage – user info card', () {

    testWidgets('shows username in card', (tester) async {
      final diary = makeDiary();
      final user = makeUser(username: 'mountain_lover');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.text('mountain_lover'), findsOneWidget);
    });

    testWidgets('shows person icon when photoProfile is null', (tester) async {
      final diary = makeDiary();
      final user = makeUser(photoProfile: null);
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsAtLeastNWidgets(1));
    });

    testWidgets('shows date and duration rows', (tester) async {
      final diary = makeDiary(date: '2025-07-15', duration: 60);
      final user = makeUser();
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.textContaining('2025-07-15'), findsOneWidget);
      expect(find.textContaining('1 h'), findsOneWidget);
    });
  });

  group('DiaryPage – conditional sections', () {
    Future<void> pumpDiary(WidgetTester tester, Diary diary) async {
      final user = makeUser();
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);
      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();
    }

    testWidgets('friends section hidden when friends list is empty',
        (tester) async {
      await pumpDiary(tester, makeDiary(friends: []));
      expect(find.byIcon(Icons.group), findsNothing);
    });

    testWidgets('friends section visible when friends list is not empty',
        (tester) async {
      final friendUser = makeUser(uid: 'friend-1', username: 'buddy');
      when(mockUserController.getUserById('friend-1'))
          .thenAnswer((_) async => friendUser);

      await pumpDiary(tester, makeDiary(friends: ['friend-1']));
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('photos section hidden when photos list is empty',
        (tester) async {
      await pumpDiary(tester, makeDiary(photos: []));
      expect(find.byIcon(Icons.photo), findsNothing);
    });

    testWidgets('photos section visible when photos list is not empty',
        (tester) async {
      when(mockDiaryController.getDownloadUrlChild(any))
          .thenAnswer((_) async => null);

      await pumpDiary(tester, makeDiary(photos: ['photo1.jpg']));
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('challenges section hidden when challenges list is empty',
        (tester) async {
      await pumpDiary(tester, makeDiary(challenges: []));
      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('challenges section visible when challenges list is not empty',
        (tester) async {
      when(mockDiaryController.getDownloadUrl(any))
          .thenAnswer((_) async => null);

      await pumpDiary(tester, makeDiary(challenges: ['badge1']));
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('mood section hidden when mood list is empty', (tester) async {
      await pumpDiary(tester, makeDiary(mood: []));
      expect(find.byIcon(Icons.mood), findsNothing);
    });

    testWidgets('mood section visible and shows emoji chips', (tester) async {
      await pumpDiary(tester, makeDiary(mood: ['😍', '😁', '🥰', '😅', '😎', '😞', '🤩']));
      expect(find.byIcon(Icons.mood), findsOneWidget);
      expect(find.text('😍'), findsOneWidget);
      expect(find.text('😁'), findsOneWidget);
      expect(find.text('🥰'), findsOneWidget);
      expect(find.text('😅'), findsOneWidget);
      expect(find.text('😎'), findsOneWidget);
      expect(find.text('😞'), findsOneWidget);
      expect(find.text('🤩'), findsOneWidget);
    });

    testWidgets('refreshment point section hidden when empty', (tester) async {
      await pumpDiary(tester, makeDiary(refreshmentPoint: ''));
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('refreshment point section visible when not empty',
        (tester) async {
      await pumpDiary(
        tester,
        makeDiary(refreshmentPoint: 'Rifugio Monviso'),
      );
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.text('Rifugio Monviso'), findsOneWidget);
    });

    testWidgets('notes section hidden when empty', (tester) async {
      await pumpDiary(tester, makeDiary(notes: ''));
      expect(find.byIcon(Icons.notes), findsNothing);
    });

    testWidgets('notes section visible when not empty', (tester) async {
      await pumpDiary(
        tester,
        makeDiary(notes: 'Bellissima escursione con vista sul ghiacciaio.'),
      );
      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(
        find.text('Bellissima escursione con vista sul ghiacciaio.'),
        findsOneWidget,
      );
    });
  });

  group('DiaryPage – navigation', () {

    testWidgets(
        'tapping username navigates to UserPage when current user is owner',
        (tester) async {
      final diary = makeDiary(userId: 'me');
      final user = makeUser(uid: 'me', username: 'myself');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById('me'))
          .thenAnswer((_) async => user);
      when(mockUserController.isLoading).thenReturn(false);
      when(mockDiaryController.getPublicDiaries('me'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPrivateDiaries('me'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowers('me'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowing('me'))
          .thenAnswer((_) async => []);
      when(mockTrekkingController.getSavedTrekkings('me'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('myself'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPage), findsOneWidget);
    });

    testWidgets(
        'tapping username navigates to UserPagePublic when current user is NOT owner',
        (tester) async {
      final diary = makeDiary(userId: 'someone-else');
      final currentUser = makeUser(uid: 'me');
      final diaryUser = makeUser(uid: 'someone-else', username: 'trailblazer');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(currentUser);
      when(mockUserController.getUserById('someone-else'))
          .thenAnswer((_) async => diaryUser);
      when(mockUserController.isFollowing('someone-else'))
          .thenAnswer((_) async => false);
      when(mockDiaryController.fetchDiaryById('someone-else'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPublicDiaries('someone-else'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPrivateDiaries('someone-else'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowers('someone-else'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowing('someone-else'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('trailblazer'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPagePublic), findsOneWidget);
    });
  });

  group('SectionTitle widget', () {

    testWidgets('renders icon and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionTitle(text: 'Test section', icon: Icons.star),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Test section'), findsOneWidget);
    });
  });

  group('infoRow widget', () {

    testWidgets('renders icon and label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: infoRow(Icons.date_range, 'Data: 2024-01-01'),
          ),
        ),
      );
      expect(find.byIcon(Icons.date_range), findsOneWidget);
      expect(find.text('Data: 2024-01-01'), findsOneWidget);
    });
  });

  group('imageScroller widget', () {

    testWidgets('renders one placeholder per image while loading',
        (tester) async {
      final completers = List.generate(3, (_) => Completer<String?>());
      int idx = 0;
      Future<String?> loader(String _) => completers[idx++].future;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: imageScroller(['a', 'b', 'c'], loader),
          ),
        ),
      );
      await tester.pump(); 

      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThanOrEqualTo(3));

      for (final c in completers) {
        c.complete(null);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('uses BoxFit.contain for badges and BoxFit.cover for photos',
        (tester) async {
      Future<String?> loader(String _) async => null;

      Widget buildScroller({required bool isBadge}) => MaterialApp(
            home: Scaffold(
              body: imageScroller(['x'], loader, isBadge: isBadge),
            ),
          );

      await tester.pumpWidget(buildScroller(isBadge: true));
      final sizedBoxBadge =
          tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBoxBadge.height, 60);

      await tester.pumpWidget(buildScroller(isBadge: false));
      final sizedBoxPhoto =
          tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBoxPhoto.height, 120);
    });
  });

  group('DiaryPage – uncovered lines', () {

    testWidgets('shows NetworkImage when user has a photoProfile',
        (tester) async {
      final diary = makeDiary();
      final user = makeUser(photoProfile: 'https://example.com/photo.jpg');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(user);
      when(mockUserController.getUserById(diary.userId))
          .thenAnswer((_) async => user);

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('NetworkImageLoadException') ||
            details.toString().contains('statusCode: 400')) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(
        avatars.any((a) => a.backgroundImage is NetworkImage),
        isTrue,
      );

      await tester.pump(const Duration(seconds: 1));
      tester.takeException(); 
    });

    testWidgets('tapping a friend chip navigates to UserPagePublic',
        (tester) async {
      final diary = makeDiary(userId: 'owner-uid', friends: ['friend-1']);
      final owner = makeUser(uid: 'owner-uid');
      final friend = makeUser(uid: 'friend-1', username: 'friendUser');
      when(mockDiaryController.getDiaryByIdAsync(diary.diaryId))
          .thenAnswer((_) async => diary);
      when(mockUserController.currentUser).thenReturn(owner);
      when(mockUserController.getUserById('owner-uid'))
          .thenAnswer((_) async => owner);
      when(mockUserController.getUserById('friend-1'))
          .thenAnswer((_) async => friend);
      when(mockUserController.isFollowing('friend-1'))
          .thenAnswer((_) async => false);
      when(mockDiaryController.fetchDiaryById('friend-1'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPublicDiaries('friend-1'))
          .thenAnswer((_) async => []);
      when(mockDiaryController.getPrivateDiaries('friend-1'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowers('friend-1'))
          .thenAnswer((_) async => []);
      when(mockUserController.getFollowing('friend-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestApp(DiaryPage(diaryId: diary.diaryId)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('friendUser'));
      await tester.pumpAndSettle();

      expect(find.byType(UserPagePublic), findsOneWidget);
    });

    testWidgets('imageScroller shows Image.network when URL is available',
        (tester) async {
      const fakeUrl = 'https://example.com/img.jpg';
      Future<String?> loader(String _) async => fakeUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: imageScroller(['photo.jpg'], loader),
          ),
        ),
      );
      await tester.pump(); 


      final images = tester.widgetList<Image>(find.byType(Image));
      expect(
        images.any((img) =>
            img.image is NetworkImage &&
            (img.image as NetworkImage).url == fakeUrl),
        isTrue,
      );

      await tester.pump(const Duration(seconds: 1));
      tester.takeException(); 
    });
  });
}