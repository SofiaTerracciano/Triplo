import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/exception/change_email_exception.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/pages/SettingsPage/setting-page.dart';
import 'setting_page_test.mocks.dart';

@GenerateMocks([UserController, Language])

void main() {
  group('SettingPage – widget', () {
    late MockUserController mockUserController;
    late MockLanguage mockLanguage;
    late Users fakeUser;

    setUp(() {
      mockUserController = MockUserController();
      mockLanguage = MockLanguage();
      fakeUser = _buildUser();

      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(mockUserController.isPasswordUser).thenReturn(true);
      when(mockUserController.isGoogleUser).thenReturn(false);
      when(mockUserController.addListener(any)).thenReturn(null);
      when(mockUserController.removeListener(any)).thenReturn(null);
      when(mockUserController.refreshEmailFromAuth())
          .thenAnswer((_) async {});

      when(mockLanguage.locale).thenReturn(const Locale('en'));
      when(mockLanguage.addListener(any)).thenReturn(null);
      when(mockLanguage.removeListener(any)).thenReturn(null);
    });

    Widget buildPage() => MultiProvider(
      providers: [
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
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
        // Aggiungi questa route
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Page')),
        },
        home: SettingPage(),
      ),
    );

    testWidgets('mostra titolo nella AppBar', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.settings_page_title), findsWidgets);
    });

    testWidgets('mostra ListView nel body', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('mostra Drawer', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final ScaffoldState scaffold =
          tester.firstState(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('mostra schermata not logged se user è null', (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      expect(find.text(local.not_logged_title), findsOneWidget);
      expect(find.text(local.not_logged_subtitle), findsOneWidget);
    });

    testWidgets('mostra bottone login nella schermata not logged',
        (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      expect(find.text(local.please_login_label), findsOneWidget);
    });

    testWidgets('mostra icona person_off nella schermata not logged',
        (tester) async {
      when(mockUserController.currentUser).thenReturn(null);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('mostra username utente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('mario'), findsOneWidget);
    });

    testWidgets('mostra nome utente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Mario'), findsOneWidget);
    });

    testWidgets('mostra cognome utente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Rossi'), findsOneWidget);
    });

    testWidgets('mostra email utente', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('mario@test.it'), findsOneWidget);
    });

    testWidgets('mostra data di nascita formattata', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('01/06/2000'), findsOneWidget);
    });

    testWidgets('mostra lingua corrente (English)', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('mostra icona edit per username', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsWidgets);
    });

    testWidgets('mostra icona calendar_today per data di nascita',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('mostra icona language per lingua', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('mostra CircleAvatar nel profilo', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('mostra icona edit sulla foto profilo', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsWidgets);
    });

    testWidgets('mostra sezione password per utente password', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.password_message_label), findsOneWidget);
    });

    testWidgets('mostra bottone invia reset password', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.password_send_label), findsOneWidget);
    });

    testWidgets('tap bottone reset password chiama requestPasswordReset',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.requestPasswordReset())
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.password_send_label));
      await tester.pumpAndSettle();

      verify(mockUserController.requestPasswordReset()).called(1);
    });

    testWidgets('NON mostra sezione password per utente Google',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.isPasswordUser).thenReturn(false);
      when(mockUserController.isGoogleUser).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.password_message_label), findsNothing);
    });

    testWidgets('mostra bottone ripristina foto Google per utente Google',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.isPasswordUser).thenReturn(false);
      when(mockUserController.isGoogleUser).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.restore_google_photo_label), findsOneWidget);
    });

    testWidgets('NON mostra bottone foto Google per utente password',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.restore_google_photo_label), findsNothing);
    });

    testWidgets('mostra bottone accoppia orologio', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.watch_pair_label), findsOneWidget);
    });

    testWidgets('mostra bottone notifiche meteo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;
      expect(find.text(local.weather_alerts_label), findsOneWidget);
    });

    testWidgets('mostra icona qr_code_scanner per bottone orologio',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('mostra icona notifications_active per bottone meteo',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('tap su nome apre AlertDialog di modifica', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.name_field_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tap su cognome apre AlertDialog di modifica', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.surname_field_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog modifica ha bottone Annulla e Salva', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.name_field_label));
      await tester.pumpAndSettle();

      expect(find.text(local.cancel_button_label), findsOneWidget);
      expect(find.text(local.save_trekking_button_label), findsOneWidget);
    });

    testWidgets('tap Annulla nel dialog chiude il dialog', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.name_field_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text(local.cancel_button_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('salva nome chiama updateName sul controller', (tester) async {
      when(mockUserController.updateName(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.name_field_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Luca');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verify(mockUserController.updateName('Luca')).called(1);
    });

    testWidgets('tap su lingua apre LanguageDialog', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.language_field_label));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageDialog), findsOneWidget);
    });

    testWidgets('LanguageDialog mostra tutte le 5 lingue', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.language_field_label));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsWidgets);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('selezione lingua chiama setLocale sul controller',
        (tester) async {
      when(mockLanguage.setLocale(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.language_field_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      verify(mockLanguage.setLocale(const Locale('it'))).called(1);
    });

    testWidgets('lingua it mostra Italiano', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('it'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Italiano'), findsOneWidget);
    });

    testWidgets('lingua es mostra Español', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('es'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('lingua de mostra Deutsch', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('de'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('lingua fr mostra Français', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('fr'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('lingua sconosciuta mostra Unknown', (tester) async {
      when(mockLanguage.locale).thenReturn(const Locale('zh'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets(
        'tap su email per utente Google mostra SnackBar provider message',
        (tester) async {
      when(mockUserController.isPasswordUser).thenReturn(false);
      when(mockUserController.isGoogleUser).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Drawer contiene voci di navigazione principali',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final ScaffoldState scaffold =
          tester.firstState(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      expect(find.text(local.home_page_title), findsOneWidget);
      expect(find.text(local.profile_page_title), findsOneWidget);
      expect(find.text(local.search_page_title), findsOneWidget);
      expect(find.text(local.settings_page_title), findsWidgets);
      expect(find.text(local.challeng_title), findsOneWidget);
      expect(find.text(local.navigation_page_title), findsOneWidget);
    });

    testWidgets('Drawer contiene icone corrette', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final ScaffoldState scaffold =
          tester.firstState(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person), findsWidgets);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsWidgets);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('tap email per utente password apre AlertDialog',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog cambio email ha campo nuova email e password',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('dialog cambio email ha bottone Annulla e Salva',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      expect(find.text(local.cancel_button_label), findsOneWidget);
      expect(find.text(local.save_trekking_button_label), findsOneWidget);
    });

    testWidgets('Annulla nel dialog cambio email chiude il dialog senza chiamare changeEmail',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text(local.cancel_button_label));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      ));
    });

    testWidgets('campi vuoti non chiamano changeEmail', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verifyNever(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      ));
    });

    testWidgets('salva cambio email con dati validi chiama changeEmail',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verify(mockUserController.changeEmail(
        newEmail: 'nuova@email.it',
        currentPassword: 'password123',
      )).called(1);
    });

    testWidgets(
        'cambio email riuscito mostra SnackBar di conferma e bottone sign-in-again',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      expect(find.text('Sign in again with the new email'), findsOneWidget);
    });

    testWidgets(
        'errore wrong-password mostra SnackBar con messaggio password errata',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('wrong-password'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'sbagliata');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(
        find.text('La password attuale non è corretta'),
        findsOneWidget,
      );
    });

    testWidgets(
        'errore email-already-in-use mostra SnackBar con messaggio email in uso',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('email-already-in-use'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'usata@email.it');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(find.text('Questa email è già in uso'), findsOneWidget);
    });

    testWidgets(
        'errore invalid-email mostra SnackBar con messaggio email non valida',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('invalid-email'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nonvalida');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(find.text("L'indirizzo email non è valido"), findsOneWidget);
    });

    testWidgets(
        'errore requires-recent-login mostra SnackBar con messaggio relog',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('requires-recent-login'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(
        find.text('Devi autenticarti di nuovo prima di cambiare email'),
        findsOneWidget,
      );
    });

    testWidgets('errore generico mostra SnackBar con messaggio di default',
        (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('unknown-error'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(find.text('Errore durante il cambio email'), findsOneWidget);
    });

    testWidgets('tap icona edit su username apre AlertDialog', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final editButtons = find.widgetWithIcon(IconButton, Icons.edit);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('salva cognome chiama updateSurname sul controller',
        (tester) async {
      when(mockUserController.updateSurname(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.surname_field_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bianchi');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verify(mockUserController.updateSurname('Bianchi')).called(1);
    });

    testWidgets('salva username chiama updateUsername sul controller',
    (tester) async {
      when(mockUserController.updateUsername(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      final editButtons = find.widgetWithIcon(IconButton, Icons.edit);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'lucar');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verify(mockUserController.updateUsername('lucar')).called(1);
    });

    testWidgets('campo vuoto nel dialog non chiama updateName', (tester) async {
      when(mockUserController.updateName(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.name_field_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      verifyNever(mockUserController.updateName(any));
    });

    testWidgets('utente senza foto mostra icona person come placeholder',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('utente con photoProfile non mostra icona person nel CircleAvatar',
    (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('NetworkImageLoadException')) return;
        originalOnError?.call(details);
      };

      final userWithPhoto = Users(
        uid: 'user1',
        username: 'mario',
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
        photoProfile: 'https://example.com/photo.jpg',
      );
      when(mockUserController.currentUser).thenReturn(userWithPhoto);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
      final mainAvatar = avatars.first;
      expect(mainAvatar.child, isNull);
      expect(mainAvatar.backgroundImage, isNotNull);

      FlutterError.onError = originalOnError;
    });

    testWidgets('tap restore google photo chiama restoreGoogleProfilePhoto',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.isPasswordUser).thenReturn(false);
      when(mockUserController.isGoogleUser).thenReturn(true);
      when(mockUserController.restoreGoogleProfilePhoto())
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.restore_google_photo_label));
      await tester.pumpAndSettle();

      verify(mockUserController.restoreGoogleProfilePhoto()).called(1);
    });

    testWidgets('reset password riuscito mostra SnackBar di conferma',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.requestPasswordReset())
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.password_send_label));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(local.password_reset_label), findsOneWidget);
    });

    testWidgets('tap su data di nascita apre DatePicker', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.birthdate_field_label));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('selezione data di nascita chiama updateBirthdate', (tester) async {
      when(mockUserController.updateBirthdate(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.birthdate_field_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      verify(mockUserController.updateBirthdate(any)).called(1);
    });

    testWidgets('tap edit foto profilo chiama updateProfilePhoto', (tester) async {
      when(mockUserController.updateProfilePhoto(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('tap sign-in-again esegue logout e naviga al login',
    (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenAnswer((_) async {});
      when(mockUserController.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in again with the new email'));
      await tester.pumpAndSettle();

      verify(mockUserController.logout()).called(1);
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('utente non-password non-Google non mostra sezione password né foto Google',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(mockUserController.isPasswordUser).thenReturn(false);
      when(mockUserController.isGoogleUser).thenReturn(false);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      expect(find.text(local.password_message_label), findsNothing);
      expect(find.text(local.restore_google_photo_label), findsNothing);
    });

    testWidgets('errore not-authenticated mostra SnackBar con messaggio utente non autenticato',
    (tester) async {
      when(mockUserController.changeEmail(
        newEmail: anyNamed('newEmail'),
        currentPassword: anyNamed('currentPassword'),
      )).thenThrow(ChangeEmailException('not-authenticated'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(SettingPage)),
      )!;

      await tester.tap(find.text(local.email_label));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nuova@email.it');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.text(local.save_trekking_button_label));
      await tester.pumpAndSettle();

      expect(find.text('Nessun utente autenticato'), findsOneWidget);
    });
  });
}

Users _buildUser() => Users(
      uid: 'user1',
      username: 'mario',
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