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



// solo per caricare i punti di un trekking
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //final language = Language();
  //await language.loadSavedLocale();

  final os = OSService();

  final language = Language(os: os);

  await language.loadSavedLocale();

  runApp(MyApp(language: language));
}

class MyApp extends StatelessWidget {
  final Language language;
  const MyApp({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider(create: (_) => TrekkingController(trekkings: [])),


        ChangeNotifierProvider.value(value: language),

        Provider<OSService>(
          create: (_) => OSService(),
        ),

        ProxyProvider<OSService, API>(
          update: (_, os, __) => API(os: os),
        ),
        ChangeNotifierProxyProvider<API, InternetService>(
          create: (context) => InternetService(api: context.read<API>())..start(),
          update: (context, api, old) => old ?? InternetService(api: api)..start(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
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
        ChangeNotifierProvider(create: (_) => ChallengesController()),
      ],
      child: Consumer2<Language, InternetService>(
        builder: (context, lang, internet, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = navKey.currentState;
            if (nav == null) return;

            if (!internet.isOnline) {
              nav.pushNamedAndRemoveUntil('/offline', (r) => false);
            } else {
              // quando torna online: vai alla home
              nav.pushNamedAndRemoveUntil('/landing_page', (r) => false);
            }
          });

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
              '/navigation': (context) => CompassAltitudePage()
            },
          );
        },
      ),
    );
  }
}

