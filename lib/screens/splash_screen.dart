import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../widgets/metro_card_pulse_logo.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final StorageService storageService;

  const SplashScreen({super.key, required this.storageService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Windows 8 Metro 3D Y-Axis Flip Entrance
    _flipAnimation = Tween<double>(begin: -math.pi / 2, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Navigate to MainNavigationScreen after 2.0 seconds
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainNavigationScreen(storageService: widget.storageService),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Metro Obsidian Background
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final angle = _flipAnimation.value;
            final opacity = _opacityAnimation.value;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // 3D Perspective depth
                ..rotateY(angle),
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sleek Credit Card Pulse Logo
                    const MetroCardPulseLogo(
                      width: 110,
                      height: 70,
                    ),

                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      'CARDPULSE',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'OFFLINE CREDIT CARD & EMI ENGINE',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFA0A0A0),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Metro Rolling Dots Progress Indicator
                    const _MetroRollingDotsProgress(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Windows 8 Metro Dot Rolling Progress Animation
class _MetroRollingDotsProgress extends StatefulWidget {
  const _MetroRollingDotsProgress();

  @override
  State<_MetroRollingDotsProgress> createState() => _MetroRollingDotsProgressState();
}

class _MetroRollingDotsProgressState extends State<_MetroRollingDotsProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final progress = (_controller.value + (index * 0.15)) % 1.0;
            final opacity = (math.sin(progress * math.pi)).clamp(0.2, 1.0);

            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.rectangle, // Windows Metro square dots!
              ),
            );
          }),
        );
      },
    );
  }
}
