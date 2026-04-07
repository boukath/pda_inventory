// File: lib/screens/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';
import 'simple_home_screen.dart';
import 'rfid_dashboard_screen.dart'; // <-- IMPORT THE NEW SCREEN
import '../license_helper.dart'; // <-- IMPORT THE NEW HIDDEN FILE HELPER

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  // --- NEW LOGIC: We now pass a String identifier instead of a boolean ---
  Future<void> _selectMode(BuildContext context, String mode) async {
    // 1. REPLACE the SharedPreferences saving with our LicenseHelper
    // This saves it to normal memory AND the hidden secure folder!
    await LicenseHelper.saveLicense(mode);

    if (!context.mounted) return;

    // Decide which screen to show based on the string
    Widget nextScreen;
    if (mode == 'simple') {
      nextScreen = const SimpleHomeScreen();
    } else if (mode == 'rfid') {
      nextScreen = const RfidDashboardScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0045),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Choose App Mode",
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 40),

              // 1. Simple Mode Button
              _buildModeButton(
                title: "Simple Mode",
                subtitle: "Fast scanning (Inventaire, Reception, Bon)",
                icon: Icons.qr_code_scanner,
                onTap: () => _selectMode(context, 'simple'), // Pass string
              ),
              const SizedBox(height: 16),

              // 2. Advanced Mode Button
              _buildModeButton(
                title: "Advanced Mode",
                subtitle: "Full database, prices, and suppliers",
                icon: Icons.storage,
                onTap: () => _selectMode(context, 'advanced'), // Pass string
              ),
              const SizedBox(height: 16),

              // 3. NEW: RFID Mode Button
              _buildModeButton(
                title: "RFID Mode",
                subtitle: "UHF scanning, mass inventory & review",
                icon: Icons.wifi_tethering,
                onTap: () => _selectMode(context, 'rfid'), // Pass string
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF4A00E0)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}