import 'package:flutter/material.dart';
import 'package:triplo/pages/geowatch/geowatch.dart';
import 'package:triplo/pages/landing_page/landing_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'package:triplo/pages/login_page/LoginPage.dart';
import 'pages/home-page.dart';
import 'pages/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triplo/pages/registration_page/registration_page.dart';
import 'firebase_options.dart';
import '/pages/login_page/LoginPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:triplo/pages/forgotten_password_page/forgotten_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await dotenv.load(fileName: ".env");


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triplo',
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
        Locale('fr')
      ],
      /*home: const SettingPage(onLocaleChanged: setLocale),*/
      home: MyHomePage(),

      //home: const SplashScreen(),
      //home: RegistrationPage(),


      initialRoute: '/landing_page',


      routes: {
        '/login' : (context) => LoginPage(),
        '/registration' : (context) => RegistrationPage(),
        '/forgotten_password' : (context) => ForgottenPasswordPage(),
        '/geowatch' : (context) => GeoWatchPage(),
        '/landing_page': (context) => Landing_Page(),
      },

    );
  }
}
