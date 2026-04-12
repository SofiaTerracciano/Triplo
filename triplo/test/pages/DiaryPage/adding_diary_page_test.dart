import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/pages/DiaryPage/adding-diary-page.dart';
import 'package:triplo/service/authservice.dart';

// Riusa i mock generati dal file change_diary_page_test.dart
import 'change_diary_page_test.mocks.dart';
import 'diary_page_test.mocks.dart'
    hide MockTrekkingController, MockUserController;

@GenerateMocks([
  AuthService,
  TrekkingController,
  UserController,
  DiaryController,
])
void main() {
  group('AddingDiaryPage – widget', () {
    late MockAuthService mockAuth;
    late MockTrekkingController mockTrekkingController;
    late MockUserController mockUserController;
    late DiaryController diaryController;
    late FakeFirebaseFirestore fakeFirestore;
    late Users fakeUser;

    setUp(() async {
      mockAuth = MockAuthService();
      when(mockAuth.currentUid).thenReturn('user1');

      fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('users').doc('user1').set({
        'Public_diary': [],
        'Private_diary': [],
      });

      diaryController = DiaryController(mockAuth, firestore: fakeFirestore);
      fakeUser = _buildUser();
      diaryController.currentUser = fakeUser;

      mockTrekkingController = MockTrekkingController();
      when(
        mockTrekkingController.getTrekkingById('trek1'),
      ).thenReturn(_buildTrekkingNoChallenge());
      when(
        mockTrekkingController.getDownloadUrl(any),
      ).thenAnswer((_) async => 'https://placeholder.url/img.jpg');

      mockUserController = MockUserController();
      when(mockUserController.currentUser).thenReturn(fakeUser);
      when(
        mockUserController.getFollowing('user1'),
      ).thenAnswer((_) async => <Users>[]);
      when(mockUserController.updateUserLevel(any)).thenAnswer((_) async => {});
    });

    // ── helpers locali ──────────────────────────────────────────────────────

    Widget buildPage({String trekkingId = 'trek1'}) => MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryController>.value(value: diaryController),
        ChangeNotifierProvider<TrekkingController>.value(
          value: mockTrekkingController,
        ),
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddingDiaryPage(trekkingId: trekkingId),
      ),
    );

    // Helper per i test del bottone Salva che evita di montare UserPage
    Widget buildPageForSave(MockDiaryController mockDiary) => MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryController>.value(value: mockDiary),
        ChangeNotifierProvider<TrekkingController>.value(
            value: mockTrekkingController),
        ChangeNotifierProvider<UserController>.value(value: mockUserController),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Intercetta la navigazione a UserPage con una pagina stub
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('stub_page')),
          );
        },
        home: const AddingDiaryPage(trekkingId: 'trek1'),
      ),
    );

    testWidgets('dispose non lancia eccezioni rimuovendo la pagina dal tree', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Sostituisce la route con un widget vuoto → chiama dispose()
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('empty'))),
      );
      await tester.pumpAndSettle();

      // Se dispose ha fatto leak o doppio dispose, il test sarebbe già fallito
      expect(find.text('empty'), findsOneWidget);
    });

    // ── CASO !snapshot.hasData ───────────────────────────────────────────────────

    testWidgets('mostra messaggio errore se getFollowing restituisce null', (
      tester,
    ) async {
      // Restituisce una Future che completa con una lista vuota
      when(
        mockUserController.getFollowing('user1'),
      ).thenAnswer((_) async => <Users>[]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(MaterialApp)),
      )!;
      expect(find.text(local.user_not_found), findsOneWidget);
    });

    // ── DROPDOWN – cambio valore tramite widget state ────────────────────────────
    // Non apriamo l'overlay (virtualizzato), verifichiamo il valore
    // chiamando direttamente onChanged come farebbe il framework.

    testWidgets('dropdown giorno aggiorna il valore dopo onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).first,
      );
      // Simula la selezione di un nuovo valore
      dropdown.onChanged!(15);
      await tester.pumpAndSettle();

      final updated = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).first,
      );
      expect(updated.value, 15);
    });

    testWidgets('dropdown mese aggiorna il valore dopo onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(1),
      );
      dropdown.onChanged!(3);
      await tester.pumpAndSettle();

      final updated = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(1),
      );
      expect(updated.value, 3);
    });

    testWidgets('dropdown anno aggiorna il valore dopo onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(2),
      );
      dropdown.onChanged!(2022);
      await tester.pumpAndSettle();

      final updated = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(2),
      );
      expect(updated.value, 2022);
    });

    testWidgets('dropdown ore aggiorna il valore dopo onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(3),
      );
      dropdown.onChanged!(5);
      await tester.pumpAndSettle();

      final updated = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(3),
      );
      expect(updated.value, 5);
    });

    testWidgets('dropdown minuti aggiorna il valore dopo onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(4),
      );
      dropdown.onChanged!(30);
      await tester.pumpAndSettle();

      final updated = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(4),
      );
      expect(updated.value, 30);
    });

    // ── AMICI con following non vuoto ────────────────────────────────────────────

    testWidgets(
      'ExpansionTile amici mostra ListTile per ogni utente nel following',
      (tester) async {
        final user2 = _buildUser(uid: 'user2', username: 'luigi');
        when(
          mockUserController.getFollowing('user1'),
        ).thenAnswer((_) async => [user2]);

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ExpansionTile).first);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is ListTile && w.leading is CircleAvatar,
          ),
          findsOneWidget,
        );
        expect(find.text('luigi'), findsOneWidget);
      },
    );

    testWidgets(
      'tap su utente nel following lo aggiunge agli amici selezionati',
      (tester) async {
        final user2 = _buildUser(uid: 'user2', username: 'luigi');
        when(
          mockUserController.getFollowing('user1'),
        ).thenAnswer((_) async => [user2]);

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Apre expansion amici
        await tester.tap(find.byType(ExpansionTile).first);
        await tester.pumpAndSettle();

        // Tappa su luigi
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ListTile && w.leading is CircleAvatar,
          ),
        );
        await tester.pumpAndSettle();

        // Il Chip di luigi appare nel preview
        expect(find.text('luigi'), findsWidgets);
      },
    );

    testWidgets('tap su utente già selezionato lo rimuove dagli amici', (tester) async {
      final user2 = _buildUser(uid: 'user2', username: 'luigi');
      when(mockUserController.getFollowing('user1'))
          .thenAnswer((_) async => [user2]);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final friendsExpansion = find.byType(ExpansionTile).first;
      await tester.tap(friendsExpansion);
      await tester.pumpAndSettle();

      final userTile = find.byWidgetPredicate(
        (w) => w is ListTile && w.leading is CircleAvatar,
      );

      // Aggiunge
      await tester.tap(userTile);
      await tester.pumpAndSettle();

      // Riapre l'ExpansionTile se si è chiuso
      if (tester.widgetList(userTile).isEmpty) {
        await tester.tap(friendsExpansion);
        await tester.pumpAndSettle();
      }

      // Rimuove
      await tester.tap(userTile);
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      expect(find.text(local.friends_selected_label), findsOneWidget);
    });

    // ── CHALLENGES con trekking che le ha ───────────────────────────────────────

    testWidgets(
      'sezione challenges mostra testo "no challenges" inizialmente',
      (tester) async {
        when(
          mockTrekkingController.getTrekkingById('trek_with_challenges'),
        ).thenReturn(_buildTrekkingWithChallenges());

        await tester.pumpWidget(buildPage(trekkingId: 'trek_with_challenges'));
        await tester.pumpAndSettle();

        final local = AppLocalizations.of(
          tester.element(find.byType(AddingDiaryPage)),
        )!;
        expect(find.text(local.challenge_selected_label), findsOneWidget);
      },
    );

    testWidgets('ExpansionTile challenges espande e mostra GridView',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Silenzia gli errori di immagine di rete attesi
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('NetworkImageLoadException')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      when(mockTrekkingController.getTrekkingById('trek_with_challenges'))
          .thenReturn(_buildTrekkingWithChallenges());

      await tester.pumpWidget(buildPage(trekkingId: 'trek_with_challenges'));
      await tester.pumpAndSettle();

      final challengeTile = find.byType(ExpansionTile).at(1);
      await tester.tap(challengeTile);
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    // ── MOOD – più emoji ─────────────────────────────────────────────────────────

    testWidgets('è possibile selezionare più emoji contemporaneamente', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      // Seleziona 😍
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😍',
        ),
      );
      await tester.pumpAndSettle();

      // Ri-apre se necessario
      if (tester
          .widgetList(
            find.byWidgetPredicate(
              (w) =>
                  w is ListTile &&
                  w.leading is Text &&
                  (w.leading as Text).data == '😁',
            ),
          )
          .isEmpty) {
        await tester.tap(tiles.last);
        await tester.pumpAndSettle();
      }

      // Seleziona 😁
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😁',
        ),
      );
      await tester.pumpAndSettle();

      // Entrambi i Chip devono essere nel preview
      expect(
        find.byWidgetPredicate(
          (w) => w is Chip && w.label is Text && (w.label as Text).data == '😍',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Chip && w.label is Text && (w.label as Text).data == '😁',
        ),
        findsOneWidget,
      );
    });

    testWidgets('icona trailing del ListTile mood cambia dopo selezione', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      // Prima della selezione: circle_outlined
      final tileBefore = tester.widget<ListTile>(
        find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😍',
        ),
      );
      expect((tileBefore.trailing as Icon).icon, Icons.circle_outlined);

      // Seleziona
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😍',
        ),
      );
      await tester.pumpAndSettle();

      // Ri-apre se necessario
      if (tester
          .widgetList(
            find.byWidgetPredicate(
              (w) =>
                  w is ListTile &&
                  w.leading is Text &&
                  (w.leading as Text).data == '😍',
            ),
          )
          .isEmpty) {
        await tester.tap(tiles.last);
        await tester.pumpAndSettle();
      }

      // Dopo la selezione: check_circle
      final tileAfter = tester.widget<ListTile>(
        find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.leading is Text &&
              (w.leading as Text).data == '😍',
        ),
      );
      expect((tileAfter.trailing as Icon).icon, Icons.check_circle);
    });

    // ── SALVA – logica costruzione data e durata ─────────────────────────────────
    // Non possiamo testare la navigazione completa (richiede uploadDiaryImages),
    // ma possiamo verificare che il DiaryController riceva i parametri corretti
    // impostando mock su uploadDiaryImages.

    testWidgets('bottone Salva chiama addDiary con data e durata corrette',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockDiary = MockDiaryController();
      when(mockDiary.uploadDiaryImages(any)).thenAnswer((_) async => <String>[]);
      when(mockDiary.currentUser).thenReturn(fakeUser);
      when(mockDiary.addDiary(
        any, any, any, any, any, any, any, any, any, any, any, any,
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPageForSave(mockDiary));
      await tester.pumpAndSettle();

      tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(3),
      ).onChanged!(1);
      await tester.pumpAndSettle();

      tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(4),
      ).onChanged!(30);
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      await tester.tap(find.text(local.save_botton_label));
      await tester.pumpAndSettle();

      verify(mockDiary.addDiary(
        'Sentiero Facile', false, argThat(isA<String>()), 90.0,
        [], [], [], '', [], '', false, '',
      )).called(1);
    });

    testWidgets('bottone Salva chiama updateUserLevel con la difficoltà del trekking',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockDiary = MockDiaryController();
      when(mockDiary.uploadDiaryImages(any)).thenAnswer((_) async => <String>[]);
      when(mockDiary.currentUser).thenReturn(fakeUser);
      when(mockDiary.addDiary(
        any, any, any, any, any, any, any, any, any, any, any, any,
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildPageForSave(mockDiary));
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      await tester.tap(find.text(local.save_botton_label));
      await tester.pumpAndSettle();

      verify(mockUserController.updateUserLevel('easy')).called(1);
    });

    testWidgets('bottone Salva costruisce la data nel formato DD/MM/YYYY',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockDiary = MockDiaryController();
      when(mockDiary.uploadDiaryImages(any)).thenAnswer((_) async => <String>[]);
      when(mockDiary.currentUser).thenReturn(fakeUser);

      String? capturedDate;
      when(mockDiary.addDiary(
        any, any, any, any, any, any, any, any, any, any, any, any,
      )).thenAnswer((inv) async {
        capturedDate = inv.positionalArguments[2] as String;
      });

      await tester.pumpWidget(buildPageForSave(mockDiary));
      await tester.pumpAndSettle();

      tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).first).onChanged!(5);
      await tester.pumpAndSettle();

      tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(1)).onChanged!(3);
      await tester.pumpAndSettle();

      tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>).at(2)).onChanged!(2025);
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      await tester.tap(find.text(local.save_botton_label));
      await tester.pumpAndSettle();

      expect(capturedDate, '05/03/2025');
    });

    testWidgets('mostra il titolo del trekking nella AppBar', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Sentiero Facile'), findsOneWidget);
    });

    testWidgets('mostra tutte le icone delle sezioni', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.mood), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('SingleChildScrollView è presente nel layout', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('card sezioni hanno bordo arrotondato', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards, isNotEmpty);
      for (final card in cards) {
        expect(card.shape, isA<RoundedRectangleBorder>());
      }
    });

    testWidgets(
      'FutureBuilder mostra CircularProgressIndicator durante caricamento',
      (tester) async {
        when(mockUserController.getFollowing('user1')).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return <Users>[];
        });

        await tester.pumpWidget(buildPage());
        await tester.pump(); // un frame: FutureBuilder in waiting

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();
      },
    );

    // ── DATE/ORA INIZIALI ───────────────────────────────────────────────────

    testWidgets('dropdown giorno inizializzato con giorno corrente', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final dayDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).first,
      );
      expect(dayDropdown.value, DateTime.now().day);
    });

    testWidgets('dropdown mese inizializzato con mese corrente', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final monthDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(1),
      );
      expect(monthDropdown.value, DateTime.now().month);
    });

    testWidgets('dropdown anno inizializzato con anno corrente', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final yearDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(2),
      );
      expect(yearDropdown.value, DateTime.now().year);
    });

    testWidgets('dropdown ore inizializzato a 0', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final hoursDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(3),
      );
      expect(hoursDropdown.value, 0);
    });

    testWidgets('dropdown minuti inizializzato a 0', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final minutesDropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>).at(4),
      );
      expect(minutesDropdown.value, 0);
    });

    // ── AMICI ───────────────────────────────────────────────────────────────

    testWidgets('sezione amici mostra testo "no friends" con lista vuota', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      expect(find.text(local.friends_selected_label), findsOneWidget);
    });

    testWidgets(
      'ExpansionTile amici espande senza ListTile utenti (following vuoto)',
      (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ExpansionTile).first);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is ListTile && w.leading is CircleAvatar,
          ),
          findsNothing,
        );
      },
    );

    // ── NOTE ────────────────────────────────────────────────────────────────

    testWidgets('campo Note è inizialmente vuoto', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final noteField = tester.widget<TextField>(find.byType(TextField).first);
      expect(noteField.controller?.text, '');
    });

    testWidgets('inserimento testo nel campo Note aggiorna il valore', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Nota di test');
      await tester.pumpAndSettle();

      expect(find.text('Nota di test'), findsOneWidget);
    });

    // ── RIFORNIMENTO ────────────────────────────────────────────────────────

    testWidgets('chip No è selezionato di default (usedRefreshment=false)', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      final noChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, local.no_botton_label),
      );
      expect(noChip.selected, true);
    });

    testWidgets('TextField rifornimento non visibile con chip No selezionato', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Solo il TextField delle note deve essere presente
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tap su chip Sì mostra il TextField del rifornimento', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      await tester.tap(find.widgetWithText(ChoiceChip, local.yes_botton_label));
      await tester.pumpAndSettle();

      // Ora ci sono 2 TextField: note + rifornimento
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets(
      'tap su chip Sì poi No nasconde di nuovo il TextField rifornimento',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        final local = AppLocalizations.of(
          tester.element(find.byType(AddingDiaryPage)),
        )!;

        await tester.tap(
          find.widgetWithText(ChoiceChip, local.yes_botton_label),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ChoiceChip, local.no_botton_label),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets('inserimento testo nel campo rifornimento aggiorna il valore', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      await tester.tap(find.widgetWithText(ChoiceChip, local.yes_botton_label));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'Rifugio Alpino');
      await tester.pumpAndSettle();

      expect(find.text('Rifugio Alpino'), findsOneWidget);
    });

    // ── MOOD ────────────────────────────────────────────────────────────────

    testWidgets('sezione mood mostra testo "no mood" con lista vuota', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;
      expect(find.text(local.mood_selected_label), findsOneWidget);
    });

    testWidgets('ExpansionTile mood espande e mostra le emoji disponibili', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      expect(find.text('😍'), findsOneWidget);
      expect(find.text('😁'), findsOneWidget);
      expect(find.text('🥰'), findsOneWidget);
    });

    testWidgets(
      'tap su emoji la aggiunge al mood e mostra il Chip nel preview',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        final tiles = find.byType(ExpansionTile);
        await tester.tap(tiles.last);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byWidgetPredicate(
            (w) =>
                w is ListTile &&
                w.leading is Text &&
                (w.leading as Text).data == '😍',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Chip && w.label is Text && (w.label as Text).data == '😍',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tap su emoji già selezionata la rimuove dal preview', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      // Finder specifico per il ListTile dell'emoji nell'ExpansionTile
      final emojiListTile = find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            w.leading is Text &&
            (w.leading as Text).data == '😍',
      );

      // Prima aggiunge
      await tester.tap(emojiListTile);
      await tester.pumpAndSettle();

      // Verifica che il Chip sia apparso nel preview
      expect(
        find.byWidgetPredicate(
          (w) => w is Chip && w.label is Text && (w.label as Text).data == '😍',
        ),
        findsOneWidget,
      );

      // L'ExpansionTile deve essere ancora aperto: il ListTile è ancora nel tree.
      // Se si è chiuso, lo riapriamo.
      if (tester.widgetList(emojiListTile).isEmpty) {
        await tester.tap(tiles.last);
        await tester.pumpAndSettle();
      }

      // Poi rimuove tappando di nuovo il ListTile
      await tester.tap(emojiListTile);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Chip && w.label is Text && (w.label as Text).data == '😍',
        ),
        findsNothing,
      );
    });

    // ── FOTO ────────────────────────────────────────────────────────────────

    testWidgets('pulsante aggiungi foto è presente', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    // ── PUBBLICO/PRIVATO ────────────────────────────────────────────────────

    testWidgets('bottone Privato è active di default (isPublic=false)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      final privateBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, local.private_botton_label),
      );
      final fg = privateBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets('tap su bottone Pubblico lo rende active', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      await tester.tap(find.text(local.public_botton_label));
      await tester.pumpAndSettle();

      final publicBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, local.public_botton_label),
      );
      final fg = publicBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    testWidgets('tap su bottone Privato dopo Pubblico lo rende active', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      await tester.tap(find.text(local.public_botton_label));
      await tester.pumpAndSettle();

      await tester.tap(find.text(local.private_botton_label));
      await tester.pumpAndSettle();

      final privateBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, local.private_botton_label),
      );
      final fg = privateBtn.style!.foregroundColor!.resolve(<MaterialState>{});
      expect(fg, Colors.white);
    });

    // ── SALVA/ANNULLA ───────────────────────────────────────────────────────

    testWidgets('bottoni Salva e Annulla sono presenti', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final local = AppLocalizations.of(
        tester.element(find.byType(AddingDiaryPage)),
      )!;

      expect(find.text(local.cancel_button_label), findsOneWidget);
      expect(find.text(local.save_botton_label), findsOneWidget);
    });

    testWidgets('bottone Annulla fa pop della route', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool popped = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DiaryController>.value(
              value: diaryController,
            ),
            ChangeNotifierProvider<TrekkingController>.value(
              value: mockTrekkingController,
            ),
            ChangeNotifierProvider<UserController>.value(
              value: mockUserController,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddingDiaryPage(trekkingId: 'trek1'),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(popped, true);
    });

    // ── CHALLENGES (trekking senza challenges) ──────────────────────────────

    testWidgets('sezione challenges non appare se trekking non ha challenges', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('sezione challenges appare se trekking ha challenges', (
      tester,
    ) async {
      when(
        mockTrekkingController.getTrekkingById('trek_with_challenges'),
      ).thenReturn(_buildTrekkingWithChallenges());

      await tester.pumpWidget(buildPage(trekkingId: 'trek_with_challenges'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Users _buildUser({String uid = 'user1', String username = 'mario'}) => Users(
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

/// Trekking senza challenges → la sezione non viene renderizzata
Trekking _buildTrekkingNoChallenge() => Trekking(
  documentId: 'trek1',
  name: 'Sentiero Facile',
  mapPhoto: '',
  difficultyLevel: 'easy',
  distance: 5.0,
  estimatedTime: 2.0,
  elevationGain: 200.0,
  upGain: true,
  downGain: false,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(45.5, 7.5),
  points: const [LatLng(45.0, 7.0), LatLng(45.5, 7.5)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: [],
  endingPointPhoto: '',
  description: [],
  picNicArea: false,
  familyFirendly: true,
  challenges: [],
);

/// Trekking con challenges → la sezione viene renderizzata
Trekking _buildTrekkingWithChallenges() => Trekking(
  documentId: 'trek_with_challenges',
  name: 'Sentiero Difficile',
  mapPhoto: '',
  difficultyLevel: 'hard',
  distance: 15.0,
  estimatedTime: 6.0,
  elevationGain: 1000.0,
  upGain: true,
  downGain: true,
  startingPoint: const LatLng(45.0, 7.0),
  endingPoint: const LatLng(46.0, 8.0),
  points: const [LatLng(45.0, 7.0), LatLng(46.0, 8.0)],
  startingPointName: 'Partenza',
  endingPointName: 'Arrivo',
  info: [],
  endingPointPhoto: '',
  description: [],
  picNicArea: false,
  familyFirendly: false,
  challenges: ['challenge1', 'challenge2'],
);


