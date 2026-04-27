import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_triplo_wearos/controller/challenge.dart';
import 'package:app_triplo_wearos/service/OSservice/notification.dart';
import 'package:app_triplo_wearos/service/OSservice/memory.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
@GenerateMocks([NotificationService, MemoryService, AppLocalizations])
import 'challenge_test.mocks.dart';
import 'trekking_test.mocks.dart' hide MockNotificationService, MockAppLocalizations, MockMemoryService;

void main() {
  late MockNotificationService mockNotification;
  late MockMemoryService mockMemory;
  late MockAppLocalizations mockLocal;

  ChallengesController makeCtrl() =>
      ChallengesController(notification: mockNotification, memory: mockMemory);

  setUp(() {
    mockNotification = MockNotificationService();
    mockMemory = MockMemoryService();
    mockLocal = MockAppLocalizations();

    when(mockNotification.showTrekkingNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async {});

    when(mockLocal.title_challenge_balance).thenReturn('Balance Title');
    when(mockLocal.body_challenge_balance).thenReturn('Balance Body');
    when(mockLocal.alert_challenge_balance).thenReturn('Balance Alert');
    when(mockLocal.title_challenge_hi).thenReturn('Hi Title');
    when(mockLocal.body_challenge_hi).thenReturn('Hi Body');
    when(mockLocal.alert_challenge_hi).thenReturn('Hi Alert');
    when(mockLocal.title_challenge_mini_orientiring).thenReturn('Orientiring Title');
    when(mockLocal.body_challenge_mini_orientiring).thenReturn('Orientiring Body');
    when(mockLocal.alert_challenge_mini_orientiring).thenReturn('Orientiring Alert');
    when(mockLocal.title_challenge_photo).thenReturn('Photo Title');
    when(mockLocal.body_challenge_photo).thenReturn('Photo Body');
    when(mockLocal.alert_challenge_photo).thenReturn('Photo Alert');
    when(mockLocal.title_challenge_silent_walking).thenReturn('Silent Title');
    when(mockLocal.body_challenge_silent_walking).thenReturn('Silent Body');
    when(mockLocal.alert_challenge_silent_walking).thenReturn('Silent Alert');
    when(mockLocal.title_challenge_time).thenReturn('Time Title');
    when(mockLocal.body_challenge_time).thenReturn('Time Body');
    when(mockLocal.alert_challenge_time).thenReturn('Time Alert');
    when(mockLocal.title_notification_arrival).thenReturn('Arrival Title');
    when(mockLocal.body_notification_arrival).thenReturn('Arrival Body');
    when(mockLocal.alert_notification_arrival).thenReturn('Arrival Alert');
  });

  group('notifyNewChallenge', () {
    void verifyNotif({required String title, required String body, required String payload}) {
      verify(mockNotification.showTrekkingNotification(
        id: anyNamed('id'),
        title: title,
        body: body,
        payload: payload,
      )).called(1);
    }

    test('balance → testi corretti', () {
      makeCtrl().notifyNewChallenge('balance', mockLocal);
      verifyNotif(title: 'Balance Title', body: 'Balance Body', payload: 'balance');
    });

    test('hi → testi corretti', () {
      makeCtrl().notifyNewChallenge('hi', mockLocal);
      verifyNotif(title: 'Hi Title', body: 'Hi Body', payload: 'hi');
    });

    test('mini_orientiring → testi corretti', () {
      makeCtrl().notifyNewChallenge('mini_orientiring', mockLocal);
      verifyNotif(title: 'Orientiring Title', body: 'Orientiring Body', payload: 'mini_orientiring');
    });

    test('photo → testi corretti', () {
      makeCtrl().notifyNewChallenge('photo', mockLocal);
      verifyNotif(title: 'Photo Title', body: 'Photo Body', payload: 'photo');
    });

    test('silent_walking → testi corretti', () {
      makeCtrl().notifyNewChallenge('silent_walking', mockLocal);
      verifyNotif(title: 'Silent Title', body: 'Silent Body', payload: 'silent_walking');
    });

    test('time → testi corretti', () {
      makeCtrl().notifyNewChallenge('time', mockLocal);
      verifyNotif(title: 'Time Title', body: 'Time Body', payload: 'time');
    });

    test('end_trekking_arrival → testi corretti', () {
      makeCtrl().notifyNewChallenge('end_trekking_arrival', mockLocal);
      verifyNotif(title: 'Arrival Title', body: 'Arrival Body', payload: 'end_trekking_arrival');
    });

    test('weather_alert → usa title hardcoded', () {
      makeCtrl().notifyNewChallenge('weather_alert', mockLocal);
      verify(mockNotification.showTrekkingNotification(
        id: anyNamed('id'),
        title: 'Weather alert',
        body: anyNamed('body'),
        payload: 'weather_alert',
      )).called(1);
    });

    test('payload sconosciuto → title e body vuoti', () {
      makeCtrl().notifyNewChallenge('unknown', mockLocal);
      verifyNotif(title: '', body: '', payload: 'unknown');
    });

    test('showTrekkingNotification chiamato esattamente una volta', () {
      makeCtrl().notifyNewChallenge('balance', mockLocal);
      verify(mockNotification.showTrekkingNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
      )).called(1);
    });
  });

  group('getCachedImage', () {
    final fakeFile = File('/tmp/fake_image.jpg');

    test('restituisce immagine dalla RAM cache se presente', () async {
      when(mockMemory.getImageFromMemory('http://img.url'))
          .thenAnswer((_) async => fakeFile);

      final result = await makeCtrl().getCachedImage('http://img.url');

      expect(result, fakeFile);
      verify(mockMemory.getImageFromMemory('http://img.url')).called(1);
      verifyNever(mockMemory.getImageFromDisk(any));
    });

    test('cerca su disco se non in RAM, salva in RAM e restituisce', () async {
      when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
      when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => fakeFile);
      when(mockMemory.saveImageToMemory(any, any)).thenReturn(null);

      final result = await makeCtrl().getCachedImage('http://img.url');

      expect(result, fakeFile);
      verify(mockMemory.getImageFromDisk('http://img.url')).called(1);
      verify(mockMemory.saveImageToMemory('http://img.url', fakeFile)).called(1);
    });

    test('scarica da rete se non in RAM né su disco', () async {
      when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
      when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => null);
      when(mockMemory.cacheImageOnDisk(any)).thenAnswer((_) async => fakeFile);
      when(mockMemory.saveImageToMemory(any, any)).thenReturn(null);

      final result = await makeCtrl().getCachedImage('http://img.url');

      expect(result, fakeFile);
      verify(mockMemory.cacheImageOnDisk('http://img.url')).called(1);
      verify(mockMemory.saveImageToMemory('http://img.url', fakeFile)).called(1);
    });

    test('restituisce null se getImageFromMemory lancia eccezione', () async {
      when(mockMemory.getImageFromMemory(any)).thenThrow(Exception('RAM error'));

      final result = await makeCtrl().getCachedImage('http://img.url');

      expect(result, isNull);
    });

    test('restituisce null se cacheImageOnDisk lancia eccezione', () async {
      when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);
      when(mockMemory.getImageFromDisk(any)).thenAnswer((_) async => null);
      when(mockMemory.cacheImageOnDisk(any)).thenThrow(Exception('Network error'));

      final result = await makeCtrl().getCachedImage('http://img.url');

      expect(result, isNull);
    });

    test('path gs:// → Firebase non inizializzato → catch → restituisce null', () async {
      when(mockMemory.getImageFromMemory(any)).thenAnswer((_) async => null);

      final result = await makeCtrl().getCachedImage('gs://bucket/image.jpg');

      expect(result, isNull);
      verifyNever(mockMemory.getImageFromDisk('gs://bucket/image.jpg'));
    });
  });
}
