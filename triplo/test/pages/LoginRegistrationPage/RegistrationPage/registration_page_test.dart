import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/pages/LoginRegistrationPage/registration_page/registration_page.dart';
import 'package:triplo/pages/SettingsPage/setting-page.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:triplo/controller/user.dart';

import 'registration_page_test.mocks.dart' show MockUserController;

@GenerateMocks([UserController])

void main() {
  late MockUserController mockUserController;

  setUp(() {
    mockUserController = MockUserController();
  });

  group('RegistrationPage - Mockito', () {

    testWidgets('Campi vuoti → mostra snackbar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const RegistrationPage(),
          controller: mockUserController,
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      verifyNever(mockUserController.register(any, any));
    });

    testWidgets('Password diverse → errore', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const RegistrationPage(),
          controller: mockUserController,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), "test@test.com");
      await tester.enterText(find.byType(TextField).at(1), "123456");
      await tester.enterText(find.byType(TextField).at(2), "abcdef");

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      verifyNever(mockUserController.register(any, any));
    });

    testWidgets('Registrazione fallita → mostra errore', (tester) async {
      when(mockUserController.register(any, any))
          .thenThrow(Exception("fail"));

      await tester.pumpWidget(
        buildTestableWidget(
          child: const RegistrationPage(),
          controller: mockUserController,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), "test@test.com");
      await tester.enterText(find.byType(TextField).at(1), "123456");
      await tester.enterText(find.byType(TextField).at(2), "123456");

      await tester.tap(find.byType(ElevatedButton));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(mockUserController.register(any, any)).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

Widget buildTestableWidget({
  required Widget child,
  required UserController controller,
}) {
  return ChangeNotifierProvider<UserController>.value(
    value: controller,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
