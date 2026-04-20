import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/SearchPage/search-page.dart';
import 'search_page_test.mocks.dart';

@GenerateMocks([UserController, DiaryController, TrekkingController, Language])

void main() {
  group('SearchPage – widget', () {
    late MockUserController mockUserController;
    late MockDiaryController mockDiaryController;
    late MockTrekkingController mockTrekkingController;
    late MockLanguage mockLanguage;
    late Users fakeUser;

    Users _buildUser({String uid = 'u1', String username = 'mario'}) => Users(
          uid: uid,
          username: username,
          name: 'Mario',
          surname: 'Rossi',
          email: 'mario@test.it',
          birthdate: DateTime(2000, 6, 1),
          followers: [],
          following: [],
          publicDiaryPages: [],
          privateDiaryPages: [],
          savedTrekkings: [],
          level: 'beginner',
          advanced: 0,
          intermediate: 0,
          photoProfile: null,
        );

    Diary _buildDiary({
      String id = 'd1',
      String userId = 'u1',
      String trekkingName = 'Monte Bianco',
    }) =>
        Diary(
          diaryId: id,
          userId: userId,
          trekkigName: trekkingName,
          date: '2024-01-01',
          duration: 3.0,
          friends: [],
          photos: [],
          challenges: [],
          refreshmentPoint: '',
          mood: [],
          notes: '',
          isPublic: true,
        );

    Trekking _buildTrekking({
      String id = 'trek-1',
      String name = 'Monte Bianco',
      String difficulty = 'easy',
    }) =>
        Trekking(
          documentId: id,
          name: name,
          mapPhoto: '',
          difficultyLevel: difficulty,
          distance: 10.0,
          estimatedTime: 3.0,
          elevationGain: 500,
          upGain: true,
          downGain: true,
          startingPoint: const LatLng(45.0, 7.0),
          endingPoint: const LatLng(45.1, 7.1),
          points: [],
          startingPointName: 'Start',
          endingPointName: 'End',
          info: [],
          endingPointPhoto: '',
          description: [],
          picNicArea: false,
          familyFirendly: false,
        );

    setUp(() {
      mockUserController = MockUserController();
      mockDiaryController = MockDiaryController();
      mockTrekkingController = MockTrekkingController();
      mockLanguage = MockLanguage();
      fakeUser = _buildUser();

      when(mockUserController.addListener(any)).thenReturn(null);
      when(mockUserController.removeListener(any)).thenReturn(null);
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.getFollowingIds(any))
          .thenAnswer((_) async => []);
      when(mockUserController.searchUsers(any)).thenAnswer((_) async => []);

      when(mockDiaryController.addListener(any)).thenReturn(null);
      when(mockDiaryController.removeListener(any)).thenReturn(null);
      when(mockDiaryController.getRandomPublicDiariesFromFollowing(
        followingIds: anyNamed('followingIds'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      when(mockTrekkingController.addListener(any)).thenReturn(null);
      when(mockTrekkingController.removeListener(any)).thenReturn(null);
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => []);

      when(mockLanguage.locale).thenReturn(const Locale('en'));
      when(mockLanguage.addListener(any)).thenReturn(null);
      when(mockLanguage.removeListener(any)).thenReturn(null);

      SearchCache.randomDiaries = null;
    });

    Widget buildPage() => MultiProvider(
          providers: [
            ChangeNotifierProvider<UserController>.value(
                value: mockUserController),
            ChangeNotifierProvider<DiaryController>.value(
                value: mockDiaryController),
            ChangeNotifierProvider<TrekkingController>.value(
                value: mockTrekkingController),
            ChangeNotifierProvider<Language>.value(value: mockLanguage),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SearchPage(),
          ),
        );

    testWidgets('mostra AppBar con titolo search_page_title', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.search_page_title), findsWidgets);
    });

    testWidgets('mostra campo di ricerca TextField', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('mostra filtro utenti e trekking', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.user_label), findsOneWidget);
      expect(find.text(local.trekking_label), findsOneWidget);
    });

    testWidgets('mostra icona search nel TextField', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('non mostra icona close se TextField è vuoto', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('mostra no_friends se lista diari random è vuota',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.no_friends), findsOneWidget);
    });

    testWidgets('utente null mostra no_friends senza crash', (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.no_friends), findsOneWidget);
    });

    testWidgets('usa cache SearchCache se già popolata', (tester) async {
      final diary = _buildDiary();
      SearchCache.randomDiaries = [diary];

      when(mockUserController.getUserById(any))
          .thenAnswer((_) async => fakeUser);
      when(mockTrekkingController.getTrekkingId(any)).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      verifyNever(mockDiaryController.getRandomPublicDiariesFromFollowing(
        followingIds: anyNamed('followingIds'),
        limit: anyNamed('limit'),
      ));
    });

    testWidgets('mostra GridView quando ci sono diari random', (tester) async {
      final diary = _buildDiary();
      SearchCache.randomDiaries = [diary];

      when(mockUserController.getUserById(any))
          .thenAnswer((_) async => fakeUser);
      when(mockTrekkingController.getTrekkingId(any)).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('mostra icona close quando c è testo nel TextField',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mario');
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tap icona close svuota il TextField', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mario');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, isEmpty);
    });

    testWidgets('focus sul TextField mostra bottone Annulla', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.cancel_button_label), findsOneWidget);
    });

    testWidgets('tap Annulla rimuove focus e svuota testo', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mario');
      await tester.pump();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.cancel_button_label));
      await tester.pump();

      expect(find.text(local.cancel_button_label), findsNothing);
    });

    testWidgets('ricerca utenti chiama searchUsers sul controller',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mario');
      await tester.pumpAndSettle();

      verify(mockUserController.searchUsers('mario')).called(greaterThan(0));
    });

    testWidgets('nessun risultato utenti mostra no_user_found_label',
        (tester) async {
      when(mockUserController.searchUsers(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      expect(find.text(local.no_user_found_label), findsOneWidget);
    });

    testWidgets('risultati utenti mostrano username e email', (tester) async {
      final foundUser = _buildUser(uid: 'u2', username: 'luigi');
      when(mockUserController.searchUsers(any))
          .thenAnswer((_) async => [foundUser]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'luigi');
      await tester.pumpAndSettle();

      expect(find.text('luigi'), findsWidgets);
      expect(find.text('mario@test.it'), findsOneWidget);
    });

    testWidgets('utente con foto mostra CircleAvatar con NetworkImage',
        (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('NetworkImageLoadException')) return;
        originalOnError?.call(details);
      };

      final userWithPhoto = _buildUser(uid: 'u2', username: 'luigi');
      userWithPhoto.photoProfile = 'https://example.com/photo.jpg';
      when(mockUserController.searchUsers(any))
          .thenAnswer((_) async => [userWithPhoto]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'luigi');
      await tester.pump();

      expect(find.byType(CircleAvatar), findsWidgets);
      FlutterError.onError = originalOnError;
    });

    testWidgets('utente senza foto mostra CircleAvatar con icona person',
        (tester) async {
      final userNoPhoto = _buildUser(uid: 'u2', username: 'luigi');
      when(mockUserController.searchUsers(any))
          .thenAnswer((_) async => [userNoPhoto]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'luigi');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('cambio filtro a trekking chiama searchTrekking',
        (tester) async {
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'monte');
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      verify(mockTrekkingController.searchTrekking('monte'))
          .called(greaterThan(0));
    });

    testWidgets('nessun risultato trekking mostra no_trekking_found_label',
        (tester) async {
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      expect(find.text(local.no_trekking_found_label), findsOneWidget);
    });

    testWidgets('risultati trekking easy mostrano nome e livello beginner',
        (tester) async {
      final trek = _buildTrekking(name: 'Sentiero Verde', difficulty: 'easy');
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => [trek]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sentiero');
      await tester.pumpAndSettle();

      expect(find.text('Sentiero Verde'), findsOneWidget);
      expect(find.text(local.beginner_level), findsOneWidget);
    });

    testWidgets('risultati trekking intermediate mostrano livello intermediate',
        (tester) async {
      final trek = _buildTrekking(
          name: 'Sentiero Medio', difficulty: 'intermediate');
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => [trek]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sentiero');
      await tester.pumpAndSettle();

      expect(find.text(local.intermediate_level), findsOneWidget);
    });

    testWidgets('risultati trekking hard mostrano livello advanced',
        (tester) async {
      final trek =
          _buildTrekking(name: 'Sentiero Duro', difficulty: 'hard');
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => [trek]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sentiero');
      await tester.pumpAndSettle();

      expect(find.text(local.advanced_level), findsOneWidget);
    });

    testWidgets('risultati trekking mostrano icona terrain', (tester) async {
      final trek = _buildTrekking();
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => [trek]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'monte');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('cambio filtro svuota risultati precedenti', (tester) async {
      final foundUser = _buildUser(uid: 'u2', username: 'luigi');
      when(mockUserController.searchUsers(any))
          .thenAnswer((_) async => [foundUser]);
      when(mockTrekkingController.searchTrekking(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'luigi');
      await tester.pumpAndSettle();

      expect(find.text('mario@test.it'), findsOneWidget);

      final local = AppLocalizations.of(
        tester.element(find.byType(SearchPage)),
      )!;
      await tester.tap(find.text(local.trekking_label));
      await tester.pumpAndSettle();

      expect(find.text('mario@test.it'), findsNothing);
    });

    testWidgets('mostra Drawer', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scaffold = tester.firstState(find.byType(Scaffold)) as ScaffoldState;
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('Drawer contiene voci di navigazione principali',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scaffold =
          tester.firstState(find.byType(Scaffold)) as ScaffoldState;
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(Drawer)),
      )!;
      expect(find.text(local.home_page_title), findsOneWidget);
      expect(find.text(local.profile_page_title), findsOneWidget);
      expect(find.text(local.settings_page_title), findsOneWidget);
      expect(find.text(local.challeng_title), findsOneWidget);
      expect(find.text(local.navigation_page_title), findsOneWidget);
    });

    testWidgets('tap search nel Drawer chiude il Drawer', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final scaffold =
          tester.firstState(find.byType(Scaffold)) as ScaffoldState;
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(Drawer)),
      )!;
      await tester.tap(find.text(local.search_page_title).last);
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
    });
  });
}