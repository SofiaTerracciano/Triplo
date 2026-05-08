import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triplo/service/permission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PermissionService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          switch (call.method) {
            case 'requestPermissions':
              final permissions = call.arguments as List;
              return {for (final p in permissions) p: 1}; 
            case 'checkPermissionStatus':
              return 1; // granted
            case 'openAppSettings':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      );
    });

    group('askPermissionsOnce()', () {
      test('completa senza eccezioni la prima volta', () async {
        SharedPreferences.setMockInitialValues({});
        final service = PermissionService();

        await expectLater(service.askPermissionsOnce(), completes);
      });

      test('salva il flag first_time_permissions_asked dopo la chiamata', () async {
        SharedPreferences.setMockInitialValues({});
        final service = PermissionService();

        await service.askPermissionsOnce();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('first_time_permissions_asked'), isTrue);
      });

      test('chiede locationAlways se location è granted', () async {
        SharedPreferences.setMockInitialValues({});
        final service = PermissionService();

        await expectLater(service.askPermissionsOnce(), completes);
      });

      test('non chiede locationAlways se location è denied', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'requestPermissions') {
              final permissions = call.arguments as List;
              return {
                for (final p in permissions)
                  p: p == 3 ? 0 : 1,
              };
            }
            if (call.method == 'checkPermissionStatus') return 0; // denied
            if (call.method == 'openAppSettings') return true;
            return null;
          },
        );

        SharedPreferences.setMockInitialValues({});
        final service = PermissionService();

        await expectLater(service.askPermissionsOnce(), completes);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('first_time_permissions_asked'), isTrue);
      });

      test('completa anche se già chiamata in precedenza (flag già true)', () async {
        SharedPreferences.setMockInitialValues({
          'first_time_permissions_asked': true,
        });
        final service = PermissionService();

        await expectLater(service.askPermissionsOnce(), completes);
      });
    });

    group('locationStatus()', () {
      test('restituisce PermissionStatus.granted quando il mock restituisce 1',
          () async {
        final service = PermissionService();
        final status = await service.locationStatus();
        expect(status, equals(PermissionStatus.granted));
      });

      test('restituisce PermissionStatus.denied quando il mock restituisce 0',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'checkPermissionStatus') return 0;
            return null;
          },
        );

        final service = PermissionService();
        final status = await service.locationStatus();
        expect(status, equals(PermissionStatus.denied));
      });
    });

    group('isLocationGranted()', () {
      test('restituisce true quando status è granted', () async {
        final service = PermissionService();
        final result = await service.isLocationGranted();
        expect(result, isTrue);
      });

      test('restituisce false quando status è denied', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'checkPermissionStatus') return 0;
            return null;
          },
        );

        final service = PermissionService();
        final result = await service.isLocationGranted();
        expect(result, isFalse);
      });

      test('restituisce false quando status è permanentlyDenied', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'checkPermissionStatus') return 2; 
            return null;
          },
        );

        final service = PermissionService();
        final result = await service.isLocationGranted();
        expect(result, isFalse);
      });
    });

    group('isLocationDenied()', () {
      test('restituisce true quando status è denied', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'checkPermissionStatus') return 0; 
            return null;
          },
        );

        final service = PermissionService();
        final result = await service.isLocationDenied();
        expect(result, isTrue);
      });

      test('restituisce false quando status è granted', () async {
        final service = PermissionService();
        final result = await service.isLocationDenied();
        expect(result, isFalse);
      });
    });

    group('openAppSettingsPage()', () {
      test('restituisce true quando openAppSettings ha successo', () async {
        final service = PermissionService();
        final result = await service.openAppSettingsPage();
        expect(result, isTrue);
      });

      test('restituisce false quando openAppSettings fallisce', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'openAppSettings') return false;
            return null;
          },
        );

        final service = PermissionService();
        final result = await service.openAppSettingsPage();
        expect(result, isFalse);
      });
    });
  });
}