import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'home-page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _sloganController;

  late Animation<double> _tScale;
  late Animation<double> _tOpacity;
  late Animation<Offset> _riploSlide;
  late Animation<double> _riploOpacity;
  late Animation<double> _sloganOpacity;

  // Initialize animations
  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Slogan animation controller
    _sloganController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // "T" animation
    _tScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // "T" opacity animation
    _tOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // "riplo" animation
    _riploSlide = Tween<Offset>(begin: const Offset(0.4, 0.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // "riplo" opacity animation
    _riploOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Slogan animation
    _sloganOpacity = CurvedAnimation(
      parent: _sloganController,
      curve: Curves.easeIn,
    );

    // When the widget is built, start the animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      _sloganController.forward();
    });

    // Navigate to home page after 4 seconds
    Future.delayed(const Duration(milliseconds: 4000), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MyHomePage()));
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Patterned background
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(255, 218, 249, 215),
              child: Opacity(
                opacity: 0.25, // slight transparency
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final emojiSize = 60.0;
                    final cols = (width / emojiSize).ceil();
                    final rows = (height / emojiSize).ceil();

                    // Full grid di emoji
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(rows, (y) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(cols, (x) {
                            final emojis = ['🏔️', '🌲', '🗻', '⛺', '🔥', '🥾'];
                            final e = emojis[(x + y) % emojis.length];
                            return Text(
                              e,
                              style: const TextStyle(fontSize: 20),
                            );
                          }),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),

          // Central zone for logo and slogan
          Align(
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Triplo logo animation
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _tScale,
                          child: FadeTransition(
                            opacity: _tOpacity,
                            child: const Text(
                              'T',
                              style: TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 1, 89, 11),
                              ),
                            ),
                          ),
                        ),
                        SlideTransition(
                          position: _riploSlide,
                          child: FadeTransition(
                            opacity: _riploOpacity,
                            child: const Text(
                              'riplo',
                              style: TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  FadeTransition(
                    opacity: _sloganOpacity,
                    child: const Text(
                      'Your trip, multiplied by connections',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
