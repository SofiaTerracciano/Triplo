import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/DiaryPage/diary_list_page.dart';
import 'package:app_triplo_wearos/pages/DiaryPage/diary_page.dart';

Diary makeDiary({
  String diaryId = 'diary-001',
  String userId = 'user-1',
  String trekkigName = 'Sentiero Alpha',
  String date = '2024-06-01',
  double duration = 3.0,
  List<String> friends = const ['Alice'],
  List<String> challenges = const ['slope'],
  bool isPublic = true,
}) =>
    Diary(
      diaryId: diaryId,
      userId: userId,
      trekkigName: trekkigName,
      date: date,
      duration: duration,
      friends: friends,
      challenges: challenges,
      isPublic: isPublic,
    );


Widget buildApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    locale: const Locale('it'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: child,
  );
}


Widget buildAppWithPreviousRoute(Widget page, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    locale: const Locale('it'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Builder(
      builder: (ctx) => ElevatedButton(
        key: const Key('open_list'),
        onPressed: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => page),
        ),
        child: const Text('Apri'),
      ),
    ),
  );
}

void main() {
  group('DiaryListPage – struttura widget', () {
    testWidgets('contiene Scaffold e SafeArea', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Test', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('contiene una ListView', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Test', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('la ListView ha padding horizontal 14 e vertical 10',
        (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Test', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final lv = tester.widget<ListView>(find.byType(ListView));
      expect(
        lv.padding,
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );
    });

    testWidgets('contiene un Expanded che wrappa la ListView', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Test', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Expanded), findsOneWidget);
    });
  });


  group('DiaryListPage – titolo', () {
    testWidgets('mostra il titolo passato come parametro', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'I miei diari', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('I miei diari'), findsOneWidget);
    });

    testWidgets('il titolo ha fontSize 13 e fontWeight bold', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Stile', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Stile'));
      expect(titleText.style?.fontSize, 13);
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('il titolo usa il primaryColor del tema', (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      );

      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'Colore', diaries: const []),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Colore'));
      expect(titleText.style?.color, theme.colorScheme.primary);
    });

    testWidgets('titoli diversi vengono visualizzati correttamente',
        (tester) async {
      for (final title in ['Trekking 2024', 'Escursioni estive']) {
        await tester.pumpWidget(
          buildApp(DiaryListPage(title: title, diaries: const [])),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
      }
    });
  });


  group('DiaryListPage – lista vuota', () {
    testWidgets('non mostra Card quando diaries è vuoto', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Vuoto', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('non mostra ListTile quando diaries è vuoto', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Vuoto', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('mostra comunque il pulsante Indietro con lista vuota',
        (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Vuoto', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('DiaryListPage – rendering lista diari', () {
    testWidgets('mostra N Card per N diari', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1', trekkigName: 'A'),
        makeDiary(diaryId: '2', trekkigName: 'B'),
        makeDiary(diaryId: '3', trekkigName: 'C'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('mostra N ListTile per N diari', (tester) async {
      final diaries = List.generate(
        4,
        (i) => makeDiary(diaryId: 'id-$i', trekkigName: 'Trek $i'),
      );

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('mostra trekkigName di ogni diario', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1', trekkigName: 'Monte Bianco'),
        makeDiary(diaryId: '2', trekkigName: 'Gran Paradiso'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monte Bianco'), findsOneWidget);
      expect(find.text('Gran Paradiso'), findsOneWidget);
    });

    testWidgets('mostra la date di ogni diario come subtitle', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1', date: '2024-01-10'),
        makeDiary(diaryId: '2', date: '2024-08-22'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2024-01-10'), findsOneWidget);
      expect(find.text('2024-08-22'), findsOneWidget);
    });

    testWidgets('ogni ListTile ha icona terrain con size 16', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1'),
        makeDiary(diaryId: '2', trekkigName: 'B'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      final icons = tester.widgetList<Icon>(find.byIcon(Icons.terrain)).toList();
      expect(icons.length, 2);
      for (final icon in icons) {
        expect(icon.size, 16);
      }
    });

    testWidgets('icona terrain usa il primaryColor del tema', (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      );

      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'Lista', diaries: [makeDiary()]),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.terrain));
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('titolo del diario ha fontSize 11 e fontWeight bold',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          DiaryListPage(
            title: 'Lista',
            diaries: [makeDiary(trekkigName: 'Rifugio Torino')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trekText = tester.widget<Text>(find.text('Rifugio Torino'));
      expect(trekText.style?.fontSize, 11);
      expect(trekText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('titolo del diario ha TextOverflow.ellipsis', (tester) async {
      const longName =
          'Questo è un nome di sentiero molto molto lungo che non entra nel widget';

      await tester.pumpWidget(
        buildApp(
          DiaryListPage(
            title: 'Lista',
            diaries: [makeDiary(trekkigName: longName)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trekText = tester.widget<Text>(find.text(longName));
      expect(trekText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('la date ha fontSize 10 e colore grigio', (tester) async {
      await tester.pumpWidget(
        buildApp(
          DiaryListPage(
            title: 'Lista',
            diaries: [makeDiary(date: '2024-03-15')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dateText = tester.widget<Text>(find.text('2024-03-15'));
      expect(dateText.style?.fontSize, 10);
      expect(dateText.style?.color, Colors.grey);
    });

    testWidgets('ogni Card ha elevation 2 e BorderRadius 12', (tester) async {
      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'Lista', diaries: [makeDiary()]),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('ogni ListTile è dense con VisualDensity.compact', (tester) async {
      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'Lista', diaries: [makeDiary()]),
        ),
      );
      await tester.pumpAndSettle();

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.dense, true);
      expect(tile.visualDensity, VisualDensity.compact);
    });

    testWidgets('con un solo diario mostra esattamente una Card', (tester) async {
      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'Lista', diaries: [makeDiary()]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });
  });


  group('DiaryListPage – pulsante Indietro', () {
    testWidgets('il pulsante è un ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('il testo del pulsante ha fontSize 11', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final btnText = tester.widget<Text>(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(Text),
        ),
      );
      expect(btnText.style?.fontSize, 11);
    });

    testWidgets('il pulsante ha forma StadiumBorder', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final shape = btn.style?.shape?.resolve({});
      expect(shape, isA<StadiumBorder>());
    });

    testWidgets('backgroundColor del pulsante è uguale al primaryColor del tema',
        (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      );

      await tester.pumpWidget(
        buildApp(
          DiaryListPage(title: 'T', diaries: const []),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bgColor = btn.style?.backgroundColor?.resolve({});
      expect(bgColor, theme.colorScheme.primary);
    });

    testWidgets('foregroundColor del pulsante è Colors.white', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final fgColor = btn.style?.foregroundColor?.resolve({});
      expect(fgColor, Colors.white);
    });

    testWidgets('minimumSize del pulsante è Size(0, 30)', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final minSize = btn.style?.minimumSize?.resolve({});
      expect(minSize, const Size(0, 30));
    });

    testWidgets('il pulsante è dentro un Padding con horizontal 20',
        (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final paddingFinder = find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsWidgets);

      final directPadding = tester.widget<Padding>(paddingFinder.first);
      expect(
        directPadding.padding,
        const EdgeInsets.symmetric(horizontal: 20),
      );
    });

    testWidgets('tap sul pulsante Indietro esegue Navigator.pop', (tester) async {
      await tester.pumpWidget(
        buildAppWithPreviousRoute(
          DiaryListPage(title: 'Lista', diaries: const []),
        ),
      );
      await tester.pumpAndSettle();


      await tester.tap(find.byKey(const Key('open_list')));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryListPage), findsOneWidget);


      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

 
      expect(find.byType(DiaryListPage), findsNothing);
      expect(find.byKey(const Key('open_list')), findsOneWidget);
    });

    testWidgets('usa back_label da AppLocalizations', (tester) async {
      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'T', diaries: const [])),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(DiaryListPage));
      final local = AppLocalizations.of(context)!;

      expect(find.text(local.back_label), findsOneWidget);
    });
  });


  group('DiaryListPage – navigazione verso DiaryPage', () {
    testWidgets('tap su un diario naviga a DiaryPage', (tester) async {
      final diary = makeDiary(trekkigName: 'Rifugio Torino');

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: [diary])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryPage), findsOneWidget);
    });

    testWidgets('tap sul secondo diario apre DiaryPage', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1', trekkigName: 'Primo'),
        makeDiary(diaryId: '2', trekkigName: 'Secondo'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Secondo'));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryPage), findsOneWidget);
    });

    testWidgets('tap su diversi diari naviga correttamente', (tester) async {
      final diaries = [
        makeDiary(diaryId: '1', trekkigName: 'Alpha'),
        makeDiary(diaryId: '2', trekkigName: 'Beta'),
        makeDiary(diaryId: '3', trekkigName: 'Gamma'),
      ];

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Lista', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gamma'));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryPage), findsOneWidget);
    });

    testWidgets('dopo navigazione è possibile tornare a DiaryListPage',
        (tester) async {
      final diary = makeDiary();

      await tester.pumpWidget(
        buildAppWithPreviousRoute(
          DiaryListPage(title: 'Lista', diaries: [diary]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_list')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryPage), findsOneWidget);

      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(DiaryListPage), findsOneWidget);
    });
  });


  group('DiaryListPage – scroll', () {
    testWidgets('lista con 15 diari è scrollabile senza overflow', (tester) async {
      final diaries = List.generate(
        15,
        (i) => makeDiary(
          diaryId: 'id-$i',
          trekkigName: 'Sentiero $i',
          date: '2024-0${(i % 9) + 1}-01',
        ),
      );

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Molti', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('il pulsante Indietro rimane accessibile dopo lo scroll',
        (tester) async {
      final diaries = List.generate(
        20,
        (i) => makeDiary(diaryId: 'id-$i', trekkigName: 'Trek $i'),
      );

      await tester.pumpWidget(
        buildApp(DiaryListPage(title: 'Molti', diaries: diaries)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
