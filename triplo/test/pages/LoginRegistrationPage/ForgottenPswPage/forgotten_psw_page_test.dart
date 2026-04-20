import 'package:mockito/annotations.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/pages/LoginRegistrationPage/forgotten_password_page/forgotten_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:mockito/mockito.dart';
import 'forgotten_psw_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserController>(),
  MockSpec<NavigatorObserver>(),
])

void main() {
  late MockUserController mockController;
  late MockNavigatorObserver mockObserver;

  setUp(() {
    mockController = MockUserController();
    mockObserver = MockNavigatorObserver();
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(
          value: mockController,
        ),
      ],
      child: MaterialApp(
        home: ForgottenPasswordPage(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('renders UI elements', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('shows snackbar if email is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    final context = tester.element(find.byType(ForgottenPasswordPage));
    final local = AppLocalizations.of(context)!;

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text(local.email_required), findsOneWidget);
  });

  testWidgets('calls controller and shows success', (tester) async {
    when(mockController.sendPasswordReset(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.byType(TextField), 'test@email.com');
    await tester.tap(find.byType(ElevatedButton));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    verify(mockController.sendPasswordReset('test@email.com')).called(1);
  });

  testWidgets('shows error if controller throws', (tester) async {
    when(mockController.sendPasswordReset(any))
        .thenThrow(Exception('error'));

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.byType(TextField), 'test@email.com');
    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(find.textContaining('Error'), findsOneWidget);
  });
  
  testWidgets('pops page after success', (tester) async {
    when(mockController.sendPasswordReset(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserController>.value(
            value: mockController,
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [mockObserver],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgottenPasswordPage(),
                        ),
                      );
                    },
                    child: const Text('Go'),
                  ),
                ),
              );
            },
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'test@email.com');
    await tester.tap(find.byType(ElevatedButton));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    verify(mockObserver.didPop(any, any)).called(1);
  });
}