// File: lib/screens/home_screen.dart

import 'dart:ui';
import 'dart:async'; // <-- New import for Timers
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // <-- Used for Keyboard intercept
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../database/db_helper.dart'; // <-- Used for Database checks
import 'add_product_screen.dart';
import 'inventory_screen.dart';
import 'export_screen.dart';
import 'print_labels_screen.dart';
import 'mode_selection_screen.dart'; // <-- New import for Kiosk Escape

// 1. Changed to StatefulWidget to manage Focus and state
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 2. We use a FocusNode to secretly listen to the PDA scanner keystrokes
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  Timer? _scanTimer; // <-- Added for scanner debounce

  // --- 3. SECRET ADMIN MENU VARIABLES ---
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  final String _adminPin = "2026"; // <-- Your Kiosk Escape PIN

  @override
  void initState() {
    super.initState();
    // Ask for focus as soon as the screen loads so it's ready to scan!
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _scanTimer?.cancel(); // Cancel scanner timer
    _secretTapTimer?.cancel(); // Cancel secret Kiosk timer
    _focusNode.dispose();
    super.dispose();
  }

  // --- 4. SECRET TAP LOGIC ---
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

  // --- 5. THE ADMIN PIN DIALOG ---
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
              _focusNode.requestFocus(); // Give scanner focus back
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
                _focusNode.requestFocus();
              }
            },
            child: Text("Unlock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 6. This function processes the complete barcode after the scanner hits 'Enter'
  Future<void> _processScannedBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    // Check if the product exists in the database
    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      // Product EXISTS -> Go directly to Inventory and PASS THE BARCODE!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryScreen(initialBarcode: barcode),
        ),
      ).then((_) => _focusNode.requestFocus());
    } else {
      // Product DOES NOT EXIST -> Show suggestion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.productNotFound,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045)),
          ),
          content: Text(
            "This barcode ($barcode) is not in your system. Would you like to add it as a new product?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _focusNode.requestFocus();
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
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(initialBarcode: barcode),
                  ),
                ).then((_) => _focusNode.requestFocus());
              },
              child: Text(AppLocalizations.of(context)!.addProduct, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    // 7. Wrap the whole Scaffold in the modern Focus widget
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          _scanTimer?.cancel(); // Reset debounce timer

          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _processScannedBarcode(_barcodeBuffer.trim());
            _barcodeBuffer = ''; // Clear buffer for next scan
            return KeyEventResult.handled;
          } else if (event.character != null) {
            _barcodeBuffer += event.character!;
            // Start 150ms countdown to clear broken scans
            _scanTimer = Timer(const Duration(milliseconds: 150), () {
              _barcodeBuffer = '';
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Stack(
          children: [
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
                        // --- 8. WRAPPED THE TITLE IN GESTURE DETECTOR ---
                        GestureDetector(
                          onTap: _handleSecretTap, // Hidden 7-tap trigger
                          child: Container(
                            color: Colors.transparent, // Ensures the whole area is tappable
                            child: Text(
                              AppLocalizations.of(context)!.appTitle,
                              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                            ),
                          ),
                        ),
                        _buildLanguageButton(context),
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
                            title: AppLocalizations.of(context)!.addProduct,
                            icon: CupertinoIcons.add_circled,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen())).then((_) => _focusNode.requestFocus());
                            },
                          ),
                          _buildGlassCard(
                            context: context,
                            title: AppLocalizations.of(context)!.inventory,
                            icon: CupertinoIcons.cube_box,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())).then((_) => _focusNode.requestFocus());
                            },
                          ),
                          _buildGlassCard(
                            context: context,
                            title: AppLocalizations.of(context)!.exportCsv,
                            icon: CupertinoIcons.doc_text,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen())).then((_) => _focusNode.requestFocus());
                            },
                          ),
                          _buildGlassCard(
                            context: context,
                            title: AppLocalizations.of(context)!.printLabels,
                            icon: CupertinoIcons.printer,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintLabelsScreen())).then((_) => _focusNode.requestFocus());
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
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(CupertinoIcons.globe, color: Colors.white),
        color: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (String languageCode) {
          Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(languageCode, ''));
          _focusNode.requestFocus(); // Re-focus after interacting with menu
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildMenuItem('en', 'English'),
          _buildMenuItem('fr', 'Français'),
          _buildMenuItem('ar', 'العربية'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: const Color(0xFF4A00E0))),
    );
  }

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