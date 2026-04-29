import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_triplo_wearos/service/OSservice/permission_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Handler che simula le risposte native di permission_handler
  const _permissionChannel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  // SharedPreferences usa una mappa in memoria nei test
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Helper: registra le risposte di permesso desiderate
  void _mockPermissions({
    required PermissionStatus notification,
    required PermissionStatus location,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, (call) async {
      if (call.method == 'checkPermissionStatus') {
        // Restituisce lo status corrente (prima del request)
        return PermissionStatus.denied.index;
      }
      if (call.method == 'requestPermissions') {
        // permission_handler passa una lista di interi (indici Permission)
        // e si aspetta una mappa <int, int> in risposta
        final List<int> permissions =
            List<int>.from(call.arguments as List);
        final result = <int, int>{};
        for (final p in permissions) {
          if (p == Permission.notification.value) {
            result[p] = notification.index;
          } else if (p == Permission.location.value) {
            result[p] = location.index;
          } else {
            result[p] = PermissionStatus.denied.index;
          }
        }
        return result;
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, null);
  });

  // ──────────────────────────────────────────────────────────────────────────

  group('PermissionService – askPermissionsOnce –', () {
    test('chiede i permessi la prima volta (flag non impostato)', () async {
      _mockPermissions(
        notification: PermissionStatus.granted,
        location: PermissionStatus.granted,
      );

      // Non deve lanciare e deve completare
      await expectLater(PermissionService.askPermissionsOnce(), completes);

      // Verifica che il flag sia stato scritto su SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('first_time_permissions_asked'), isTrue);
    });

    test('non chiede i permessi se il flag è già true', () async {
      // Pre-imposta il flag come già fatto
      SharedPreferences.setMockInitialValues({
        'first_time_permissions_asked': true,
      });

      // Registra un handler che farebbe fallire il test se venisse chiamato
      bool requestCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_permissionChannel, (call) async {
        if (call.method == 'requestPermissions') {
          requestCalled = true;
        }
        return null;
      });

      await PermissionService.askPermissionsOnce();

      expect(requestCalled, isFalse,
          reason: 'requestPermissions non deve essere chiamato se '
              'i permessi sono già stati chiesti');
    });

    test('scrive il flag anche quando i permessi vengono negati', () async {
      _mockPermissions(
        notification: PermissionStatus.denied,
        location: PermissionStatus.denied,
      );

      await PermissionService.askPermissionsOnce();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('first_time_permissions_asked'), isTrue);
    });

    test('scrive il flag anche quando i permessi sono permanentemente negati',
        () async {
      _mockPermissions(
        notification: PermissionStatus.permanentlyDenied,
        location: PermissionStatus.permanentlyDenied,
      );

      await PermissionService.askPermissionsOnce();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('first_time_permissions_asked'), isTrue);
    });

    test('chiamate multiple consecutive chiedono i permessi solo una volta',
        () async {
      _mockPermissions(
        notification: PermissionStatus.granted,
        location: PermissionStatus.granted,
      );

      int requestCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_permissionChannel, (call) async {
        if (call.method == 'requestPermissions') requestCount++;
        return {
          Permission.notification.value: PermissionStatus.granted.index,
          Permission.location.value: PermissionStatus.granted.index,
        };
      });

      await PermissionService.askPermissionsOnce();
      await PermissionService.askPermissionsOnce();
      await PermissionService.askPermissionsOnce();

      expect(requestCount, 1,
          reason: 'requestPermissions deve essere chiamato solo alla prima '
              'invocazione');
    });

    test('la chiave SharedPreferences usata è quella attesa', () async {
      _mockPermissions(
        notification: PermissionStatus.granted,
        location: PermissionStatus.granted,
      );

      await PermissionService.askPermissionsOnce();

      final prefs = await SharedPreferences.getInstance();
      // Verifica che esista esattamente quella chiave e non altre
      expect(prefs.containsKey('first_time_permissions_asked'), isTrue);
    });
  });
}