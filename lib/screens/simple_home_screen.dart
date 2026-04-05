// File: lib/screens/simple_home_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // <-- Needed to intercept hardware scanner keys!
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../database/simple_db_helper.dart'; // <-- Needed to save scans from the dashboard
import 'simple_inventory_screen.dart';
import 'mode_selection_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  // --- 1. SCANNER VARIABLES ---
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  Timer? _scanTimer;

  // --- SECRET ADMIN MENU VARIABLES ---
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  final String _adminPin = "2026";

  @override
  void initState() {
    super.initState();
    // Ask for focus as soon as the menu loads so the PDA trigger works instantly
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _secretTapTimer?.cancel();
    _focusNode.dispose(); // Don't forget to dispose the focus node!
    super.dispose();
  }

  // --- 2. BACKGROUND SCANNER LOGIC ---
  Future<void> _processScannedBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    // Save the scan instantly to the simple inventory database
    await SimpleDatabaseHelper.instance.scanBarcode(barcode);

    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;

    // Show a quick success message so the user knows it worked
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${loc.scannedItem}$barcode"),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  // --- SECRET MENU LOGIC ---
  void _handleSecretTap() {
    _secretTapCount++;
    _secretTapTimer?.cancel();
    _secretTapTimer = Timer(const Duration(milliseconds: 1000), () {
      _secretTapCount = 0;
    });

    if (_secretTapCount >= 7) {
      _secretTapCount = 0;
      _showAdminPinDialog();
    }
  }

  void _showAdminPinDialog() {
    final TextEditingController pinController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.developerMode, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(labelText: loc.enterAdminPin, prefixIcon: const Icon(Icons.lock)),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _focusNode.requestFocus(); // Give focus back to the scanner if they cancel!
              },
              child: Text(loc.cancel, style: GoogleFonts.poppins(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (pinController.text == _adminPin) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
                      (route) => false,
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(loc.incorrectPin),
                    backgroundColor: Colors.red
                ));
                _focusNode.requestFocus(); // Give focus back to the scanner!
              }
            },
            child: Text(loc.unlock, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    // --- 3. WRAP SCAFFOLD IN FOCUS WIDGET ---
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          _scanTimer?.cancel();
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _processScannedBarcode(_barcodeBuffer.trim());
            _barcodeBuffer = '';
            return KeyEventResult.handled;
          } else if (event.character != null) {
            _barcodeBuffer += event.character!;
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
                        GestureDetector(
                          onTap: _handleSecretTap,
                          child: Container(
                            color: Colors.transparent,
                            child: Text(
                                loc.simpleMenuTitle,
                                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0)
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
                            title: loc.inventory,
                            icon: CupertinoIcons.cube_box,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SimpleInventoryScreen())
                              ).then((_) => _focusNode.requestFocus()); // <-- 4. Re-request focus when returning from screen!
                            },
                          ),
                          _buildGlassCard(
                            context: context,
                            title: loc.reception,
                            icon: CupertinoIcons.tray_arrow_down,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.comingSoon)));
                              _focusNode.requestFocus(); // Re-request focus after tapping
                            },
                          ),
                          _buildGlassCard(
                            context: context,
                            title: loc.bon,
                            icon: CupertinoIcons.doc_text,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.comingSoon)));
                              _focusNode.requestFocus(); // Re-request focus after tapping
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

  // --- UI WIDGETS ---

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
          _focusNode.requestFocus(); // Re-request focus after closing the menu
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
}