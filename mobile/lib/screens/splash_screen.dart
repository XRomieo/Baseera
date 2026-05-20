// screens/splash_screen.dart
// Dart-side splash — shows logo + "Baseera" wordmark + tagline,
// then fades into HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleTransition();
  }

  Future<void> _scheduleTransition() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseeraColors.bg,
      body: Stack(
        children: [
          // Soft purple radial glow
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Color(0x556C3FE8),
                      Color(0x3D6C3FE8),
                      Color(0x266C3FE8),
                      Color(0x146C3FE8),
                      Color(0x086C3FE8),
                      Color(0x000A0A12),
                    ],
                    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [BaseeraColors.gold, BaseeraColors.goldGlow],
                  ).createShader(rect),
                  child: Text(
                    'Baseera',
                    style: GoogleFonts.outfit(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),
                const SizedBox(height: 10),
                Text(
                  'Multi-source AI analyst',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: BaseeraColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BaseeraColors.primaryGlow,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AISeekho 2026',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: BaseeraColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
