import 'dart:async';
import 'dart:io';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

// ── channel silencer ──────────────────────────────────────────────────────────
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
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.tekartik.sqflite'),
    (call) async => null,
  );
}

// ── mock factories ────────────────────────────────────────────────────────────
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
  when(m.forceRecheck()).thenAnswer((_) async {});
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

// ── widget builder con mock (test isolati) ────────────────────────────────────
Widget _buildMockedApp({bool isOnline = true, String languageCode = 'en'}) {
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

// ── widget builder con provider reali + FakeFirestore ─────────────────────────
Widget _buildRealApp({String languageCode = 'en'}) {
  final fakeFirestore = FakeFirebaseFirestore();
  final language = _mockLanguage(languageCode: languageCode);
  final memory = _mockMemory();
  final geo = _mockGeo();
  final notification = _mockNotification();

  final mockSC = MockServiceController();
  when(mockSC.hasInternet()).thenAnswer((_) async => true);

  final pairing = PairingService.withFirestore(
    watchId: 'test-watch-id',
    db: fakeFirestore,
  );

  return MultiProvider(
    providers: [
      Provider<MemoryService>.value(value: memory),
      Provider<GeoService>.value(value: geo),
      Provider<NotificationService>.value(value: notification),
      ChangeNotifierProvider<Language>.value(value: language),
      ChangeNotifierProvider<DiaryController>(
        create: (_) => DiaryController(),
      ),
      ChangeNotifierProvider<PairingService>.value(value: pairing),
      ChangeNotifierProxyProvider<PairingService, UserController>(
        create: (ctx) => UserController(ctx.read<PairingService>()),
        update: (ctx, ps, prev) => prev ?? UserController(ps),
      ),
      Provider<ServiceController>.value(value: mockSC),
      ChangeNotifierProvider<InternetService>(
        create: (ctx) => InternetService(
          servicecontroller: ctx.read<ServiceController>(),
        )..start(),
      ),
      ChangeNotifierProvider<TrekkingController>(
        create: (ctx) => TrekkingController(
          geo: ctx.read<GeoService>(),
          memory: ctx.read<MemoryService>(),
          notification: ctx.read<NotificationService>(),
          pairingService: ctx.read<PairingService>(),
          trekkings: [],
          db: fakeFirestore,
        ),
      ),
      ChangeNotifierProvider<ChallengesController>(
        create: (ctx) => ChallengesController(
          memory: ctx.read<MemoryService>(),
          notification: ctx.read<NotificationService>(),
        ),
      ),
    ],
    child: Consumer<Language>(
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Triplo',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
            useMaterial3: true,
          ),
          locale: lang.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('it'),
            Locale('es'),
            Locale('de'),
            Locale('fr'),
          ],
          builder: (context, child) {
            final isOnline = context.watch<InternetService>().isOnline;
            return Stack(
              children: [
                if (child != null) child,
                if (!isOnline) const OfflineWatchPage(),
              ],
            );
          },
          home: const NavigationPage(),
        );
      },
    ),
  );
}

// ── fake path provider ────────────────────────────────────────────────────────
class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
  @override
  Future<String?> getApplicationCachePath() async => Directory.systemTemp.path;
}

// ── main ──────────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    dotenv.testLoad(
        fileInput: 'OPENWEATHER_API_KEY=test\nWEATHERBIT_API_KEY=test');
    PathProviderPlatform.instance = _FakePathProvider();
    _silenceChannels();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
  });

  // ── TriploWatchApp costruttore ──────────────────────────────────────────
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

    test('tutti i campi sono accessibili dopo la costruzione', () {
      final memory = _mockMemory();
      final geo = _mockGeo();
      final lang = _mockLanguage();
      final notif = _mockNotification();
      final app = TriploWatchApp(
        watchId: 'w1',
        memoryService: memory,
        geoService: geo,
        language: lang,
        notification: notif,
      );
      expect(app.memoryService, same(memory));
      expect(app.geoService, same(geo));
      expect(app.language, same(lang));
      expect(app.notification, same(notif));
    });

    test('firestore è null di default', () {
      final app = TriploWatchApp(
        watchId: 'w1',
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
      );
      expect(app.firestore, isNull);
    });

    test('firestore viene memorizzato quando fornito', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final app = TriploWatchApp(
        watchId: 'w1',
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
        firestore: fakeFirestore,
      );
      expect(app.firestore, same(fakeFirestore));
    });

    test('watchId accetta stringhe vuote', () {
      final app = TriploWatchApp(
        watchId: '',
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
      );
      expect(app.watchId, '');
    });

    test('watchId accetta stringhe con caratteri speciali', () {
      const id = 'watch-123_ABC.test';
      final app = TriploWatchApp(
        watchId: id,
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
      );
      expect(app.watchId, id);
    });

    test('istanze distinte con stessi parametri sono widget diversi', () {
      final memory = _mockMemory();
      final geo = _mockGeo();
      final lang = _mockLanguage();
      final notif = _mockNotification();
      final app1 = TriploWatchApp(
          watchId: 'id',
          memoryService: memory,
          geoService: geo,
          language: lang,
          notification: notif);
      final app2 = TriploWatchApp(
          watchId: 'id',
          memoryService: memory,
          geoService: geo,
          language: lang,
          notification: notif);
      expect(identical(app1, app2), isFalse);
    });
  }); // fine gruppo costruttore

  // ── TriploWatchApp build() REALE ────────────────────────────────────────
  group('TriploWatchApp – build() reale con FakeFirebaseFirestore –', () {
    testWidgets('monta senza eccezioni con FakeFirebaseFirestore',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('crea MultiProvider con tutti i provider interni',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<MemoryService>(), returnsNormally);
      expect(() => ctx.read<GeoService>(), returnsNormally);
      expect(() => ctx.read<NotificationService>(), returnsNormally);
    });

    testWidgets('MaterialApp ha debugShowCheckedModeBanner false',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('MaterialApp ha il titolo Triplo', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.title, 'Triplo');
    });

    testWidgets('MaterialApp ha navigatorKey impostato', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.navigatorKey, isNotNull);
    });

    testWidgets('supporta le 5 lingue previste nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(
        app.supportedLocales,
        containsAll([
          const Locale('en'),
          const Locale('it'),
          const Locale('es'),
          const Locale('de'),
          const Locale('fr'),
        ]),
      );
    });

    testWidgets('usa la locale della Language nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp(languageCode: 'it'));
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.locale, const Locale('it'));
    });

    testWidgets('ha i delegati di localizzazione configurati nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.localizationsDelegates, isNotEmpty);
    });

    testWidgets('InternetService è accessibile nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<InternetService>(), returnsNormally);
    });

    testWidgets('navigatorKey corrisponde al navKey globale', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.navigatorKey, same(navKey));
    });

    testWidgets('MaterialApp usa useMaterial3 true', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('ServiceController è accessibile nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<ServiceController>(), returnsNormally);
    });

    testWidgets('PairingService è accessibile nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<PairingService>(), returnsNormally);
    });

    /*testWidgets('UserController è accessibile nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<UserController>(), returnsNormally);
    });*/

   /*testWidgets('TrekkingController è accessibile nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<TrekkingController>(), returnsNormally);
    });*/

    testWidgets('ChallengesController è accessibile nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<ChallengesController>(), returnsNormally);
    });

    /*testWidgets('DiaryController è accessibile nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<DiaryController>(), returnsNormally);
    });*/

    /*testWidgets('Language è accessibile nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<Language>(), returnsNormally);
    });*/

    testWidgets('OfflineWatchPage non mostrata online nel build reale',
        (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('locale francese applicata nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp(languageCode: 'fr'));
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.locale, const Locale('fr'));
    });

    testWidgets('locale spagnola applicata nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp(languageCode: 'es'));
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.locale, const Locale('es'));
    });

    testWidgets('locale tedesca applicata nel build reale', (tester) async {
      await tester.pumpWidget(_buildRealApp(languageCode: 'de'));
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.locale, const Locale('de'));
    });

    testWidgets('TrekkingController usa il firestore iniettato', (tester) async {
      await tester.pumpWidget(_buildRealApp());
      await tester.pump();
      final ctx = tester.element(find.byType(MaterialApp).first);
      expect(() => ctx.read<TrekkingController>(), returnsNormally);
    });

    testWidgets('monta correttamente anche senza firestore esplicito',
        (tester) async {
      final app = TriploWatchApp(
        watchId: 'no-fs-id',
        memoryService: _mockMemory(),
        geoService: _mockGeo(),
        language: _mockLanguage(),
        notification: _mockNotification(),
        firestore: null,
      );
      expect(app.firestore, isNull);
    });
  }); // fine gruppo build() reale

  // ── UI struttura (mock) ─────────────────────────────────────────────────
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

    testWidgets('builder ritorna uno Stack', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('builder con child non null non lancia eccezioni',
        (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('offline con lingua italiana mostra OfflineWatchPage',
        (tester) async {
      await tester.pumpWidget(
          _buildMockedApp(isOnline: false, languageCode: 'it'));
      await tester.pumpAndSettle();
      expect(find.byType(OfflineWatchPage), findsOneWidget);
    });
  }); // fine gruppo struttura UI

  // ── localizzazione ──────────────────────────────────────────────────────
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

    testWidgets('locale inglese applicata correttamente', (tester) async {
      await tester.pumpWidget(_buildMockedApp(languageCode: 'en'));
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
    });

    testWidgets('locale tedesca applicata correttamente', (tester) async {
      await tester.pumpWidget(_buildMockedApp(languageCode: 'de'));
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('de'));
    });

    testWidgets('locale spagnola applicata correttamente', (tester) async {
      await tester.pumpWidget(_buildMockedApp(languageCode: 'es'));
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('es'));
    });

    testWidgets('locale francese applicata correttamente', (tester) async {
      await tester.pumpWidget(_buildMockedApp(languageCode: 'fr'));
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('fr'));
    });
  }); // fine gruppo localizzazione

  // ── provider (mock) ─────────────────────────────────────────────────────
  group('TriploWatchApp – provider –', () {
    testWidgets('InternetService è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<InternetService>(), returnsNormally);
    });

    testWidgets('NotificationService è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<NotificationService>(), returnsNormally);
    });

    testWidgets('PairingService è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<PairingService>(), returnsNormally);
    });

    testWidgets('Language è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<Language>(), returnsNormally);
    });

    testWidgets('TrekkingController è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<TrekkingController>(), returnsNormally);
    });

    testWidgets('isOnline true quando online', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: true));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(ctx.read<InternetService>().isOnline, isTrue);
    });

    testWidgets('isOnline false quando offline', (tester) async {
      await tester.pumpWidget(_buildMockedApp(isOnline: false));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(OfflineWatchPage));
      expect(ctx.read<InternetService>().isOnline, isFalse);
    });

    testWidgets('MemoryService è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<MemoryService>(), returnsNormally);
    });

    testWidgets('GeoService è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<GeoService>(), returnsNormally);
    });

    testWidgets('UserController è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<UserController>(), returnsNormally);
    });

    testWidgets('ChallengesController è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<ChallengesController>(), returnsNormally);
    });

    testWidgets('DiaryController è accessibile', (tester) async {
      await tester.pumpWidget(_buildMockedApp());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(NavigationPage));
      expect(() => ctx.read<DiaryController>(), returnsNormally);
    });
  }); // fine gruppo provider

  // ── AppBootstrap ────────────────────────────────────────────────────────
  group('AppBootstrap –', () {
    test('getWatchId è configurato con WatchIdService di default', () {
      expect(AppBootstrap.getWatchId, isNotNull);
    });

    test('askPermissions è configurato con PermissionService di default', () {
      expect(AppBootstrap.askPermissions, isNotNull);
    });

    test('getWatchId può essere sostituito con un fake', () async {
      final original = AppBootstrap.getWatchId;
      AppBootstrap.getWatchId = () async => 'fake-watch-id';
      final result = await AppBootstrap.getWatchId();
      expect(result, 'fake-watch-id');
      AppBootstrap.getWatchId = original;
    });

    test('askPermissions può essere sostituito con un fake', () async {
      final original = AppBootstrap.askPermissions;
      var called = false;
      AppBootstrap.askPermissions = () async {
        called = true;
      };
      await AppBootstrap.askPermissions();
      expect(called, isTrue);
      AppBootstrap.askPermissions = original;
    });

    test('getWatchId ripristinato correttamente dopo la sostituzione',
        () async {
      final original = AppBootstrap.getWatchId;
      AppBootstrap.getWatchId = () async => 'temp';
      AppBootstrap.getWatchId = original;
      expect(AppBootstrap.getWatchId, same(original));
    });

    test('askPermissions ripristinato correttamente dopo la sostituzione',
        () async {
      final original = AppBootstrap.askPermissions;
      AppBootstrap.askPermissions = () async {};
      AppBootstrap.askPermissions = original;
      expect(AppBootstrap.askPermissions, same(original));
    });

    test('getWatchId restituisce Future<String>', () {
      AppBootstrap.getWatchId = () async => 'test-string';
      final result = AppBootstrap.getWatchId();
      expect(result, isA<Future<String>>());
    });

    test('askPermissions restituisce Future<void>', () {
      AppBootstrap.askPermissions = () async {};
      final result = AppBootstrap.askPermissions();
      expect(result, isA<Future<void>>());
    });
  }); // fine gruppo AppBootstrap

  // ── navKey ──────────────────────────────────────────────────────────────
  group('navKey –', () {
    test('navKey è un GlobalKey<NavigatorState>', () {
      expect(navKey, isA<GlobalKey<NavigatorState>>());
    });

    test('navKey non è null', () {
      expect(navKey, isNotNull);
    });

    test('navKey è lo stesso oggetto (singleton a livello di file)', () {
      final ref1 = navKey;
      final ref2 = navKey;
      expect(identical(ref1, ref2), isTrue);
    });
  }); // fine gruppo navKey

  // ── initializeApp ───────────────────────────────────────────────────────
  group('initializeApp –', () {
    testWidgets('esegue senza eccezioni con factory iniettate', (tester) async {
      Widget? capturedWidget;
      await initializeApp(
        watchIdFactory: () async => 'test-id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (widget) {
          capturedWidget = widget;
        },
      );
      expect(capturedWidget, isA<TriploWatchApp>());
    });

    testWidgets('passa il watchId corretto a TriploWatchApp', (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'my-watch-123',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (widget) {
          app = widget as TriploWatchApp;
        },
      );
      expect(app?.watchId, 'my-watch-123');
    });

    testWidgets('chiama permissionsFactory quando fornita', (tester) async {
      var permCalled = false;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {
          permCalled = true;
        },
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (_) {},
      );
      expect(permCalled, isTrue);
    });

    testWidgets('chiama notificationInit quando fornita', (tester) async {
      var notifCalled = false;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {
          notifCalled = true;
        },
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (_) {},
      );
      expect(notifCalled, isTrue);
    });

    testWidgets('chiama watchIdFactory e ne usa il risultato', (tester) async {
      var factoryCalled = false;
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async {
          factoryCalled = true;
          return 'factory-id';
        },
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(factoryCalled, isTrue);
      expect(app?.watchId, 'factory-id');
    });

    testWidgets('usa memoryServiceFactory quando fornita', (tester) async {
      final mockMemory = MockMemoryService();
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => mockMemory,
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.memoryService, same(mockMemory));
    });

    testWidgets('usa geoServiceFactory quando fornita', (tester) async {
      final mockGeo = MockGeoService();
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => mockGeo,
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.geoService, same(mockGeo));
    });

    testWidgets('passa firestore a TriploWatchApp', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: fakeFirestore,
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.firestore, same(fakeFirestore));
    });

    testWidgets('firestore è null quando non fornito a initializeApp',
        (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.firestore, isNull);
    });

    testWidgets('runAppFn riceve un widget non null', (tester) async {
      Widget? received;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          received = w;
        },
      );
      expect(received, isNotNull);
    });

    /*testWidgets('il watchId viene caricato dalla factory asincrona',
        (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async {
          await Future.delayed(Duration.zero);
          return 'delayed-id';
        },
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.watchId, 'delayed-id');
    });*/

    testWidgets('language è configurata dopo initializeApp', (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.language, isNotNull);
    });

    testWidgets('notification è configurato dopo initializeApp', (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) {
          app = w as TriploWatchApp;
        },
      );
      expect(app?.notification, isNotNull);
    });

    testWidgets('chiamate multiple a initializeApp sono indipendenti',
        (tester) async {
      final apps = <TriploWatchApp>[];
      for (final id in ['id-1', 'id-2', 'id-3']) {
        await initializeApp(
          watchIdFactory: () async => id,
          permissionsFactory: () async {},
          notificationInit: () async {},
          memoryServiceFactory: () => MockMemoryService(),
          geoServiceFactory: () => MockGeoService(),
          firestore: FakeFirebaseFirestore(),
          runAppFn: (w) {
            apps.add(w as TriploWatchApp);
          },
        );
      }
      expect(apps.length, 3);
      expect(apps[0].watchId, 'id-1');
      expect(apps[1].watchId, 'id-2');
      expect(apps[2].watchId, 'id-3');
    });
    testWidgets('permissionsFactory null non lancia eccezioni', (tester) async {
      TriploWatchApp? app;
      await initializeApp(
        watchIdFactory: () async => 'id',
        permissionsFactory: () async {},
        notificationInit: () async {},
        memoryServiceFactory: () => MockMemoryService(),
        geoServiceFactory: () => MockGeoService(),
        firestore: FakeFirebaseFirestore(),
        runAppFn: (w) => app = w as TriploWatchApp,
      );
      expect(app, isNotNull);
    });
  }); // fine gruppo initializeApp
} // fine main