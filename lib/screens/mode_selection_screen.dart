// File: lib/screens/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'simple_home_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future<void> _selectMode(BuildContext context, bool isSimple) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSimpleMode', isSimple);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => isSimple ? const SimpleHomeScreen() : const HomeScreen(),
      ),
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
              _buildModeButton(
                title: "Simple Mode",
                subtitle: "Fast scanning (Inventaire, Reception, Bon)",
                icon: Icons.qr_code_scanner,
                onTap: () => _selectMode(context, true),
              ),
              const SizedBox(height: 20),
              _buildModeButton(
                title: "Advanced Mode",
                subtitle: "Full database, prices, and suppliers",
                icon: Icons.storage,
                onTap: () => _selectMode(context, false),
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