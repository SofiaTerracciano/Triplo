import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  
  // Funzione unica per gestire la logica "solo la prima volta"
  static Future<void> askPermissionsOnce() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool alreadyAsked = prefs.getBool('first_time_permissions_asked') ?? false;

  if (!alreadyAsked) {
    // ASPETTIAMO 3 secondi per stabilizzare la sessione login
    await Future.delayed(const Duration(seconds: 3));
    
    // 1. Chiediamo le Notifiche
    await Permission.notification.request();

    // 2. Chiediamo la posizione STANDARD (While in use)
    // Questo farà apparire il pop-up che conosciamo tutti
    PermissionStatus status = await Permission.location.request();

    // 3. SOLO SE ha accettato il primo, allora (facoltativo) chiediamo il sempre
    if (status.isGranted) {
      // Nota: su Android questo potrebbe mandare l'utente in una pagina 
      // di impostazioni invece di mostrare un pop-up. 

      await Permission.locationAlways.request();
    }

    await prefs.setBool('first_time_permissions_asked', true);
  }
}
}