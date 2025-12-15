import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triplo/controller/API.dart';
import 'package:triplo/pages/user-page-public.dart';
import 'firebase_options.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';

import 'package:triplo/pages/landing_page/landing_page.dart';

import 'package:triplo/pages/login_page/LoginPage.dart';
import 'package:triplo/pages/registration_page/registration_page.dart';
import 'package:triplo/pages/forgotten_password_page/forgotten_password_page.dart';
import 'package:triplo/pages/geowatch/geowatch.dart';

// solo per caricare i punti di un trekking
import 'package:triplo/update_points.dart';

import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/diary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env file not found — continuing without it.");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  late TrekkingController trekkingController;
  late DiaryController diaryController;
  late UserController userController;

  @override
  void initState() {
    super.initState();

    trekkingController = TrekkingController(trekkings: []);
    // Update UI after loading trekkings
    trekkingController.loadTrekking().then((_) {
      setState(() {});
    });

    diaryController = DiaryController();

    userController = UserController();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserController()),
        ],
      child: MaterialApp(
        title: 'Triplo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
          useMaterial3: true,
        ),
        locale: _locale,
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

        // Usa le routes (niente 'home:' in questo caso)
        initialRoute: '/landing_page',
        routes: {
          '/landing_page': (context) => Landing_Page(
            trekkingController: trekkingController,
            userController: userController,
            diaryController: diaryController,
            onLocaleChanged: setLocale,
          ), // o LandingPage() se la tua classe si chiama così
          '/login': (context) => LoginPage(
            trekkingController: trekkingController,
            userController: userController,
            diaryController: diaryController,
            onLocaleChanged: setLocale,
          ),
          '/registration': (context) => RegistrationPage(
            trekkingController: trekkingController,
            userController: userController,
            diaryController: diaryController,
            onLocaleChanged: setLocale,
          ),
          '/forgotten_password': (context) => ForgottenPasswordPage(),
          '/geowatch': (context) => const GeoWatchPage(),

          // bottone per caricare i punti di un trekking
          '/admin_upload': (context) => const AdminUploadPage(),

            "/userProfileRemote": (context) => UserPagePublic(
              userId: ModalRoute.of(context)!.settings.arguments as String,
              diaryController: diaryController,
              trekkingController: trekkingController,
              userController: userController,
              onLocaleChanged: (l) {},
            ),
          },



      ),
    );
  }
}
