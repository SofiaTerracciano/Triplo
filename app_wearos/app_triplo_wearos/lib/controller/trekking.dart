import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trekking.dart';
import 'package:flutter/material.dart';
import '../service/OSservice/notification.dart';
import '../service/OSservice/geo.dart';
import '../service/OSservice/memory.dart';
import '../service/pairing_service.dart';
// Controller for managing trekking data
class TrekkingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GeoService geo;
  final MemoryService memory;
  final NotificationService notification;
  final PairingService pairingService;

  List<Trekking> _trekkings;
  bool _loaded = false;
  late final CollectionReference<Map<String, dynamic>> _weatherNotificationRef;

  TrekkingController({
    required List<Trekking> trekkings,
    required this.geo,
    required this.memory,
    required this.notification,
    required this.pairingService,
  }) : _trekkings = trekkings {
    _weatherNotificationRef = _db.collection('weather_notification');
  }
  String? get uid => pairingService.effectiveUid;
  // Getter for all trekkings
  List<Trekking> get allTrekkings => _trekkings;

  //Load trekkings from Firestore
  Future<void> loadTrekking() async {
    if (_loaded) return; // To avoid reloading
    _loaded = true;

    // Fetch trekking documents from Firestore
    final snap = await _db
        .collection('trekking')
        .get();


    // Map documents to Trekking objects and store in the list --> this function create a
    //list of istance of trekkning (model)
    _trekkings = snap.docs
        .map((doc) => Trekking.fromMap(doc.data(), docId: doc.id))
        .toList();

    notifyListeners();
  }

  // Callback when a trekking is selected
  void Function(Trekking trekking)? onTrekkingSelected;

  // Getter trekking per documentId --> it return the trekking instance given the ID
  Trekking? getTrekkingById(String documentId) {
    try {
      return _trekkings.firstWhere((t) => t.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  Future<Trekking?> getTrekkingByIdAsync(String documentId) async {
    final local = getTrekkingById(documentId);
    if (local != null) return local;

    try {
      final doc = await _db.collection("trekking").doc(documentId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Trekking.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      debugPrint("Error loading trekking by id: $e");
      return null;
    }
  }

  String? getTrekkingId(String name) {
    try {
      return _trekkings.firstWhere((t) => t.name == name).documentId;
    } catch (_) {
      return null;
    }
  }

  // Fetch image URLs from Firebase Storage given a list of complete firestore url
  // It returns a list of download URLs that can be used to display images
  Future<List<String>> getDownloadUrls(List<String> paths) async {
    return await Future.wait(paths.map((path) async {
      Reference ref = FirebaseStorage.instance.refFromURL(path);
      return await ref.getDownloadURL();
    }));
  }

  // Fetch image URL from Firebase Storage given complete firestore url
  // It returns a only one download URL that can be used to display the image
  Future<String> getDownloadUrl(String path) async {
    Reference ref = FirebaseStorage.instance.refFromURL(path);
    return await ref.getDownloadURL();
  }

   // Metodo per gestire l'arrivo
  Future<void> checkArrival(String trekkingId, double distanceInMeters, AppLocalizations local) async {
    // Se la distanza è inferiore a 1000 metri (o quella che preferisci)
    if (distanceInMeters <= 1000) {
      final content = notificationcontent('end_trekking_arrival', local);

      await notification.showTrekkingNotification(
        id: 999,
        title: content['title']!,
        body: content['body']!,
        payload: 'end_trekking_arrival',
        channelId: 'arrival_channel',
        channelName: 'Notifications',
      );
    }
  }

  Future<bool> isWeatherAlertEnabled(String trekkingId) async {
    if (uid == null) return false;

    final snap = await _weatherNotificationRef.doc(uid).get();
    final ids = List<String>.from(snap.data()?['trekkingIds'] ?? []);
    return ids.contains(trekkingId);
  }

  Future<List<String>> getWeatherAlertTrekkingIds() async {
    if (uid == null) return [];

    final snap = await _weatherNotificationRef.doc(uid).get();
    return List<String>.from(snap.data()?['trekkingIds'] ?? []);
  }

  Future<List<Trekking>> getWeatherAlertTrekkings() async {
    final ids = await getWeatherAlertTrekkingIds();
    final trekkings = await Future.wait(ids.map(getTrekkingByIdAsync));
    return trekkings.whereType<Trekking>().toList();
  }

  Future<void> enableWeatherAlertForTrekking(String trekkingId) async {
    if (uid == null) return;

    await _weatherNotificationRef.doc(uid).set({
      'userId': uid,
      'trekkingIds': FieldValue.arrayUnion([trekkingId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disableWeatherAlertForTrekking(String trekkingId) async {
    if (uid == null) return;

    await _weatherNotificationRef.doc(uid).set({
      'userId': uid,
      'trekkingIds': FieldValue.arrayRemove([trekkingId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}