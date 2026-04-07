// File: lib/screens/rfid_dashboard_screen.dart

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mode_selection_screen.dart';
import 'rfid_screen.dart';
import 'rfid_inventory_screen.dart';
import 'rfid_review_screen.dart';
import 'add_rfid_product_screen.dart'; // <-- NEW: Imported your registration screen

class RfidDashboardScreen extends StatefulWidget {
  const RfidDashboardScreen({super.key});

  @override
  State<RfidDashboardScreen> createState() => _RfidDashboardScreenState();
}

class _RfidDashboardScreenState extends State<RfidDashboardScreen> {
  // --- SECRET ADMIN MENU VARIABLES ---
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  final String _adminPin = "2026"; // <-- Your Kiosk Escape PIN

  @override
  void dispose() {
    _secretTapTimer?.cancel(); // Cancel secret Kiosk timer
    super.dispose();
  }

  // --- SECRET TAP LOGIC ---
  void _handleSecretTap() {
    _secretTapCount++;

    // Reset the counter if they stop tapping for more than 1 second
    _secretTapTimer?.cancel();
    _secretTapTimer = Timer(const Duration(milliseconds: 1000), () {
      _secretTapCount = 0;
    });

    // If they tap 7 times fast, trigger the PIN pad!
    if (_secretTapCount >= 7) {
      _secretTapCount = 0; // Reset
      _showAdminPinDialog();
    }
  }

  // --- THE ADMIN PIN DIALOG ---
  void _showAdminPinDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Force them to enter pin or cancel
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            "Developer Mode",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))
        ),
        content: TextField(
          controller: pinController,
          obscureText: true, // Hides the PIN as they type
          keyboardType: TextInputType.number,
          maxLength: 4, // Assuming a 4-digit PIN
          decoration: const InputDecoration(
            labelText: "Enter Admin PIN",
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (pinController.text == _adminPin) {
                // SUCCESS! Take the developer to the secret mode selection screen
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
                      (route) => false,
                );
              } else {
                // FAILURE! Wrong PIN.
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect PIN"), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Unlock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E0045), Color(0xFF4A00E0), Color(0xFF00B4DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- WRAPPED THE TITLE IN GESTURE DETECTOR ---
                      GestureDetector(
                        onTap: _handleSecretTap, // Hidden 7-tap trigger
                        child: Container(
                          color: Colors.transparent, // Ensures the whole area is tappable
                          child: Text(
                            "RFID Dashboard",
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        _buildGlassCard(
                          context: context,
                          title: "RFID Scanner",
                          icon: Icons.wifi_tethering,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RfidScreen()));
                          },
                        ),
                        _buildGlassCard(
                          context: context,
                          title: "RFID Inventory",
                          icon: CupertinoIcons.archivebox,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RfidInventoryScreen()));
                          },
                        ),
                        // --- NEW: Register Product Card ---
                        _buildGlassCard(
                          context: context,
                          title: "Register Product",
                          icon: CupertinoIcons.add_circled_solid,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRfidProductScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GLASSMORPHISM CARD WIDGET ---
  Widget _buildGlassCard({required BuildContext context, required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 52, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}