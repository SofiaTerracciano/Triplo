import 'package:flutter/material.dart';
import 'home-page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _tSlide;      // T move left
  late Animation<Offset> _riploSlide;  // "riplo" comes from right
  late AnimationController _sloganController;
  late Animation<double> _sloganOpacity;

  @override
  void initState() {
    super.initState();

    // Controller for logo animation: "T" e "riplo"
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // "T" goes from left to center-left
    _tSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    // "riplo" comes from right to center-right (after "T" has moved)
    _riploSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    // Slogan fade-in
    _sloganController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sloganOpacity = CurvedAnimation(
      parent: _sloganController,
      curve: Curves.easeIn,
    );

    // Timeline
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      _sloganController.forward();
    });

    // After 3.5 seconds, navigate to HomePage
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Triplo logo with animations
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SlideTransition(
                    position: _tSlide,
                    child: const Text(
                      'T',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _riploSlide,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 40.0),
                      child: Text(
                        'riplo',
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _sloganOpacity,
              child: const Text(
                'Your trip, multiplied by connections',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
