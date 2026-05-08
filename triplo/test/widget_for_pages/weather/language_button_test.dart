import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/widgets_for_pages/language_button/language_button.dart'; // aggiusta il path

Widget _wrap({required Future<void> Function(Locale) onLocaleSelected}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('it'),
      Locale('es'),
      Locale('de'),
      Locale('fr'),
    ],
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => LanguageButton(onLocaleSelected: onLocaleSelected),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}


void main() {
  group('LanguageButton', () {

    testWidgets('mostra il titolo del dialog', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('mostra tutte e 5 le lingue', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('mostra le bandiere', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      expect(find.text('🇬🇧'), findsOneWidget);
      expect(find.text('🇮🇹'), findsOneWidget);
      expect(find.text('🇪🇸'), findsOneWidget);
      expect(find.text('🇩🇪'), findsOneWidget);
      expect(find.text('🇫🇷'), findsOneWidget);
    });

    testWidgets('ha 5 ListTile', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('tap English chiama onLocaleSelected con Locale("en")',
        (tester) async {
      Locale? selected;
      await tester.pumpWidget(
          _wrap(onLocaleSelected: (l) async => selected = l));
      await _openDialog(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(selected, const Locale('en'));
    });

    testWidgets('tap Italiano chiama onLocaleSelected con Locale("it")',
        (tester) async {
      Locale? selected;
      await tester.pumpWidget(
          _wrap(onLocaleSelected: (l) async => selected = l));
      await _openDialog(tester);

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      expect(selected, const Locale('it'));
    });

    testWidgets('tap Español chiama onLocaleSelected con Locale("es")',
        (tester) async {
      Locale? selected;
      await tester.pumpWidget(
          _wrap(onLocaleSelected: (l) async => selected = l));
      await _openDialog(tester);

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(selected, const Locale('es'));
    });

    testWidgets('tap Deutsch chiama onLocaleSelected con Locale("de")',
        (tester) async {
      Locale? selected;
      await tester.pumpWidget(
          _wrap(onLocaleSelected: (l) async => selected = l));
      await _openDialog(tester);

      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      expect(selected, const Locale('de'));
    });

    testWidgets('tap Français chiama onLocaleSelected con Locale("fr")',
        (tester) async {
      Locale? selected;
      await tester.pumpWidget(
          _wrap(onLocaleSelected: (l) async => selected = l));
      await _openDialog(tester);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(selected, const Locale('fr'));
    });

    testWidgets('dopo tap il dialog si chiude (Navigator.pop)', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('dialog si chiude anche dopo tap Italiano', (tester) async {
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {}));
      await _openDialog(tester);

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('attende il completamento del callback async prima del pop',
        (tester) async {
      bool completed = false;
      await tester.pumpWidget(_wrap(onLocaleSelected: (_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        completed = true;
      }));
      await _openDialog(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}