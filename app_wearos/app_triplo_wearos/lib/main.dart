import 'package:app_triplo_wearos/controller/API.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/language.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/pages/navigation.dart';
import 'package:app_triplo_wearos/service/watch_id_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:app_triplo_wearos/controller/user.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env file not found — continuing without it.");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



  final watchId = await WatchIdService.getOrCreateWatchId();

  const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final context = navKey.currentContext;
      if (context == null) return;

      final String payload = response.payload ?? "";

      if (payload == 'end_trekking_arrival') {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "📍 Destinazione vicina!",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getChallengeBody(payload),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK", style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🥾 È ora di una sfida!",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getChallengeBody(payload),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK", style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    },
  );

  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'notifications_channel',
        'Notifications',
        importance: Importance.high,
      ),
    );
  
  await flutterLocalNotificationsPlugin
  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  ?.createNotificationChannel(
    const AndroidNotificationChannel(
      'arrival_channel',
      'Arrivo Trekking',
      importance: Importance.high,
    ),
  );

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
            navigatorKey: navKey,
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

String _getChallengeBody(String challenge) {
  switch (challenge) {
    case "balance":
      return "Metti alla prova il tuo equilibrio!";
    case "hi":
      return "Saluta qualcuno che incontri sul sentiero!";
    case "mini_orientiring":
      return "Trova la tua strada!";
    case "photo":
      return "Scatta una foto al paesaggio!";
    case "silent_walking":
      return "Cammina in silenzio per qualche minuto!";
    case "time":
      return "Quanto tempo riesci senza guardare il telefono?";
    default:
      return "Sei quasi arrivato. Tocca per completare il percorso.";
  }
}