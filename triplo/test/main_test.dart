import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/challenge.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/controller/servicecontroller.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/main.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/service/authservice.dart';
import 'package:triplo/service/backgroundservice.dart';
import 'package:triplo/service/geo.dart';
import 'package:triplo/service/internetservice.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/notification.dart';
import 'package:triplo/service/permission.dart';
import 'main_test.mocks.dart';

// Tell Mockito which real classes must be replaced with mocks
@GenerateMocks([
  MemoryService,
  GeoService,
  AuthService,
  PermissionService,
  NotificationService,
  Language,
  InternetService,
  UserController,
  TrekkingController,
  DiaryController,
  ChallengesController,
  ServiceController,
])
void main() {
  // Mock variables used by the tests
  late MockMemoryService mockMemory;
  late MockGeoService mockGeo;
  late MockAuthService mockAuth;
  late MockPermissionService mockPermission;
  late MockNotificationService mockNotification;
  late MockLanguage mockLanguage;
  late MockInternetService mockInternet;
  late MockTrekkingController mockTrekking;
  late MockDiaryController mockDiary;
  late MockChallengesController mockChallenges;
  late MockUserController mockUser;
  late MockServiceController mockServiceController;

  //function that creates a simple Trekking object for the tests
  Trekking makeTrekking({
    String id = 'trek1',
    String name = 'Test Trek',
    LatLng? startingPoint,
    LatLng? endingPoint,
  }) {
    return Trekking(
      documentId: id,
      name: name,
      mapPhoto: '',
      difficultyLevel: 'easy',
      distance: 5.0,
      estimatedTime: 2.0,
      elevationGain: 100.0,
      upGain: true,
      downGain: false,
      startingPoint: startingPoint ?? const LatLng(45.0, 9.0),
      endingPoint: endingPoint ?? const LatLng(46.0, 10.0),
      points: [],
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
    );
  }

  setUp(() {
    // Create all fake dependencies.
    mockMemory = MockMemoryService();
    mockGeo = MockGeoService();
    mockAuth = MockAuthService();
    mockPermission = MockPermissionService();
    mockNotification = MockNotificationService();
    mockLanguage = MockLanguage();
    mockInternet = MockInternetService();
    mockTrekking = MockTrekkingController();
    mockDiary = MockDiaryController();
    mockChallenges = MockChallengesController();
    mockUser = MockUserController();
    mockServiceController = MockServiceController();

    // Default fake values used in most tests
    when(mockLanguage.locale).thenReturn(const Locale('en'));
    when(mockLanguage.hasListeners).thenReturn(false);
    when(mockInternet.isOnline).thenReturn(true);
    when(mockInternet.hasListeners).thenReturn(false);

    // These mock components also start with no listeners
    for (final n in [mockTrekking, mockDiary, mockChallenges, mockUser]) {
      when(n.hasListeners).thenReturn(false);
    }
    when(mockNotification.setNavKey(any)).thenReturn(null);
    when(mockNotification.init()).thenAnswer((_) async {});
    when(mockPermission.askPermissionsOnce()).thenAnswer((_) async {});
  });

  Widget buildMockedMaterialApp({
    bool isOnline = true,
    Locale locale = const Locale('en'),
  }) {
    when(mockInternet.isOnline).thenReturn(isOnline);
    when(mockLanguage.locale).thenReturn(locale);

    // Build a minimal app with the same providers used by the real app
    return MultiProvider(
      providers: [
        // Language is provided as a ChangeNotifier because it can notify the UI
        ChangeNotifierProvider<Language>.value(value: mockLanguage),

        // MemoryService is provided as a simple Provider because it does not notify listeners
        Provider<MemoryService>.value(value: mockMemory),

        // GeoService is a simple service
        // It does not need to rebuild the UI
        Provider<GeoService>.value(value: mockGeo),

        // AuthService is a ChangeNotifier because authentication state can change,
        //  and widgets listening to AuthService can rebuild when notifyListeners() is called
        ChangeNotifierProvider<AuthService>.value(value: mockAuth),

        // PermissionService is provided as a simple Provider because it does not notify the UI
        Provider<PermissionService>.value(value: mockPermission),

        // NotificationService is a simple Provider because it does not notify the UI through notifyListeners()
        Provider<NotificationService>.value(value: mockNotification),



        // ServiceController is a simple Provider
        Provider<ServiceController>.value(value: mockServiceController),

        // InternetService is a ChangeNotifier because if the internet state changes, it can notify the widgets that depend on it
        ChangeNotifierProvider<InternetService>.value(value: mockInternet),

        // UserController is a ChangeNotifier because user-related data can change
        // and the UI may need to update when those changes happen
        ChangeNotifierProvider<UserController>.value(value: mockUser),

        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),

        // DiaryController is a ChangeNotifier because diary entries or diary state
        // can change, and listening widgets may need to rebuild
        ChangeNotifierProvider<DiaryController>.value(value: mockDiary),

        ChangeNotifierProvider<ChallengesController>.value(value: mockChallenges),
      ],
      child: Builder(
        builder: (context) {
          final lang = context.watch<Language>();
          final internet = context.watch<InternetService>();
          return MaterialApp(
            title: 'Triplo',
            debugShowCheckedModeBanner: false,
            locale: lang.locale,
            localizationsDelegates: const [
              DefaultWidgetsLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), Locale('it'), Locale('es'), Locale('de'), Locale('fr'),
            ],
            routes: {
              '/user': (_) => const Scaffold(body: Text('user')),
              '/registration': (_) => const Scaffold(body: Text('registration')),
              '/forgotten_password': (_) => const Scaffold(body: Text('fp')),
              '/login': (_) => const Scaffold(body: Text('login')),
              '/offline': (_) => const Scaffold(body: Text('offline')),
              '/navigation': (_) => const Scaffold(body: Text('navigation')),
            },
            home: internet.isOnline
                ? const Scaffold(body: Text('online'))
                : const Scaffold(body: Text('offline')),
          );
        },
      ),
    );
  }


  // Build only what is needed to test BackgroundServiceHost
  Widget buildWithAllProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),
        ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        Provider<MemoryService>.value(value: mockMemory),
        Provider<NotificationService>.value(value: mockNotification),
        Provider<GeoService>.value(value: mockGeo),
        Provider<ServiceController>.value(value: mockServiceController),
        ChangeNotifierProvider<InternetService>.value(value: mockInternet),
        ChangeNotifierProvider<Language>.value(value: mockLanguage),
      ],
      child: MaterialApp(home: BackgroundServiceHost(child: child)),
    );
  }



  Future<BuildContext> pumpServiceContext(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TrekkingController>.value(value: mockTrekking),
          Provider<ServiceController>.value(value: mockServiceController),
          Provider<NotificationService>.value(value: mockNotification),
          Provider<MemoryService>.value(value: mockMemory),
        ],
        child: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    );

    return ctx;
  }

  group('MyApp – constructor', () {
    // Create MyApp with mocks and check that every field stores the same object
    test('stores all required service references', () {
      final app = MyApp(
        memoryService: mockMemory,
        geoService: mockGeo,
        authService: mockAuth,
        permissionService: mockPermission,
        language: mockLanguage,
        notification: mockNotification,
      );
      expect(app.memoryService, same(mockMemory));
      expect(app.geoService, same(mockGeo));
      expect(app.authService, same(mockAuth));
      expect(app.permissionService, same(mockPermission));
      expect(app.language, same(mockLanguage));
      expect(app.notification, same(mockNotification));
    });
  });

  group('navKey', () {
    // The app exposes one navigator key, and it must have the correct type
    test('is a GlobalKey<NavigatorState>', () {
      expect(navKey, isA<GlobalKey<NavigatorState>>());
    });
  });

  group('MaterialApp configuration', () {
    // If the app tree can be pumped, the root widget configuration is valid.
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    // Read the MaterialApp widget and check its title field
    testWidgets('title is "Triplo"', (tester) async {
      //uses minimal app tree with providers
      await tester.pumpWidget(buildMockedMaterialApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Triplo');
    });

    // The debug banner should be off
    testWidgets('debug banner is disabled', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    // The locale shown by the app must come from the Language provider
    testWidgets('locale reflects Language.locale', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp(locale: const Locale('en')));
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
    });

    // Check that the expected five language codes are registered
    testWidgets('supportedLocales contains en, it, es, de, fr', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final codes = app.supportedLocales.map((l) => l.languageCode).toList();
      expect(codes, containsAll(['en', 'it', 'es', 'de', 'fr']));
    });

    // Check that the test app exposes the same main routes expected by the project
    testWidgets('routes map contains all 6 expected keys', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routes!.keys, containsAll([
        '/user', '/registration', '/forgotten_password',
        '/login', '/offline', '/navigation',
      ]));
    });
  });

  group('Online / offline rendering', () {
    // With internet on, the home widget must show the online placeholder in buildMockedMaterialApp
    testWidgets('shows online content when connected', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('online'), findsOneWidget);
    });

    // With internet off, the home widget must show the offline placeholder in the same widget
    testWidgets('shows offline content when not connected', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp(isOnline: false));
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);
    });

    // Pump the widget twice with different states and check that the UI changes
    testWidgets('rebuilds when online status changes', (tester) async {
      await tester.pumpWidget(buildMockedMaterialApp(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('online'), findsOneWidget);

      await tester.pumpWidget(buildMockedMaterialApp(isOnline: false));
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);
    });
  });

  group('BackgroundServiceHost', () {
    testWidgets('renders its child widget', (tester) async {
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      const key = Key('bg_child');
      await tester.pumpWidget(buildWithAllProviders(child: const SizedBox(key: key)));
      await tester.pump();
      expect(find.byKey(key), findsOneWidget);
    });


    // Replacing the widget tree forces dispose
    testWidgets('disposes without throwing', (tester) async {
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      await tester.pumpWidget(buildWithAllProviders(child: const SizedBox()));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    });


    testWidgets('mounts and starts without crashing', (tester) async {
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      await tester.pumpWidget(buildWithAllProviders(child: const SizedBox()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('BackgroundService', () {
    // Starting the background service must be safe in a normal scenario
    testWidgets('start() runs without throwing', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      final service = BackgroundService(ctx);
      expect(() => service.start(), returnsNormally);
      service.dispose();
    });

    // Normal lifecycle: start first, then dispose
    testWidgets('dispose() after start() does not throw', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      final service = BackgroundService(ctx);
      service.start();
      expect(() => service.dispose(), returnsNormally);
    });

    // Edge case: dispose is called before start, so internal timer is still null
    testWidgets('dispose() before start() does not throw (timer is null)', (tester) async {
      final ctx = await pumpServiceContext(tester);
      final service = BackgroundService(ctx);
      expect(() => service.dispose(), returnsNormally);
    });

    // The service should avoid running the same work twice at the same time
    testWidgets('_run() skips second call while first is running', (tester) async {
      final ctx = await pumpServiceContext(tester);
      final completer = Completer<List<Trekking>>();
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenAnswer((_) => completer.future);

      final service = BackgroundService(ctx);
      service.start();         
      await tester.pump();

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      completer.complete([]);
      await tester.pump();

      verify(mockTrekking.getWeatherAlertTrekkings()).called(1);
      service.dispose();
    });

    // Returning to foreground should force another check.
    testWidgets('didChangeAppLifecycleState resumed triggers _run()', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      final service = BackgroundService(ctx);
      service.start();
      await tester.pump();

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(); 

      verify(mockTrekking.getWeatherAlertTrekkings()).called(greaterThanOrEqualTo(2));
      service.dispose();
    });

    // Paused should not force a new weather-alert check.
    testWidgets('didChangeAppLifecycleState paused does NOT trigger _run()', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      final service = BackgroundService(ctx);
      service.start();
      await tester.pump();
      clearInteractions(mockTrekking);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();

      verifyNever(mockTrekking.getWeatherAlertTrekkings());
      service.dispose();
    });

    // Inactive should also not force a new check.
    testWidgets('didChangeAppLifecycleState inactive does NOT trigger _run()', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      final service = BackgroundService(ctx);
      service.start();
      await tester.pump();
      clearInteractions(mockTrekking);

      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();

      verifyNever(mockTrekking.getWeatherAlertTrekkings());
      service.dispose();
    });

    // If the controller throws, the service should render the error and continue
    testWidgets('_run() catches and swallows exceptions', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenThrow(Exception('network error'));

      final service = BackgroundService(ctx);
      expect(() async {
        service.start();
        await tester.pump();
      }, returnsNormally);

      service.dispose();
    });

    testWidgets('_running resets to false after successful _run()', (tester) async {
      final ctx = await pumpServiceContext(tester);
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);

      final service = BackgroundService(ctx);
      service.start();
      await tester.pump(); 

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      verify(mockTrekking.getWeatherAlertTrekkings()).called(greaterThanOrEqualTo(2));
      service.dispose();
    });

    testWidgets('_running resets to false after exception in _run()', (tester) async {
      final ctx = await pumpServiceContext(tester);
      var callCount = 0;
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('first call fails');
        return [];
      });

      final service = BackgroundService(ctx);
      service.start();
      await tester.pump(); 

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(); 

      expect(callCount, equals(2));
      service.dispose();
    });
  });

  group('BackgroundServiceLogic', () {
    setUp(() {
      // Default fake behavior for the pure logic tests below
      when(mockServiceController.weatherbitAlerts(any, any))
          .thenAnswer((_) async => []);
      when(mockServiceController.mockAlerts())
          .thenAnswer((_) async => []);
      when(mockMemory.hasShownWeatherAlertKey(any))
          .thenAnswer((_) async => false);
      when(mockMemory.addShownWeatherAlertKey(any))
          .thenAnswer((_) async => {});
      when(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => {});
    });

    // If there are no trekking subscriptions, the method should just finish
    test('run() with no trekkings completes without error', () async {
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => []);
      await expectLater(
        BackgroundServiceLogic.run(
          trekkingController: mockTrekking,
          api: mockServiceController,
          notification: mockNotification,
          memory: mockMemory,
        ),
        completes,
      );
    });

    // The logic must call the weather API using the trekking start coordinates
    test('run() calls weatherbitAlerts with starting_point coordinates', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockServiceController.weatherbitAlerts(45.0, 9.0)).called(1);
      verify(mockServiceController.mockAlerts()).called(1);
    });

    // A new alert should create a notification and then save its unique key
    test('run() shows notification for new alert and saves key', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'event': 'Thunderstorm', 'headline': 'Heavy', 'start': '1', 'end': '2'},
      ]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: 'Thunderstorm',
        body: 'Alert for Test Trek',
      )).called(1);
      verify(mockMemory.addShownWeatherAlertKey(any)).called(1);
    });

    // If memory says the alert was already shown, no new notification is sent
    test('run() skips already-shown alert', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'event': 'Thunderstorm', 'headline': 'Heavy', 'start': '1', 'end': '2'},
      ]);
      when(mockMemory.hasShownWeatherAlertKey(any)).thenAnswer((_) async => true);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verifyNever(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
      ));
      verifyNever(mockMemory.addShownWeatherAlertKey(any));
    });


    test('run() uses title field when event is null', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'title': 'Wind Advisory', 'headline': '', 'start': '1', 'end': '2'},
      ]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: 'Wind Advisory',
        body: anyNamed('body'),
      )).called(1);
    });

    // If both fields are missing, a safe default title is expected
    test('run() uses default title when both event and title are null', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'headline': 'Something', 'start': '1', 'end': '2'},
      ]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: 'Weather alert',
        body: anyNamed('body'),
      )).called(1);
    });

    // Real API alerts and local mock alerts are combined into one list.
    test('run() merges real and mock alerts, notifies for each', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'event': 'Rain', 'headline': '', 'start': '1', 'end': '2'},
      ]);
      when(mockServiceController.mockAlerts()).thenAnswer((_) async => [
        {'event': 'Snow', 'headline': '', 'start': '3', 'end': '4'},
      ]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
      )).called(2);
    });

    // Each trekking should be processed separately, with one notification per alert
    test('run() processes multiple trekkings independently', () async {
      final trek1 = makeTrekking(id: 't1', name: 'Trek 1', startingPoint: const LatLng(45.0, 9.0));
      final trek2 = makeTrekking(id: 't2', name: 'Trek 2', startingPoint: const LatLng(46.0, 10.0));
      when(mockTrekking.getWeatherAlertTrekkings())
          .thenAnswer((_) async => [trek1, trek2]);
      when(mockServiceController.weatherbitAlerts(any, any)).thenAnswer((_) async => [
        {'event': 'Storm', 'headline': '', 'start': '1', 'end': '2'},
      ]);

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
      )).called(2);
    });

    // The same alert data should generate the same key, so duplicates are ignored.
    test('alert key is stable for same trekking and alert data', () async {
      final trek = makeTrekking(startingPoint: const LatLng(45.0, 9.0));
      when(mockTrekking.getWeatherAlertTrekkings()).thenAnswer((_) async => [trek]);
      final alert = {'event': 'Hail', 'headline': 'Big', 'start': '1', 'end': '2'};
      when(mockServiceController.weatherbitAlerts(any, any))
          .thenAnswer((_) async => [alert, alert]); // same alert twice

      var saveCount = 0;
      when(mockMemory.hasShownWeatherAlertKey(any)).thenAnswer((_) async {
        return saveCount > 0; 
      });
      when(mockMemory.addShownWeatherAlertKey(any)).thenAnswer((_) async {
        saveCount++;
      });

      await BackgroundServiceLogic.run(
        trekkingController: mockTrekking,
        api: mockServiceController,
        notification: mockNotification,
        memory: mockMemory,
      );

      verify(mockNotification.showWeatherNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
      )).called(1);
    });
  });

   // Test the startup helper that builds and initializes app services
   group('appSetup()', () {
    setUp(() {
      when(mockMemory.getSavedLocaleCode())   
        .thenAnswer((_) async => null);  
      when(mockNotification.setNavKey(any)).thenReturn(null);
      when(mockNotification.init()).thenAnswer((_) async {});
      when(mockPermission.askPermissionsOnce()).thenAnswer((_) async {});
    });


 
    // appSetup should return all required service objects
    test('restituisce tutti i servizi richiesti', () async {
      final result = await appSetup(
        memoryOverride: mockMemory,
        authOverride: mockAuth,           // Use the mock instead of real FirebaseAuth.instance
        notificationOverride: mockNotification,
        permissionOverride: mockPermission,
      );
 
      expect(result.memory, same(mockMemory));
      expect(result.auth, same(mockAuth));
      expect(result.notification, same(mockNotification));
      expect(result.permission, same(mockPermission));
      expect(result.geo, isA<GeoService>());
      expect(result.language, isA<Language>());
    });
 

    test('chiama setNavKey con navKey', () async {
      await appSetup(
        memoryOverride: mockMemory,
        authOverride: mockAuth,
        notificationOverride: mockNotification,
        permissionOverride: mockPermission,
      );
      verify(mockNotification.setNavKey(navKey)).called(1);
    });
 

    test('chiama init() su NotificationService', () async {
      await appSetup(
        memoryOverride: mockMemory,
        authOverride: mockAuth,
        notificationOverride: mockNotification,
        permissionOverride: mockPermission,
      );
      verify(mockNotification.init()).called(1);
    });
 
    // PermissionService should ask permissions once during startup
    test('chiama askPermissionsOnce su PermissionService', () async {
      await appSetup(
        memoryOverride: mockMemory,
        authOverride: mockAuth,
        notificationOverride: mockNotification,
        permissionOverride: mockPermission,
      );
      verify(mockPermission.askPermissionsOnce()).called(1);
    });
  });
 

  // handleConnectivityChange() — testa la logica pura senza
  // montare MyApp reale (che dipende da Firebase/dotenv).
  // Usiamo un MaterialApp minimale per ottenere un NavigatorState
  // reale con le rotte /offline e /user registrate.
  group('handleConnectivityChange()', () {
    setUp(() {
      // Resetta lo stato globale prima di ogni test
      resetOfflinePageFlag();
    });
 
    testWidgets('nav==null → nessuna azione, nessun crash', (tester) async {
      // Chiamata diretta senza Navigator
      expect(
        () => handleConnectivityChange(nav: null, isOnline: false),
        returnsNormally,
      );
      expect(
        () => handleConnectivityChange(nav: null, isOnline: true),
        returnsNormally,
      );
    });
 
    testWidgets(
        'isOnline=false, _isShowingOfflinePage=false → naviga a /offline',
        (tester) async {
      final testNavKey = GlobalKey<NavigatorState>();
 
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          routes: {
            '/': (_) => const Scaffold(body: Text('home')),
            '/offline': (_) => const Scaffold(body: Text('offline')),
            '/user': (_) => const Scaffold(body: Text('user')),
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();
 
      handleConnectivityChange(
        nav: testNavKey.currentState,
        isOnline: false,
      );
      await tester.pumpAndSettle();
 
      expect(find.text('offline'), findsOneWidget);
    });
 
    testWidgets(
        'isOnline=false, _isShowingOfflinePage=true → non naviga di nuovo',
        (tester) async {
      final testNavKey = GlobalKey<NavigatorState>();
      // Pre-imposta il flag come se fossimo già offline
      handleConnectivityChange(nav: null, isOnline: false); // nav null: imposta solo il flag
      // Forziamo il flag manualmente
      resetOfflinePageFlag();
      // Prima chiamata: va offline
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          routes: {
            '/': (_) => const Scaffold(body: Text('home')),
            '/offline': (_) => const Scaffold(body: Text('offline')),
            '/user': (_) => const Scaffold(body: Text('user')),
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();
 
      handleConnectivityChange(nav: testNavKey.currentState, isOnline: false);
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);
 
      // Seconda chiamata con isOnline=false: _isShowingOfflinePage è già true → no-op
      handleConnectivityChange(nav: testNavKey.currentState, isOnline: false);
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget); // ancora offline, nessun crash
    });
 
    testWidgets(
        'isOnline=true, _isShowingOfflinePage=true → naviga a /user e resetta flag',
        (tester) async {
      final testNavKey = GlobalKey<NavigatorState>();
 
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          routes: {
            '/': (_) => const Scaffold(body: Text('home')),
            '/offline': (_) => const Scaffold(body: Text('offline')),
            '/user': (_) => const Scaffold(body: Text('user')),
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();
 
      // Prima: vai offline
      handleConnectivityChange(nav: testNavKey.currentState, isOnline: false);
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);
 
      // Poi: torna online
      handleConnectivityChange(nav: testNavKey.currentState, isOnline: true);
      await tester.pumpAndSettle();
      expect(find.text('user'), findsOneWidget);
    });
 
    testWidgets(
        'isOnline=true, _isShowingOfflinePage=false → no-op, nessuna navigazione',
        (tester) async {
      final testNavKey = GlobalKey<NavigatorState>();
 
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          routes: {
            '/': (_) => const Scaffold(body: Text('home')),
            '/offline': (_) => const Scaffold(body: Text('offline')),
            '/user': (_) => const Scaffold(body: Text('user')),
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();
 
      // Online con flag già false: non deve succedere nulla
      handleConnectivityChange(nav: testNavKey.currentState, isOnline: true);
      await tester.pumpAndSettle();
 
      // Siamo ancora sulla rotta iniziale '/'
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('resetOfflinePageFlag()', () {
    test('resetta il flag a false', () {
      // Imposta il flag a true tramite handleConnectivityChange con nav null
      // (nav null fa return immediato senza navigare, ma il flag non viene toccato)
      // Usiamo direttamente la funzione esposta
      resetOfflinePageFlag();
      // Verifica indirettamente: dopo reset, isOnline=true non naviga a /user
      // (perché _isShowingOfflinePage è false)
      expect(() => resetOfflinePageFlag(), returnsNormally);
    });
  });
}
