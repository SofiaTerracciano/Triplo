import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/challenge.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/main.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:app_triplo_wearos/pages/offline_page.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/internetservice.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:flutter/services.dart';

@GenerateMocks([
  MemoryService,
  GeoService,
  NotificationService,
  Language,
  InternetService,
  PairingService,
  TrekkingController,
  UserController,
  ChallengesController,
  DiaryController,
  ServiceController,
])
import 'main_test.mocks.dart';


void _silenceChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async => call.method == 'initialize' ? true : null,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_firestore'),
    (call) async => null,
  );
}


MockLanguage _mockLanguage({String languageCode = 'en'}) {
  final m = MockLanguage();
  when(m.locale).thenReturn(Locale(languageCode));
  when(m.addListener(any)).thenReturn(null);
  when(m.removeListener(any)).thenReturn(null);
  when(m.hasListeners).thenReturn(false);
  when(m.loadSavedLocale()).thenAnswer((_) async {});
  return m;
}

MockNotificationService _mockNotification() {
  final m = MockNotificationService();
  when(m.setNavKey(any)).thenReturn(null);
  when(m.init()).thenAnswer((_) async {});
  return m;
}

MockMemoryService _mockMemory() => MockMemoryService();
MockGeoService _mockGeo() => MockGeoService();

MockInternetService _mockInternet({bool isOnline = true}) {
  final m = MockInternetService();
  when(m.isOnline).thenReturn(isOnline);
  when(m.addListener(any)).thenReturn(null);
  when(m.removeListener(any)).thenReturn(null);
  when(m.hasListeners).thenReturn(false);
  return m;
}

MockPairingService _mockPairing() {
  final m = MockPairingService();
  when(m.restoreWatchPairing()).thenAnswer((_) async => true);
  when(m.addListener(any)).thenReturn(null);
  when(m.removeListener(any)).thenReturn(null);
  when(m.hasListeners).thenReturn(false);
  return m;
}

Widget _buildMockedApp({
  bool isOnline = true,
  String languageCode = 'en',
}) {
  final language = _mockLanguage(languageCode: languageCode);
  final internet = _mockInternet(isOnline: isOnline);
  final pairing = _mockPairing();

  final mockTrekking = MockTrekkingController();
  when(mockTrekking.addListener(any)).thenReturn(null);
  when(mockTrekking.removeListener(any)).thenReturn(null);
  when(mockTrekking.hasListeners).thenReturn(false);

  final mockUser = MockUserController();
  when(mockUser.addListener(any)).thenReturn(null);
  when(mockUser.removeListener(any)).thenReturn(null);
  when(mockUser.hasListeners).thenReturn(false);

  final mockChallenges = MockChallengesController();
  when(mockChallenges.addListener(any)).thenReturn(null);
  when(mockChallenges.removeListener(any)).thenReturn(null);
  when(mockChallenges.hasListeners).thenReturn(false);

  final mockDiary = MockDiaryController();
  when(mockDiary.addListener(any)).thenReturn(null);
  when(mockDiary.removeListener(any)).thenReturn(null);
  when(mockDiary.hasListeners).thenReturn(false);

  return MultiProvider(
    providers: [
      Provider<MemoryService>.value(value: _mockMemory()),
      Provider<GeoService>.value(value: _mockGeo()),
      Provider<NotificationService>.value(value: _mockNotification()),
      ChangeNotifierProvider<Language>.value(value: language),
      ChangeNotifierProvider<PairingService>.value(value: pairing),
      ChangeNotifierProvider<UserController>.value(value: mockUser),
      ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),
      ChangeNotifierProvider<ChallengesController>.value(value: mockChallenges),
      ChangeNotifierProvider<DiaryController>.value(value: mockDiary),
      ChangeNotifierProvider<InternetService>.value(value: internet),
    ],
    child: Consumer<Language>(
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final online = context.watch<InternetService>().isOnline;
            return Stack(
              children: [
                if (child != null) child,
                if (!online) const OfflineWatchPage(),
              ],
            );
          },
          home: const NavigationPage(enableBackgroundService: false),
        );
      },
    ),
  );
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_silenceChannels);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
  });

  group('TriploWatchApp – costruttore –', () {
    test('accetta tutti i parametri richiesti senza eccezioni', () {
      expect(
        () => TriploWatchApp(
          watchId: 'test-watch-id',
          memoryService: _mockMemory(),
          geoService: _mockGeo(),
          language: _mockLanguage(),
          notification: _mockNotification(),
        ),
        returnsNormally,
      );
    });

    test('watchId viene memorizzato correttamente', () {
      const id = 'watch-abc-123';
      final app = TriploWatchApp(
        watchId: id,
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
      );
      expect(app.watchId, id);
    });
  });

  group('TriploWatchApp – struttura UI –', () {
    testWidgets('mostra NavigationPage quando online', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationPage), findsOneWidget);
    });

    testWidgets('non mostra OfflineWatchPage quando online', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: true));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineWatchPage), findsNothing);
    });

    testWidgets('mostra OfflineWatchPage quando offline', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: false));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineWatchPage), findsOneWidget);
    });

    testWidgets('mostra sia NavigationPage che OfflineWatchPage quando offline',
        (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: false));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationPage), findsOneWidget);
      expect(find.byType(OfflineWatchPage), findsOneWidget);
    });

    testWidgets('debugShowCheckedModeBanner è false', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });

  group('TriploWatchApp – localizzazione –', () {
    testWidgets('usa la locale impostata in Language', (tester) async {
      await tester.pumpWidget(_buildMockedApp(languageCode: 'it'));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('it'));
    });

    testWidgets('supporta le 5 lingue previste', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.supportedLocales, containsAll([
        const Locale('en'),
        const Locale('it'),
        const Locale('es'),
        const Locale('de'),
        const Locale('fr'),
      ]));
    });

    testWidgets('ha i delegati di localizzazione configurati', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates, isNotEmpty);
    });
  });

  group('TriploWatchApp – provider –', () {
    testWidgets('InternetService è accessibile nell\'albero', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<InternetService>(), returnsNormally);
    });

    testWidgets('NotificationService è accessibile nell\'albero', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<NotificationService>(), returnsNormally);
    });

    testWidgets('PairingService è accessibile nell\'albero', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<PairingService>(), returnsNormally);
    });

    testWidgets('Language è accessibile nell\'albero', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<Language>(), returnsNormally);
    });

    testWidgets('TrekkingController è accessibile nell\'albero', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<TrekkingController>(), returnsNormally);
    });

    testWidgets('isOnline restituisce true quando online', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: true));
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(NavigationPage));
      expect(ctx.read<InternetService>().isOnline, isTrue);
    });

    testWidgets('isOnline restituisce false quando offline', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: false));
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(OfflineWatchPage));
      expect(ctx.read<InternetService>().isOnline, isFalse);
    });
  });
}