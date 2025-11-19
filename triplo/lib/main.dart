import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';


import 'package:triplo/pages/landing_page/landing_page.dart';

import 'package:triplo/pages/login_page/LoginPage.dart';
import 'package:triplo/pages/registration_page/registration_page.dart';
import 'package:triplo/pages/forgotten_password_page/forgotten_password_page.dart';
import 'package:triplo/pages/geowatch/geowatch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/landing_page': (context) => Landing_Page(), // o LandingPage() se la tua classe si chiama così
        '/login': (context) => const LoginPage(),
        '/registration': (context) => const RegistrationPage(),
        '/forgotten_password': (context) => ForgottenPasswordPage(),
        '/geowatch': (context) => const GeoWatchPage(),
      },
    );
  }
}