
import 'package:app_triplo_wearos/controller/challenge.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/service/OSservice/permission_service.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/user.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env file not found — continuing without it.");
  }

  try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint("Firebase init failed (GMS non disponibile su emulatore x86): $e");
}

  final watchId = await WatchIdService.getOrCreateWatchId();

  /*Init NotificationService centralizzato
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.setNavKey(navKey); // <- passa il navKey

  // Crea i canali Android
  final androidPlugin = notificationService
      // ignore: invalid_use_of_visible_for_testing_member
      .plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'notifications_channel',
      'Notifications',
      importance: Importance.high,
    ),
  );

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'arrival_channel',
      'Arrivo Trekking',
      importance: Importance.high,
    ),
  );*/
  
  final memoryService = MemoryService();
  final geoService= GeoService();

  final language = Language();
  await language.loadSavedLocale();

  await PermissionService.askPermissionsOnce();

  final notification = NotificationService();
  notification.setNavKey(navKey);
  await notification.init();

  runApp(
    TriploWatchApp(
      watchId: watchId,
      memoryService: memoryService,
      geoService: geoService,
      language: language,
      notification: notification,
    )
  );
}

class TriploWatchApp extends StatelessWidget {
  final String watchId;
  final MemoryService memoryService;
  final GeoService geoService;
  final Language language;
  final NotificationService notification;
  const TriploWatchApp({
    super.key, 
    required this.watchId, 
    required this.memoryService,
    required this.geoService,
    required this.language,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Inietta prima i servizi base (Provider semplici)
        Provider<MemoryService>.value(value: memoryService),
        Provider<GeoService>.value(value: geoService),
        Provider<NotificationService>.value(value: notification),
        ChangeNotifierProvider.value(value: language),

        // 2. Inietta i controller che dipendono dai servizi
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider(
          create: (_) => PairingService(watchId: watchId),
        ),


        ChangeNotifierProxyProvider<PairingService, UserController>(
          create: (context) => UserController(context.read<PairingService>()),
          update: (context, pairingService, previous) =>
          previous ?? UserController(pairingService),
        ),

        // API (Provider semplice perché non è un ChangeNotifier)
        Provider<ServiceController>(create: (context) => ServiceController(
          geo: context.read<GeoService>(), 
          memory: context.read<MemoryService>(),
          //notification: context.read<NotificationService>(),
        )),

        // TrekkingController con le dipendenze passate correttamente
        ChangeNotifierProvider(create: (context) => TrekkingController(
          geo: context.read<GeoService>(),
          memory: context.read<MemoryService>(),
          notification: context.read<NotificationService>(),
          trekkings: [],
        )),

        // ChallengesController con le dipendenze passate correttamente
        ChangeNotifierProvider(create: (context) => ChallengesController(
          memory: context.read<MemoryService>(),
          notification: context.read<NotificationService>(),
        )),
        
        /*ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider.value(value: language),
        Provider<MemoryService>.value(value: memoryService),
        Provider<GeoService>.value(value: geoService),
        Provider<NotificationService>.value(value: notification),
        ChangeNotifierProxyProvider3<GeoService, MemoryService, NotificationService, TrekkingController>(
          create: (context) => TrekkingController(
            geo: context.read<GeoService>(),
            memory: context.read<MemoryService>(),
            notification: context.read<NotificationService>(),
            trekkings: [],
          ),
          update: (context, geo, memory, notification, previous) {
            if (previous != null) {
              previous.geo = geo;
              previous.memory = memory;
              previous.notification = notification;
              return previous;
            }
            return TrekkingController(
              geo: geo,
              memory: memory,
              notification: notification,
              trekkings: [],
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => UserController(watchId: widget.watchId)),
        ProxyProvider2<GeoService, MemoryService, API>(
          update: (context, geo, memory, previous) => 
              API(geo: geo, memory: memory),
        ),
        ChangeNotifierProxyProvider<API>(
          create: (context) =>
              InternetService(api: context.read<API>())..start(),
          update: (context, api, old) =>
              old ?? InternetService(api: api)..start(),
        ),
        ChangeNotifierProxyProvider<MemoryService, ChallengesController>(
          create: (context) => ChallengesController(
            memory: context.read<MemoryService>(),
            notification: context.read<NotificationService>(),
          ),
          update: (context, memory, previous) {
            if (previous != null) {
              previous.memory = memory;
              previous.notification = context.read<NotificationService>();
              return previous;
            }
            return ChallengesController(
              memory: memory, 
              notification: context.read<NotificationService>(),
            );
          },
        ),*/
      ],
      child: Consumer<Language>(
        builder: (context, lang, child) {
          return MaterialApp(
            title: 'Triplo',
            debugShowCheckedModeBanner: false,
            navigatorKey: navKey,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
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
            home: NavigationPage()

          );
        },
      ),
    );
  }
}