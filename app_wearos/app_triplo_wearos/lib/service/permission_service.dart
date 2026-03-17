import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _kAskedKey = 'first_time_permissions_asked';

  static Future<void> askPermissionsOnce() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
  
    bool alreadyAsked = prefs.getBool(_kAskedKey) ?? false;

    if (!alreadyAsked) {
      // Un piccolo delay per lasciare che la UserPage si carichi graficamente
      await Future.delayed(const Duration(seconds: 2));
      
      // 1. Chiediamo Notifiche e Posizione base insieme
      // Questo ottimizza la coda dei dialoghi di sistema
      Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
        Permission.location,
      ].request();

      // 2. Opzionale: Permesso in Background (Background Location)
      // Solo se strettamente necessario per il trekking a schermo spento
      if (statuses[Permission.location]!.isGranted) {
        // Su Wear OS, questo spesso apre una schermata di impostazioni di sistema
        // valutare bene se serve davvero.
        // await Permission.locationAlways.request();
      }

      await prefs.setBool(_kAskedKey, true);
    }
  }
}