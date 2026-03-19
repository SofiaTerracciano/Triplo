import 'dart:async';
import 'dart:io';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../service/notification.dart';
import '../service/memory.dart';
// Controller for managing challenges data from Firestore
class ChallengesController extends ChangeNotifier {
  // Aggiungi queste variabili che riceverai nel costruttore
  final NotificationService notification;
  final MemoryService memory;

  ChallengesController({required this.notification, required this.memory});

  Future<File?> getCachedImage(String imagePath) async {
    debugPrint("getCachedImage challenge -> $imagePath");

    try {
      // 1. RAM Cache (Corretto)
      final inMemory = await memory.getImageFromMemory(imagePath);
      if (inMemory != null) {
        debugPrint("Challenge image found in RAM cache");
        return inMemory;
      }

      String cacheableUrl = imagePath;

      if (imagePath.startsWith("gs://")) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        cacheableUrl = await ref.getDownloadURL();
      }

      final cached = await memory.getImageFromDisk(cacheableUrl);
      if (cached != null) {
        debugPrint("Challenge image found in disk cache");
        memory.saveImageToMemory(imagePath, cached);
        return cached;
      }

      debugPrint("Challenge image not in cache, downloading");
      final file = await memory.cacheImageOnDisk(cacheableUrl); 
      memory.saveImageToMemory(imagePath, file);
      return file;

    } catch (e) {
      debugPrint("getCachedImage challenge error: $e");
      return null;
    }
  }

  void notifyNewChallenge(String challengeType, AppLocalizations local) {
    // 1. Recuperiamo i testi localizzati tramite la funzione helper
    final content = getChallengeContent(challengeType, local);
    
    // 2. DELEGHIAMO al servizio notifiche l'invio fisico della notifica
    notification.showTrekkingNotification(
      id: DateTime.now().millisecond, // ID univoco per non sovrascrivere notifiche precedenti
      title: content['title'] ?? "Challenge!",
      body: content['body'] ?? "",
      payload: challengeType, // Il payload permette al Service di sapere cosa mostrare al TAP
    );
  }

}