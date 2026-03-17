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
import 'package:triplo/service/OSservice.dart';
import 'package:triplo/service/authservice.dart';
import 'package:triplo/service/internetservice.dart';
import 'controller/challenge.dart';
import 'firebase_options.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'package:triplo/pages/landing_page/landing_page.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:triplo/update_points.dart';

import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/diary.dart';

import 'package:triplo/controller/API.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

  final os = OSService();
  final authService = AuthService();

  final language = Language(os: os);
  await language.loadSavedLocale();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final context = navKey.currentContext;
      if (context == null) return;

      final local = AppLocalizations.of(context);
      if (local == null) return;

      final String payload = response.payload ?? "";
      
      // Recuperiamo i testi tradotti usando la tua funzione
      final challengeContent = _getChallengeContent(payload, local);
      final String title = challengeContent['title'] ?? "";
      final String body = challengeContent['body'] ?? "";

      if (payload == 'end_trekking_arrival') {
        // Tuo alert originale per l'arrivo
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("📍 $title"), // Usa il titolo tradotto dell'arrivo
            content: Text(body),       // Usa il corpo tradotto dell'arrivo
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        // Tuo alert originale per le sfide
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("🥾 $title"), // Usa il titolo specifico della sfida
            content: Text(body),       // Usa il corpo specifico della sfida
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    },
  );

  runApp(
    MyApp(
      os: os,
      authService: authService,
      language: language,
    ),
  );
}

class MyApp extends StatelessWidget {
  final OSService os;
  final AuthService authService;
  final Language language;

  const MyApp({
    super.key,
    required this.os,
    required this.authService,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider.value(value: language),
        Provider<OSService>.value(value: os),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProxyProvider<OSService, TrekkingController>(
          create: (context) => TrekkingController(
            os: context.read<OSService>(),
            trekkings: [],
          ),
          update: (context, os, previous) =>
              previous ?? TrekkingController(os: os, trekkings: []),
        ),
        ProxyProvider<OSService, API>(
          update: (_, os, __) => API(os: os),
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

        ChangeNotifierProxyProvider<OSService, ChallengesController>(
          create: (context) => ChallengesController(
            os: context.read<OSService>(),
          ),
          update: (context, os, previous) =>
          previous ?? ChallengesController(os: os),
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

Map<String, String> _getChallengeContent(String payload, AppLocalizations local) {
  switch (payload) {
    case "balance":
      return {
        'title': local.title_challenge_balance,
        'body': local.body_challenge_balance,
      };
    case "hi":
      return {
        'title': local.title_challenge_hi,
        'body': local.body_challenge_hi,
      };
    case "mini_orientiring":
      return {
        'title': local.title_challenge_mini_orientiring,
        'body': local.body_challenge_mini_orientiring,
      };
    case "photo":
      return {
        'title': local.title_challenge_photo,
        'body': local.body_challenge_photo,
      };
    case "silent_walking":
      return {
        'title': local.title_challenge_silent_walking,
        'body': local.body_challenge_silent_walking,
      };
    case "time":
      return {
        'title': local.title_challenge_time,
        'body': local.body_challenge_time,
      };
    case "end_trekking_arrival":
      return {
        'title': local.title_notification_arrival,
        'body': local.body_notification_arrival,
      };
    default:
      return {
        'title': "",
        'body': "",
      };
  }
}
