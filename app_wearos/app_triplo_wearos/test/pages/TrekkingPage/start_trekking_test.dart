import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_triplo_wearos/controller/challenge.dart';
import 'package:app_triplo_wearos/controller/trekking.dart';
import 'package:app_triplo_wearos/model/trekking.dart';
import 'package:app_triplo_wearos/pages/trekkingPage/start_trekking.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'start_trekking_test.mocks.dart';

@GenerateMocks([TrekkingController, ChallengesController])
void main() {
  late MockTrekkingController trekkingCtrl;
  late MockChallengesController challengesCtrl;

  setUp(() {
    trekkingCtrl = MockTrekkingController();
    challengesCtrl = MockChallengesController();
  });

  Widget buildPage({
    required String trekkingId,
    Stream<Position>? positionStream,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrekkingController>.value(value: trekkingCtrl),
        ChangeNotifierProvider<ChallengesController>.value(
          value: challengesCtrl,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StartTrekkingPage(
          trekkingid: trekkingId,
          positionStreamOverride: positionStream,
        ),
      ),
    );
  }

  Position fakePosition(double lat, double lon) => Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );

  Trekking makeTrekking({
    String id = 'trek-1',
    String difficulty = 'easy',
    List<String> challenges = const [],
    List<LatLng>? points,
  }) {
    final pts = points ?? [const LatLng(45.0, 9.0), const LatLng(45.1, 9.1)];

    return Trekking(
      documentId: id,
      name: 'Test Trekking',
      mapPhoto: '',
      difficultyLevel: difficulty,
      distance: 10.0,
      estimatedTime: 3.0,
      elevationGain: 200.0,
      upGain: true,
      downGain: true,
      startingPoint: pts.isNotEmpty ? pts.first : const LatLng(0, 0),
      endingPoint: pts.isNotEmpty ? pts.last : const LatLng(0, 0),
      points: pts,
      startingPointName: 'Start',
      endingPointName: 'End',
      info: [],
      endingPointPhoto: '',
      description: [],
      picNicArea: false,
      familyFirendly: false,
      challenges: challenges,
    );
  }

  void stubTrekking({
    String id = 'trek-1',
    String difficulty = 'easy',
    List<String> challenges = const [],
    List<LatLng>? points,
  }) {
    when(trekkingCtrl.getTrekkingById(id)).thenReturn(
      makeTrekking(
        id: id,
        difficulty: difficulty,
        challenges: challenges,
        points: points,
      ),
    );
    when(trekkingCtrl.getDownloadUrl(any)).thenAnswer((_) async => '');
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required String trekkingId,
    Stream<Position>? positionStream,
  }) async {
    await tester.pumpWidget(
      buildPage(trekkingId: trekkingId, positionStream: positionStream),
    );
    await tester.pump();
  }

  group('Rendering', () {
    testWidgets("mostra il timer a '0:00:00' all'avvio", (tester) async {
      stubTrekking();
      await pumpPage(tester, trekkingId: 'trek-1');

      expect(find.text('0:00:00'), findsOneWidget);
    });

    testWidgets('mostra CircularProgressIndicator', (tester) async {
      stubTrekking();
      await pumpPage(tester, trekkingId: 'trek-1');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra GestureDetector per il pulsante stop', (tester) async {
      stubTrekking();
      await pumpPage(tester, trekkingId: 'trek-1');

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('sfondo Scaffold è nero', (tester) async {
      stubTrekking();
      await pumpPage(tester, trekkingId: 'trek-1');

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });

  group('Challenges', () {
    testWidgets(
      'notifyNewChallenge viene chiamato dopo 10 secondi se ci sono sfide',
      (tester) async {
        stubTrekking(
          challenges: ['https://cdn.example.com/fire_challenge.png'],
        );
        when(challengesCtrl.notifyNewChallenge(any, any)).thenReturn(null);

        await pumpPage(
          tester,
          trekkingId: 'trek-1',
          positionStream: const Stream.empty(),
        );

        await tester.pump(const Duration(seconds: 10));

        verify(challengesCtrl.notifyNewChallenge('fire', any)).called(1);
      },
    );

    testWidgets('notifyNewChallenge NON viene chiamato senza sfide', (
      tester,
    ) async {
      stubTrekking(challenges: []);

      await pumpPage(
        tester,
        trekkingId: 'trek-1',
        positionStream: const Stream.empty(),
      );

      await tester.pump(const Duration(seconds: 30));

      verifyNever(challengesCtrl.notifyNewChallenge(any, any));
    });

    testWidgets(
      'il nome della challenge viene estratto correttamente dalla URL',
      (tester) async {
        stubTrekking(
          challenges: ['https://cdn.example.com/water_challenge.png'],
        );
        when(challengesCtrl.notifyNewChallenge(any, any)).thenReturn(null);

        await pumpPage(
          tester,
          trekkingId: 'trek-1',
          positionStream: const Stream.empty(),
        );

        await tester.pump(const Duration(seconds: 10));

        verify(challengesCtrl.notifyNewChallenge('water', any)).called(1);
      },
    );

    testWidgets(
      'notifyNewChallenge viene chiamato in ordine per sfide multiple',
      (tester) async {
        stubTrekking(
          challenges: [
            'https://cdn.example.com/fire_challenge.png',
            'https://cdn.example.com/rock_challenge.png',
          ],
        );
        when(challengesCtrl.notifyNewChallenge(any, any)).thenReturn(null);

        await pumpPage(
          tester,
          trekkingId: 'trek-1',
          positionStream: const Stream.empty(),
        );

        await tester.pump(const Duration(seconds: 10));
        verify(challengesCtrl.notifyNewChallenge('fire', any)).called(1);

        await tester.pump(const Duration(seconds: 10));
        verify(challengesCtrl.notifyNewChallenge('rock', any)).called(1);
      },
    );

    testWidgets(
      'il timer challenge si ferma dopo aver esaurito tutte le sfide',
      (tester) async {
        stubTrekking(
          challenges: ['https://cdn.example.com/snow_challenge.png'],
        );
        when(challengesCtrl.notifyNewChallenge(any, any)).thenReturn(null);

        await pumpPage(
          tester,
          trekkingId: 'trek-1',
          positionStream: const Stream.empty(),
        );

        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 10));

        verify(challengesCtrl.notifyNewChallenge(any, any)).called(1);
      },
    );
  });

  group('Dispose', () {
    testWidgets('nessuna eccezione al dispose del widget', (tester) async {
      stubTrekking();
      await pumpPage(
        tester,
        trekkingId: 'trek-1',
        positionStream: const Stream.empty(),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(tester.takeException(), isNull);
    });
  });
}
