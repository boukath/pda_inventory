// File: lib/screens/rfid_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart'; // <-- New Audio Player
import '../database/db_helper.dart';
import '../models/product.dart';

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  State<RfidScreen> createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  String _rfidBuffer = '';

  final Set<String> _uniquePhysicalTags = {};
  final Map<String, Product?> _productCache = {};
  final Map<String, int> _inventoryCounts = {};

  bool _isScanning = false; // Start paused so they can prepare

  // Audio & Animation for the "Zara" feel
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Setup the radar pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false); // Loops continuously

    // We will use a default system beep, but later you can add a custom asset!
    _audioPlayer.setVolume(1.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- THE SCANNING ENGINE ---
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isScanning) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_rfidBuffer.isNotEmpty) {
          _processScannedTag(_rfidBuffer.trim());
          _rfidBuffer = '';
        }
        return KeyEventResult.handled;
      } else if (event.character != null) {
        _rfidBuffer += event.character!;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _processScannedTag(String tag) async {
    // If we already saw this exact physical tag, do nothing (ignore duplicates)
    if (_uniquePhysicalTags.contains(tag)) return;

    // --- NEW TAG FOUND! ---
    _uniquePhysicalTags.add(tag);
    _inventoryCounts[tag] = (_inventoryCounts[tag] ?? 0) + 1;

    // Play a short, satisfying "beep" for every new item
    // Note: We use play with AssetSource if you have a sound file,
    // or you can rely on the PDA's native hardware beep.
    // If the PDA makes a sound automatically, we can remove this line.
    // _audioPlayer.play(AssetSource('beep.mp3'));

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
    if (_isScanning) {
      _focusNode.requestFocus();
    }
  }

  void _finishSession() {
    // Step 3: This will eventually go to the "Review & Commit" screen
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Session Complete", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("You scanned ${_uniquePhysicalTags.length} unique items. Ready to review and save to the database?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _focusNode.requestFocus();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0)),
              onPressed: () {
                // TODO: Navigate to the Review Screen (We will build this next!)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review Screen Coming Soon!"))
                );
              },
              child: const Text("Review Items", style: TextStyle(color: Colors.white)),
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
        title: Text('RFID Sweep', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: Column(
          children: [
            // --- THE ZARA RADAR UI ---
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
                  Text('SCANNED ITEMS', style: GoogleFonts.poppins(color: Colors.white54, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text(
                    '${_uniquePhysicalTags.length}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, height: 1),
                  ),
                  const SizedBox(height: 30),

                  // The Interactive Radar Button
                  GestureDetector(
                    onTap: _toggleScanning,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Pulse Effect
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
                        // Main Play/Pause Button
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              color: _isScanning ? Colors.greenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isScanning ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ]
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
                    _isScanning ? 'SCANNING ACTIVE... WALK AISLE' : 'PRESS TO START SCANNING',
                    style: GoogleFonts.poppins(color: _isScanning ? Colors.greenAccent : Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // --- LIST OF ITEMS ---
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
                        isUnknown ? 'Unknown Tag' : product.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045)),
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
      ),

      // --- BOTTOM ACTION BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A00E0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _uniquePhysicalTags.isEmpty ? null : _finishSession,
          child: Text(
            'FINISH & REVIEW',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}