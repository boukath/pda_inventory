// File: lib/screens/rfid_screen.dart

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../l10n/app_localizations.dart';
import 'rfid_review_screen.dart';

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  State<RfidScreen> createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> with SingleTickerProviderStateMixin {
  static const EventChannel _rfidChannel = EventChannel('com.pda_inventory/rfid_events');

  // --- NEW: MethodChannel to talk TO the gun ---
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');

  StreamSubscription? _rfidSubscription;

  final Set<String> _uniquePhysicalTags = {};
  final Map<String, Product?> _productCache = {};
  final Map<String, int> _inventoryCounts = {};

  bool _isScanning = true; // Enabled by default

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _audioPlayer.setVolume(1.0);
    _startListeningToHardware();
  }

  void _startListeningToHardware() {
    _rfidSubscription = _rfidChannel.receiveBroadcastStream().listen((dynamic event) {
      if (!_isScanning) return;

      String scannedTag = event.toString().trim();
      if (scannedTag.isNotEmpty) {
        _processScannedTag(scannedTag);
      }
    }, onError: (dynamic error) {
      debugPrint('RFID Stream Error: ${error.message}');
    });
  }

  @override
  void dispose() {
    _rfidSubscription?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _processScannedTag(String tag) async {
    if (_uniquePhysicalTags.contains(tag)) return;

    _uniquePhysicalTags.add(tag);
    _inventoryCounts[tag] = (_inventoryCounts[tag] ?? 0) + 1;

    setState(() {});

    if (!_productCache.containsKey(tag)) {
      final product = await DatabaseHelper.instance.getProductByBarcode(tag);
      if (mounted) {
        setState(() {
          _productCache[tag] = product;
        });
      }
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _clearSession() {
    setState(() {
      _uniquePhysicalTags.clear();
      _inventoryCounts.clear();
      _productCache.clear();
      _isScanning = false;
    });
  }

  void _finishSession() {
    setState(() {
      _isScanning = false;
    });

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.sessionComplete, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("${AppLocalizations.of(context)!.scannedItems}: ${_uniquePhysicalTags.length}\n\n${AppLocalizations.of(context)!.readyToReview}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RfidReviewScreen(
                      scannedCounts: _inventoryCounts,
                      productCache: _productCache,
                    ),
                  ),
                ).then((_) => _clearSession());
              },
              child: Text(AppLocalizations.of(context)!.reviewItems, style: const TextStyle(color: Colors.white)),
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.rfidSweep, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // --- NEW: TEMPORARY TEST BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Manually trigger the inventory command on the gun
          _methodChannel.invokeMethod('startScan');
        },
        backgroundColor: Colors.orange,
        icon: const Icon(CupertinoIcons.bolt_fill, color: Colors.white),
        label: const Text("TEST SCAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Radar UI section remains unchanged
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF1E0045),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.scannedItems, style: GoogleFonts.poppins(color: Colors.white54, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text(
                  '${_uniquePhysicalTags.length}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, height: 1),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _toggleScanning,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 150 + (_pulseController.value * 50),
                              height: 150 + (_pulseController.value * 50),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(1.0 - _pulseController.value),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _isScanning ? Colors.greenAccent : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isScanning ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
                          color: const Color(0xFF1E0045),
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isScanning ? AppLocalizations.of(context)!.scanningActive : AppLocalizations.of(context)!.pressToStartScanning,
                  style: GoogleFonts.poppins(color: _isScanning ? Colors.greenAccent : Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventoryCounts.length,
              itemBuilder: (context, index) {
                String tag = _inventoryCounts.keys.elementAt(index);
                int count = _inventoryCounts[tag]!;
                Product? product = _productCache[tag];
                bool isUnknown = product == null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUnknown ? Colors.red.withOpacity(0.1) : const Color(0xFF4A00E0).withOpacity(0.1),
                      child: Icon(isUnknown ? CupertinoIcons.question : CupertinoIcons.tag_solid, color: isUnknown ? Colors.red : const Color(0xFF4A00E0)),
                    ),
                    title: Text(
                      isUnknown ? AppLocalizations.of(context)!.unknownTag : product.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tag, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    trailing: Text('x$count', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF4A00E0))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A00E0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _uniquePhysicalTags.isEmpty ? null : _finishSession,
          child: Text(AppLocalizations.of(context)!.finishAndReview, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}