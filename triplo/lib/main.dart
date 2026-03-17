import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/pages/GeowatchPage/geowatch.dart';
import 'package:triplo/pages/LoginRegistrationPage/forgotten_password_page/forgotten_password_page.dart';
import 'package:triplo/pages/LoginRegistrationPage/login_page/LoginPage.dart';
import 'package:triplo/pages/LoginRegistrationPage/registration_page/registration_page.dart';
import 'package:triplo/pages/offline_page.dart';
import 'package:triplo/pages/UserProfilePage/user-page-public.dart';
import 'package:triplo/service/authservice.dart';
import 'package:triplo/service/geo.dart';
import 'package:triplo/service/internetservice.dart';
import 'package:triplo/service/memory.dart';
import 'package:triplo/service/permission.dart';
import 'controller/challenge.dart';
import 'firebase_options.dart';
import '../service/notification.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'package:triplo/pages/landing_page/landing_page.dart';


import 'package:triplo/update_points.dart';

import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/diary.dart';

import 'package:triplo/controller/API.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env file not found — continuing without it.");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final memoryService = MemoryService();
  final geoService= GeoService();
  final authService = AuthService();

  final language = Language();
  await language.loadSavedLocale();

  PermissionService.askPermissionsOnce();

  final notification = NotificationService();
  notification.setNavKey(navKey);
  await notification.init();

  runApp(
    MyApp(
      memoryService: memoryService,
      geoService: geoService,
      authService: authService,
      language: language,
      notification: notification,
    ),
  );
}

class MyApp extends StatelessWidget {
  final MemoryService memoryService;
  final GeoService geoService;
  final AuthService authService;
  final Language language;
  final NotificationService notification;

  const MyApp({
    super.key,
    required this.memoryService,
    required this.geoService,
    required this.authService,
    required this.language,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider.value(value: language),
        Provider<MemoryService>.value(value: memoryService),
        Provider<GeoService>.value(value: geoService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
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
        ProxyProvider2<GeoService, MemoryService, API>(
          update: (context, geo, memory, previous) => 
              API(geo: geo, memory: memory),
        ),
        ChangeNotifierProxyProvider<API, InternetService>(
          create: (context) =>
              InternetService(api: context.read<API>())..start(),
          update: (context, api, old) =>
              old ?? InternetService(api: api)..start(),
        ),
        ChangeNotifierProxyProvider<AuthService, UserController>(
          create: (context) {
            final controller = UserController(context.read<AuthService>());
            controller.tryAutoLogin();
            return controller;
          },
          update: (context, authService, previous) =>
              previous ?? UserController(authService),
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
        ),
      ],

      // ---- FIX: Consumer<InternetService> separato da Consumer<Language> ----
      // Consumer<InternetService> gestisce la navigazione offline/online
      // Consumer<Language> aggiorna solo il locale di MaterialApp
      // In questo modo il cambio lingua NON resetta più lo stack di navigazione
      child: Consumer<InternetService>(
        builder: (context, internet, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = navKey.currentState;
            if (nav == null) return;

            // Naviga a /offline solo se perde la connessione
            if (!internet.isOnline) {
              nav.pushNamedAndRemoveUntil('/offline', (r) => false);
            }
          });

          return Consumer<Language>(
            builder: (context, lang, child) {
              return MaterialApp(
                title: 'Triplo',
                debugShowCheckedModeBanner: false,
                navigatorKey: navKey,

                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.lightBlueAccent,
                  ),
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

                initialRoute: '/landing_page',

                routes: {
                  '/landing_page': (context) => Landing_Page(),
                  '/login': (context) => LoginPage(),
                  '/registration': (context) => RegistrationPage(),
                  '/forgotten_password': (context) => ForgottenPasswordPage(),
                  '/geowatch': (context) => const GeoWatchPage(),
                  '/admin_upload': (context) => const AdminUploadPage(),
                  "/userProfileRemote": (context) => UserPagePublic(
                        userId: ModalRoute.of(context)!.settings.arguments
                            as String,
                      ),
                  '/offline': (context) => const OfflinePage(),
                  '/navigation': (context) => CompassAltitudePage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}

