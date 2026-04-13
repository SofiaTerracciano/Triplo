import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
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
            ChangeNotifierProvider<UserController>.value(
                value: mockUserController),
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

      // Apre il drawer
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