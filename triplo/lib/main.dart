import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triplo/controller/language.dart';
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





import 'package:triplo/controller/API.dart';
import 'package:triplo/service/notification.dart';
import 'package:triplo/service/observer.dart';


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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Provide controllers to the app --> state management
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final controller = UserController();
            controller.tryAutoLogin();
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider(create: (_) => TrekkingController(trekkings: [])),
        ChangeNotifierProvider(create: (_) => Language()),

        Provider<API>(create: (_) => API()),

        /*
        Provider<NotificationService>(
          create: (_) {
            final service = NotificationService();
            service.init();
            return service;
          },
        ),


        Provider<ObserverService>(
          create: (context) => ObserverService(
            api: context.read<API>(),
            notificationService: context.read<NotificationService>(),
          ),
        ),
         */

      ],
      child: Consumer<Language>(
        builder: (context, lang, child) {
          return MaterialApp(
            title: 'Triplo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
              useMaterial3: true,
            ),
            // This is for localization --> set the app language based on Language controller
            locale: lang.locale, //
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Supported locales --> English, Italian, Spanish, German, French
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
              //'/admin_upload': (context) => const AdminBuildTrekkingIndexPage(),
              "/userProfileRemote": (context) => UserPagePublic(
                    userId: ModalRoute.of(context)!.settings.arguments as String,
                  ),
            },
          );
        },
      ),
    );
  }
}
