// File: lib/screens/rfid_dashboard_screen.dart

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // <-- Needed for Method/Event Channels
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

import 'enterprise_catalog_screen.dart';
import 'mode_selection_screen.dart';
import 'rfid_screen.dart';
import 'rfid_inventory_screen.dart';
import 'rfid_review_screen.dart';
import 'add_rfid_product_screen.dart';

class RfidDashboardScreen extends StatefulWidget {
  const RfidDashboardScreen({super.key});

  @override
  State<RfidDashboardScreen> createState() => _RfidDashboardScreenState();
}

class _RfidDashboardScreenState extends State<RfidDashboardScreen> {
  // --- HARDWARE CHANNELS ---
  static const EventChannel _rfidChannel = EventChannel('com.pda_inventory/rfid_events');
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');
  StreamSubscription? _rfidSubscription;

  // --- HARDWARE STATE ---
  int? _batteryLevel;

  // --- SECRET ADMIN MENU VARIABLES ---
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  final String _adminPin = "2026";

  // --- NAVIGATION LOCK TO PREVENT DOUBLE TAPS ---
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupBatteryListener();
    _fetchBatteryLevel();
  }

  @override
  void dispose() {
    _rfidSubscription?.cancel();
    _secretTapTimer?.cancel();
    super.dispose();
  }

  // --- 1. LISTEN TO HARDWARE BATTERY UPDATES ---
  void _setupBatteryListener() {
    _rfidSubscription = _rfidChannel.receiveBroadcastStream().listen((dynamic event) {
      String data = event.toString().trim();

      // If Kotlin sends us a battery update, update the UI
      if (data.startsWith('BATTERY:')) {
        if (mounted) {
          setState(() {
            _batteryLevel = int.tryParse(data.replaceAll('BATTERY:', ''));
          });
        }
      }
    }, onError: (dynamic error) {
      debugPrint('RFID Stream Error: ${error.message}');
    });
  }

  // --- 2. ASK HARDWARE FOR INITIAL BATTERY ---
  Future<void> _fetchBatteryLevel() async {
    try {
      await _methodChannel.invokeMethod('getBattery');
    } catch (e) {
      debugPrint("Could not fetch battery: $e");
    }
  }

  // --- SAFE NAVIGATION HANDLER ---
  void _safeNavigate(Widget targetScreen) {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    Future.delayed(const Duration(milliseconds: 50), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      ).then((_) {
        // Fetch battery again when we come back to this screen!
        _fetchBatteryLevel();
        if (mounted) setState(() => _isNavigating = false);
      });
    });
  }

  // --- SECRET TAP LOGIC ---
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

  // --- THE ADMIN PIN DIALOG ---
  void _showAdminPinDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            AppLocalizations.of(context)!.developerMode,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))
        ),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.enterAdminPin,
            prefixIcon: const Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (pinController.text == _adminPin) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
                      (route) => false,
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.incorrectPin), backgroundColor: Colors.red),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.unlock, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                            AppLocalizations.of(context)!.appTitle,
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                          ),
                        ),
                      ),

                      // --- UPDATED TOP RIGHT CORNER: BATTERY & LANGUAGE ---
                      Row(
                        children: [
                          _buildBatteryIndicator(),
                          const SizedBox(width: 12),
                          _buildLanguageButton(context),
                        ],
                      )
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
                          title: AppLocalizations.of(context)!.rfidScanner,
                          icon: Icons.wifi_tethering,
                          onTap: () => _safeNavigate(const RfidScreen()),
                        ),
                        _buildGlassCard(
                          context: context,
                          title: AppLocalizations.of(context)!.rfidInventory,
                          icon: CupertinoIcons.archivebox,
                          onTap: () => _safeNavigate(const RfidInventoryScreen()),
                        ),
                        _buildGlassCard(
                          context: context,
                          title: AppLocalizations.of(context)!.registerTag,
                          icon: CupertinoIcons.add_circled_solid,
                          onTap: () => _safeNavigate(const AddRfidProductScreen()),
                        ),
                        _buildGlassCard(
                          context: context,
                          title: AppLocalizations.of(context)!.enterpriseCatalog,
                          icon: CupertinoIcons.book_solid,
                          onTap: () => _safeNavigate(const EnterpriseCatalogScreen()),
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

  // --- BATTERY INDICATOR WIDGET ---
  Widget _buildBatteryIndicator() {
    if (_batteryLevel == null) {
      return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)
      );
    }

    IconData icon;
    Color color;

    if (_batteryLevel! > 75) {
      icon = CupertinoIcons.battery_100;
      color = Colors.greenAccent;
    } else if (_batteryLevel! > 25) {
      icon = CupertinoIcons.battery_25;
      color = Colors.yellowAccent;
    } else {
      icon = CupertinoIcons.battery_0;
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            '$_batteryLevel%',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- LANGUAGE SWITCHER WIDGET ---
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

  // --- HIGH-PERFORMANCE GLASSMORPHISM CARD WIDGET ---
  Widget _buildGlassCard({required BuildContext context, required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withOpacity(0.4),
              highlightColor: Colors.white.withOpacity(0.2),
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
      ),
    );
  }
}