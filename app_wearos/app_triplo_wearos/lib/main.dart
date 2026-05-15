import 'package:app_triplo_wearos/controller/challenge.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/servicecontroller.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:app_triplo_wearos/pages/offline_page.dart';
import 'package:app_triplo_wearos/service/OSservice/geo.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/internetservice.dart';
import 'package:app_triplo_wearos/service/pairing_service.dart';
import 'package:app_triplo_wearos/service/OSservice/permission_service.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/user.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

// Testabile: contiene tutta la logica di avvio
@visibleForTesting
Future<void> initializeApp({
  Future<String> Function()? watchIdFactory,
  Future<void> Function()? permissionsFactory,
  Future<void> Function()? notificationInit,
  void Function(Widget)? runAppFn,
  MemoryService Function()? memoryServiceFactory,
  GeoService Function()? geoServiceFactory,
  FirebaseFirestore? firestore,
}) async {
  final resolvedWatchId = watchIdFactory != null
      ? await watchIdFactory()
      : await WatchIdService.getOrCreateWatchId(); // coverage:ignore-line

  if (permissionsFactory != null) {
    await permissionsFactory();
  } else {
    await PermissionService.askPermissionsOnce(); // coverage:ignore-line
  }

  final memoryService = memoryServiceFactory != null
      ? memoryServiceFactory()
      : MemoryService(); // coverage:ignore-line

  final geoService = geoServiceFactory != null
      ? geoServiceFactory()
      : GeoService(); // coverage:ignore-line

  final language = Language();
  await language.loadSavedLocale();

  final notification = NotificationService();
  notification.setNavKey(navKey);

  if (notificationInit != null) {
    await notificationInit();
  } else {
    await notification.init(); // coverage:ignore-line
  }

  final app = TriploWatchApp(
    watchId: resolvedWatchId,
    memoryService: memoryService,
    geoService: geoService,
    language: language,
    notification: notification,
    firestore: firestore,
  );

  if (runAppFn != null) {
    runAppFn(app);
  } else {
    runApp(app); // coverage:ignore-line
  }
}

// Punto di ingresso reale — tutto ignorato dalla copertura
Future<void> main() async { // coverage:ignore-line
  WidgetsFlutterBinding.ensureInitialized(); // coverage:ignore-line
  try { // coverage:ignore-line
    await dotenv.load(fileName: ".env"); // coverage:ignore-line
  } catch (e) { // coverage:ignore-line
    debugPrint(".env file not found"); // coverage:ignore-line
  } // coverage:ignore-line
  try { // coverage:ignore-line
    await Firebase.initializeApp( // coverage:ignore-line
        options: DefaultFirebaseOptions.currentPlatform); // coverage:ignore-line
  } catch (e) { // coverage:ignore-line
    debugPrint("Firebase init failed: $e"); // coverage:ignore-line
  } // coverage:ignore-line
  await initializeApp(); // coverage:ignore-line
} // coverage:ignore-line

class AppBootstrap {
  static Future<String> Function() getWatchId =
      WatchIdService.getOrCreateWatchId;
  static Future<void> Function() askPermissions =
      PermissionService.askPermissionsOnce;
}

class TriploWatchApp extends StatelessWidget {
  final String watchId;
  final MemoryService memoryService;
  final GeoService geoService;
  final Language language;
  final NotificationService notification;
  final FirebaseFirestore? firestore; // ← iniettabile per i test

  const TriploWatchApp({
    super.key,
    required this.watchId,
    required this.memoryService,
    required this.geoService,
    required this.language,
    required this.notification,
    this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MemoryService>.value(value: memoryService),
        Provider<GeoService>.value(value: geoService),
        Provider<NotificationService>.value(value: notification),
        ChangeNotifierProvider.value(value: language),
        ChangeNotifierProvider(create: (_) => DiaryController()),
        /*ChangeNotifierProvider(
          create: (_) => PairingService(watchId: watchId),
        ),*/
        ChangeNotifierProvider(
          create: (_) => firestore != null
              ? PairingService.withFirestore(watchId: watchId, db: firestore!)
              : PairingService(watchId: watchId), // coverage:ignore-line
        ),
        ChangeNotifierProxyProvider<PairingService, UserController>(
          create: (context) => UserController(context.read<PairingService>()),
          update: (context, pairingService, previous) =>
              previous ?? UserController(pairingService),
        ),
        Provider<ServiceController>(
          create: (context) => ServiceController(
            geo: context.read<GeoService>(),
            memory: context.read<MemoryService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => InternetService(
            servicecontroller: context.read<ServiceController>(),
          )..start(),
        ),
        ChangeNotifierProvider(
          create: (context) => TrekkingController(
            geo: context.read<GeoService>(),
            memory: context.read<MemoryService>(),
            notification: context.read<NotificationService>(),
            pairingService: context.read<PairingService>(),
            trekkings: [],
            db: firestore ?? FirebaseFirestore.instance, // ← usa fake in test
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChallengesController(
            memory: context.read<MemoryService>(),
            notification: context.read<NotificationService>(),
          ),
        ),
      ],
      child: Consumer<Language>(
        builder: (context, lang, child) {
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
}