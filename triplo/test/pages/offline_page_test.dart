import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/pages/offline_page.dart'; 

void main() {
  Widget createWidget(Locale locale) {
    return MaterialApp(
      locale: locale,
      routes: {
        '/navigation': (context) => const Scaffold(body: Text('Navigation Page')),
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
      ],
      home: const OfflinePage(),
    );
  }

  testWidgets('Mostra testi in inglese', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Offline mode'), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
  });

  testWidgets('Mostra tutti gli elementi principali', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);

    expect(find.byType(Text), findsNWidgets(3));

    expect(find.byKey(const Key('offline_navigation_button')), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('Scroll funziona se contenuto eccede', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(const Locale('en')));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('Click sul bottone naviga a /navigation', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(const Locale('en')));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('offline_navigation_button'));

    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Navigation Page'), findsOneWidget);
  });

  testWidgets('Mostra testi in italiano', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(const Locale('it')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OfflinePage));
    final local = AppLocalizations.of(context)!;

    expect(find.text(local.offline_mode_label), findsOneWidget);
    expect(find.text(local.no_internet), findsOneWidget);
  });

  testWidgets('Cambia lingua dinamicamente', (WidgetTester tester) async {
    Locale locale = const Locale('en');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('it'),
            ],
            home: Builder(
              builder: (context) {
                return Column(
                  children: [
                    const Expanded(child: OfflinePage()),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          locale = const Locale('it');
                        });
                      },
                      child: const Text('Change Language'),
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Offline mode'), findsOneWidget);

    await tester.tap(find.text('Change Language'));
    await tester.pumpAndSettle();

    expect(find.text('Modalità offline'), findsOneWidget);
  });
}