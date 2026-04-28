import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/LoginRegistrationPage/login_page/LoginPage.dart';
import 'package:triplo/service/memory.dart';
import 'login_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserController>(),
  MockSpec<DiaryController>(),
  MockSpec<MemoryService>(),
  MockSpec<TrekkingController>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  late MockUserController mockUserController;
  late MockDiaryController mockDiaryController;
  late MockMemoryService mockMemoryService;
  late MockTrekkingController mockTrekkingController;
  late MockNavigatorObserver mockObserver;

  setUp(() {
    mockUserController = MockUserController();
    mockDiaryController = MockDiaryController();
    mockMemoryService = MockMemoryService();
    mockTrekkingController = MockTrekkingController();
    mockObserver = MockNavigatorObserver();

    when(mockUserController.isLoading).thenReturn(false);

    when(mockUserController.login(any, any))
        .thenAnswer((_) async {});
    when(mockUserController.loginWithGoogle())
        .thenAnswer((_) async {});
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
        ChangeNotifierProvider<DiaryController>.value(value: mockDiaryController),
        ChangeNotifierProvider<Language>(
          create: (_) => Language(memoryService: mockMemoryService),
        ),
        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekkingController),
      ],
      child: MaterialApp(
        navigatorObservers: [mockObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/registration': (_) => const Scaffold(),
          '/forgotten_password': (_) => const Scaffold(),
        },
        home: const LoginPage(),
      ),
    );
  }

  group('LoginPage Tests', () {

    testWidgets('Campi vuoti → mostra snackbar', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      verifyNever(mockUserController.login(any, any));
    });

    testWidgets('Login successo → naviga', (tester) async {
      when(mockUserController.currentUser).thenReturn(buildFakeUser());

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextField).at(0), "test@test.com");
      await tester.enterText(find.byType(TextField).at(1), "123456");

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(mockUserController.login("test@test.com", "123456")).called(1);

      verify(mockObserver.didPush(any, any)).called(greaterThan(0));
    });

    testWidgets('Login fallito → snackbar errore', (tester) async {
      when(mockUserController.login(any, any))
          .thenThrow(Exception("fail"));

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextField).at(0), "test@test.com");
      await tester.enterText(find.byType(TextField).at(1), "123456");

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('currentUser null → snackbar', (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextField).at(0), "test@test.com");
      await tester.enterText(find.byType(TextField).at(1), "123456");

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Google login successo → naviga', (tester) async {
      when(mockUserController.currentUser).thenReturn(buildFakeUser());

      await tester.pumpWidget(buildTestableWidget());

      final googleBtn = find.byKey(const Key('google_login_button'));
      expect(googleBtn, findsOneWidget);

      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      verify(mockUserController.loginWithGoogle()).called(1);
      verify(mockObserver.didPush(any, any)).called(greaterThan(0));
    });

    testWidgets('Google login fallito → snackbar', (tester) async {
      when(mockUserController.loginWithGoogle())
          .thenThrow(Exception("google error"));

      await tester.pumpWidget(buildTestableWidget());

      final googleBtn = find.byType(OutlinedButton);
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Navigazione a registration', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      final btn = find.byType(TextButton).first;
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any)).called(greaterThan(0));
    });

    testWidgets('Navigazione a forgotten password', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      final btn = find.byType(TextButton).last;
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any)).called(greaterThan(0));
    });
  });
}

Users buildFakeUser() {
  return Users(
    uid: "123",
    username: "testuser",
    name: "Test",
    surname: "User",
    email: "test@test.com",
    birthdate: DateTime(2000, 1, 1),
    followers: [],
    following: [],
    publicDiaryPages: [],
    privateDiaryPages: [],
    savedTrekkings: [],
    level: "1",
    advanced: 0,
    intermediate: 0,
    photoProfile: null,
  );
}