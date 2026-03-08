import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class CompassAltitudePage extends StatefulWidget {
  const CompassAltitudePage({super.key});

  @override
  State<CompassAltitudePage> createState() => _CompassAltitudePageState();
}

class _CompassAltitudePageState extends State<CompassAltitudePage> {
  StreamSubscription<Position>? _positionSub;
  double? _altitude;
  String? _error;

  Position? _position;
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Servizi di localizzazione disattivati';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permesso di localizzazione non concesso';
        });
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          _altitude = position.altitude;
          _position = position;
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Errore: $e';
      });
    }
  }

  String _directionLabel(double heading) {
    const directions = [
      'N',
      'NE',
      'E',
      'SE',
      'S',
      'SW',
      'W',
      'NW'
    ];
    final index = ((heading + 22.5) ~/ 45) % 8;
    return directions[index];
  }

  String _directionFullLabel(String shortLabel) {
    switch (shortLabel) {
      case 'N':
        return 'Nord';
      case 'NE':
        return 'Nord-Est';
      case 'E':
        return 'Est';
      case 'SE':
        return 'Sud-Est';
      case 'S':
        return 'Sud';
      case 'SW':
        return 'Sud-Ovest';
      case 'W':
        return 'Ovest';
      case 'NW':
        return 'Nord-Ovest';
      default:
        return shortLabel;
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(

      appBar: AppBar(
        title: const Text('Navigazione'),
        centerTitle: true,
      ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE8F5E9),
                Color(0xFFC8E6C9),
                Color(0xFFA5D6A7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(

          child: _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        )
            : StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final heading = snapshot.data?.heading;

            if (heading == null) {
              return const Center(
                child: Text(
                  'Bussola non disponibile',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final shortDirection = _directionLabel(heading);
            final fullDirection = _directionFullLabel(shortDirection);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${heading.toStringAsFixed(0)}°',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$fullDirection ($shortDirection)',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Altitudine',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _altitude != null
                                  ? '${_altitude!.toStringAsFixed(1)} m'
                                  : 'Calcolo in corso...',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posizione',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                                _position != null
                                    ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                                    : 'Calcolo coordinate...'
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
        )
    );
  }
}