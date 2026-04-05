// File: lib/screens/splash_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // <-- Needed for the Apple-style loading spinner
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup a premium cinematic entrance animation
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800) // Smooth, deliberate 1.8s entrance
    );

    // Fade in gracefully
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale up slightly for a 3D "pop" effect (Apple loves this)
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2. Automatically navigate after 3.8 seconds
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        // --- PREMIUM UPGRADE: Custom Fade Transition ---
        // Instead of a harsh cut, it dissolves smoothly into the Home Screen
        Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1000), // 1 second smooth crossfade
            )
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep OLED Black Background
      body: Stack(
        children: [
          // ========================================================
          // 1. VIBRANT MESH GRADIENT BACKGROUND (Siri-style glow)
          // ========================================================
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowingOrb(const Color(0xFF4A00E0), 350), // Deep Purple
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlowingOrb(const Color(0xFF00B4DB), 300), // Electric Cyan
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _buildGlowingOrb(const Color(0xFF8A2387), 250), // Magenta highlight
          ),

          // ========================================================
          // 2. FOREGROUND 4K FROSTED GLASS CARD
          // ========================================================
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40), // Ultra-smooth Apple corners
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Heavy glass blur
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08), // Barely visible white tint
                        borderRadius: BorderRadius.circular(40),
                        // The secret to perfect glass is the thin, bright border
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- YOUR LOGO ---
                          Image.asset(
                            'assets/boitexinfo+tn.png',
                            width: 200,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 40),

                          // --- MODERN TYPOGRAPHY ---
                          Text(
                            "BOITEX INFO",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8.0, // Wide spacing is very premium
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "P R E M I U M   S Y S T E M S",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4.0,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),

                          const SizedBox(height: 60),

                          // --- APPLE iOS LOADER ---
                          const CupertinoActivityIndicator(
                            radius: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: Builds the massive blurry light orbs in the background ---
  Widget _buildGlowingOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 120, // Extreme blur to make it look like light, not a circle
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}