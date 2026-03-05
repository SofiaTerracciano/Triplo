import 'package:app_triplo_wearos/controller/API.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/home-page.dart';
import 'package:app_triplo_wearos/pages/landing_page.dart';
import 'package:app_triplo_wearos/pages/login.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:app_triplo_wearos/pages/user.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:app_triplo_wearos/controller/user.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env file not found — continuing without it.");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);




  final watchId = await WatchIdService.getOrCreateWatchId();

  runApp(TriploWatchApp(watchId: watchId));
}

class TriploWatchApp extends StatefulWidget {
  final String watchId;
  const TriploWatchApp({super.key, required this.watchId});


  @override
  State<TriploWatchApp> createState() => _TriploWatchAppState();
}




class _TriploWatchAppState extends State<TriploWatchApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Provide controllers to the app --> state management
      providers: [
        //ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => DiaryController()),
        ChangeNotifierProvider(
          create: (_) => TrekkingController(trekkings: []),
        ),
        ChangeNotifierProvider(create: (_) => Language()),
        ChangeNotifierProvider(create: (_) => UserController(watchId: widget.watchId)),
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
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlueAccent,
              ),
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
            home: NavigationPage(),
          );
        },
      ),
    );
  }

}