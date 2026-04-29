import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/pages/HomePage/home-page.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/controller/language.dart';

@GenerateMocks([PairingService, Language, TrekkingController, UserController])
import 'navigation_test.mocks.dart';

Widget _buildTestApp({
  required MockPairingService pairing,
  required MockLanguage language,
  MockTrekkingController? trekking,
  MockUserController? user,
  bool enableBackgroundService = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PairingService>.value(value: pairing),
      ChangeNotifierProvider<Language>.value(value: language),
      if (trekking != null)
        ChangeNotifierProvider<TrekkingController>.value(value: trekking),
      if (user != null)
        ChangeNotifierProvider<UserController>.value(value: user),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NavigationPage(enableBackgroundService: enableBackgroundService),
    ),
  );
}

MockPairingService _mockPairing() {
  final m = MockPairingService();
  when(m.restoreWatchPairing()).thenAnswer((_) async => true);
  return m;
}

MockLanguage _mockLanguage() {
  final m = MockLanguage();
  when(m.addListener(any)).thenReturn(null);
  when(m.removeListener(any)).thenReturn(null);
  when(m.hasListeners).thenReturn(false);
  when(m.setLocale(any)).thenAnswer((_) async {});
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationPage – struttura UI –', () {
    testWidgets('mostra il titolo "Triplo"', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Triplo'), findsOneWidget);
    });

    testWidgets('mostra il pulsante Home', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('mostra il pulsante User', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('mostra il pulsante lingua con icona language', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('lo scaffold ha sfondo nero', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('NavigationPage – bootstrap –', () {
    testWidgets('chiama restoreWatchPairing durante initState', (tester) async {
      final pairing = _mockPairing();

      await tester.pumpWidget(
        _buildTestApp(pairing: pairing, language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      verify(pairing.restoreWatchPairing()).called(1);
    });

    testWidgets(
      'non avvia BackgroundService quando enableBackgroundService è false',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('gestisce eccezione in restoreWatchPairing senza crashare', (
      tester,
    ) async {
      final pairing = MockPairingService();
      when(pairing.restoreWatchPairing()).thenThrow(Exception('pairing error'));

      when(pairing.addListener(any)).thenReturn(null);
      when(pairing.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(pairing: pairing, language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Triplo'), findsOneWidget);
    });
  });
  
  group('NavigationPage – dialog lingua –', () {
    testWidgets('tap sul pulsante lingua apre LanguageDialog', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageDialog), findsOneWidget);
    });

    testWidgets('LanguageDialog mostra tutte e 5 le lingue', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('selezione di una lingua chiama setLocale e chiude il dialog', (
      tester,
    ) async {
      final language = _mockLanguage();

      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Seleziona "English"
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      verify(language.setLocale(const Locale('en'))).called(1);
      // Il dialog deve essersi chiuso
      expect(find.byType(LanguageDialog), findsNothing);
    });

    testWidgets('selezione di Italiano chiama setLocale con Locale("it")', (
      tester,
    ) async {
      final language = _mockLanguage();

      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      verify(language.setLocale(const Locale('it'))).called(1);
    });

    testWidgets('selezione di Español chiama setLocale con Locale("es")', (
      tester,
    ) async {
      final language = _mockLanguage();

      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      verify(language.setLocale(const Locale('es'))).called(1);
    });

    testWidgets('selezione di Deutsch chiama setLocale con Locale("de")', (
      tester,
    ) async {
      final language = _mockLanguage();

      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      verify(language.setLocale(const Locale('de'))).called(1);
    });

    testWidgets('selezione di Français chiama setLocale con Locale("fr")', (
      tester,
    ) async {
      final language = _mockLanguage();

      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: language),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      verify(language.setLocale(const Locale('fr'))).called(1);
    });

    testWidgets('il dialog ha sfondo nero', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, Colors.black);
    });
  });

  group('NavigationPage – dispose –', () {
    testWidgets('dispose non lancia eccezioni', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(pairing: _mockPairing(), language: _mockLanguage()),
      );
      await tester.pumpAndSettle();

      // Smonta il widget
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });
}
