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

// solo per caricare i punti di un trekking
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

  // ===== Service principali creati una sola volta =====
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

  await flutterLocalNotificationsPlugin.initialize(initSettings, onDidReceiveNotificationResponse: (NotificationResponse response) {
    final context = navKey.currentContext;
    if (context == null) return;

    final String challenge = response.payload ?? "sfida";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🥾 È ora di una sfida!"),
        content: Text(_getChallengeBody(challenge)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  },);
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

        /// Controllers
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider.value(value: language),

        /// Services condivisi
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
        /// API (dipende da OSService)
        ProxyProvider<OSService, API>(
          update: (_, os, __) => API(os: os),
        ),

        /// InternetService (dipende da API)
        ChangeNotifierProxyProvider<API, InternetService>(
          create: (context) =>
          InternetService(api: context.read<API>())..start(),
          update: (context, api, old) =>
          old ?? InternetService(api: api)..start(),
        ),

        /// UserController (dipende da AuthService)
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


      child: Consumer2<Language, InternetService>(
        builder: (context, lang, internet, child) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = navKey.currentState;
            if (nav == null) return;

            if (!internet.isOnline) {
              nav.pushNamedAndRemoveUntil('/offline', (r) => false);
            } else {
              nav.pushNamedAndRemoveUntil('/landing_page', (r) => false);
            }
          });

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
                userId: ModalRoute.of(context)!.settings.arguments as String,
              ),

              '/offline': (context) => const OfflinePage(),
              '/navigation': (context) => CompassAltitudePage(),
            },
          );
        },
      ),
    );
  }
}
String _getChallengeBody(String challenge) {
  switch (challenge) {
    case "balance": return "Metti alla prova il tuo equilibrio!";
    case "hi": return "Saluta qualcuno che incontri sul sentiero!";
    case "mini_orientiring": return "Trova la tua strada!";
    case "photo": return "Scatta una foto al paesaggio!";
    case "silent_walking": return "Cammina in silenzio per qualche minuto!";
    case "time": return "Quanto tempo riesci senza guardare il telefono?";
    default: return "È il momento di una nuova sfida. Buona fortuna!";
  }
}