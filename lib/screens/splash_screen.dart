// File: lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

// --- IMPORTS FOR BACKGROUND ROUTING ---
import '../license_helper.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';
import 'simple_home_screen.dart';
import 'rfid_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Kick off the routing instantly in the background
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final String? initialMode = await LicenseHelper.getLicense();

    Widget startScreen;
    if (initialMode == 'simple') {
      startScreen = const SimpleHomeScreen();
    } else if (initialMode == 'rfid') {
      startScreen = const RfidDashboardScreen();
    } else if (initialMode == 'advanced') {
      startScreen = const HomeScreen();
    } else {
      startScreen = const ModeSelectionScreen();
    }

    // Safely navigate instantly (Zero transition duration)
    if (mounted) {
      Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => startScreen,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A completely blank, solid white screen. No logo, no loader.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(), // Draws absolutely nothing, maximizing performance
    );
  }
}