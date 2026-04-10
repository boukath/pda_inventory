// File: lib/screens/geiger_counter_screen.dart

import 'dart:async';
import 'dart:math'; // <-- NEW: Required for the Pro Radar exponential curve!
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/product.dart';
import '../l10n/app_localizations.dart';

class GeigerCounterScreen extends StatefulWidget {
  final String targetEpc;
  final Product? targetProduct;

  const GeigerCounterScreen({
    super.key,
    required this.targetEpc,
    this.targetProduct,
  });

  @override
  State<GeigerCounterScreen> createState() => _GeigerCounterScreenState();
}

class _GeigerCounterScreenState extends State<GeigerCounterScreen> {
  static const EventChannel _rfidChannel = EventChannel('com.pda_inventory/rfid_events');
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');

  StreamSubscription? _rfidSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- AUDIO LOOP VARIABLES ---
  Timer? _pingTimer;
  int _currentIntervalMs = 1000;
  bool _isBeeping = false;

  bool _isScanning = false;
  double _signalPercentage = 0.0; // 0.0 (far) to 1.0 (close)

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);

    // 1. BOOT HARDWARE
    _methodChannel.invokeMethod('connectHardware');

    // 2. LISTEN CONSTANTLY FOR HARDWARE TRIGGER
    _startListeningToHardware();
  }

  void _startListeningToHardware() {
    _rfidSubscription = _rfidChannel.receiveBroadcastStream().listen((dynamic event) {
      String data = event.toString().trim();

      // --- PHYSICAL TRIGGER PULL DETECTED ---
      if (data == 'STATUS:START') {
        HapticFeedback.lightImpact();
        if (mounted) {
          setState(() => _isScanning = true);
          // Explicitly tell Android which tag to look for when trigger is pulled
          _methodChannel.invokeMethod('startLocator', {'targetEpc': widget.targetEpc});
        }
        return;
      }
      // --- PHYSICAL TRIGGER RELEASE DETECTED ---
      else if (data == 'STATUS:STOP') {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _signalPercentage = 0.0; // Reset visual
          });
        }
        _methodChannel.invokeMethod('stopLocator');
        return;
      }

      // --- TAG DATA RECEIVED ---
      // We don't want to process tags unless we are actually scanning
      if (_isScanning) {
        _processRfidEvent(data);
      }
    }, onError: (dynamic error) {
      debugPrint('RFID Stream Error: ${error.message}');
    });
  }

  @override
  void dispose() {
    _stopScanning();
    // PUT HARDWARE TO SLEEP
    _methodChannel.invokeMethod('disconnectHardware');

    _rfidSubscription?.cancel();
    _pingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleScanning() async {
    HapticFeedback.lightImpact(); // Instant feedback for software button
    if (_isScanning) {
      await _stopScanning();
    } else {
      await _startScanning();
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _signalPercentage = 0.0;
    });

    try {
      await _methodChannel.invokeMethod('startLocator', {'targetEpc': widget.targetEpc});
    } on PlatformException catch (e) {
      debugPrint("Error starting scanner: ${e.message}");
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScanning() async {
    _pingTimer?.cancel();
    _isBeeping = false;

    try {
      await _methodChannel.invokeMethod('stopLocator');
    } catch (e) {
      debugPrint("Error stopping scanner: $e");
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _signalPercentage = 0.0;
      });
    }
  }

  void _processRfidEvent(String eventData) {
    String epc = eventData;
    int rssi = -90;

    // Parse the incoming "EPC, RSSI" string sent from Kotlin
    if (eventData.contains(',')) {
      final parts = eventData.split(',');
      epc = parts[0].trim();
      rssi = int.tryParse(parts[1].trim()) ?? -90;
    }

    if (epc.toUpperCase() == widget.targetEpc.toUpperCase()) {
      _calculateSignalStrength(rssi);
    }
  }

  void _calculateSignalStrength(int rssi) {
    const int minRssi = -85; // Far away
    const int maxRssi = -35; // Very close

    int clampedRssi = rssi;
    if (clampedRssi < minRssi) clampedRssi = minRssi;
    if (clampedRssi > maxRssi) clampedRssi = maxRssi;

    double percentage = (clampedRssi - minRssi) / (maxRssi - minRssi);

    setState(() {
      _signalPercentage = percentage;
    });

    _updateAudioPing(percentage);
  }

  // --- UPGRADED: PRO RADAR EXPONENTIAL BEEP LOOP ---
  void _updateAudioPing(double percentage) {
    if (percentage <= 0.05 || !_isScanning) {
      _isBeeping = false;
      _pingTimer?.cancel();
      return;
    }

    // EXPONENTIAL CURVE:
    // Uses pow() to create a sharp drop in delay as you get closer.
    // 5%  = ~950ms (Slow ping)
    // 50% = ~300ms (Getting warmer)
    // 80% = ~100ms (Very close)
    // 95% = ~60ms  (Hyper fast stutter)
    _currentIntervalMs = (1000 * pow(1.0 - percentage, 2)).toInt() + 60;

    // If the loop isn't already running, start it up!
    if (!_isBeeping) {
      _startBeepLoop();
    }
  }

  void _startBeepLoop() {
    // Safety check to kill the loop if user stopped scanning or tag lost
    if (!_isScanning || _signalPercentage <= 0.05) {
      _isBeeping = false;
      return;
    }

    _isBeeping = true;

    // --- UPGRADED: USING NEW scanbeep.mp3 ---
    _audioPlayer.play(AssetSource('sounds/scanbeep.mp3')).catchError((e) {
      debugPrint("Audio error: $e");
    });

    // Schedule the next beep using our dynamically updating interval
    _pingTimer = Timer(Duration(milliseconds: _currentIntervalMs), () {
      _startBeepLoop();
    });
  }

  Color _getIndicatorColor() {
    if (_signalPercentage < 0.3) return Colors.red;
    if (_signalPercentage < 0.7) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.targetProduct?.name ?? AppLocalizations.of(context)?.unknownTag ?? "Item Locator";

    return Scaffold(
      appBar: AppBar(
        title: Text("Radar Mode", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A00E0).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4A00E0).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text("TARGET ACQUIRED", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF4A00E0))),
                  Text(widget.targetEpc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                    ),
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: 50 + (_signalPercentage * 250),
                    height: 50 + (_signalPercentage * 250),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getIndicatorColor().withOpacity(0.3),
                        border: Border.all(color: _getIndicatorColor(), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: _getIndicatorColor().withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5 * _signalPercentage,
                          )
                        ]
                    ),
                  ),

                  Icon(
                    CupertinoIcons.location_solid,
                    size: 40,
                    color: _isScanning ? _getIndicatorColor() : Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          Text(
            _isScanning
                ? "${(_signalPercentage * 100).toInt()}% Signal Strength"
                : "Scanner Inactive",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: InkWell(
              onTap: _toggleScanning,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                height: 80,
                decoration: BoxDecoration(
                  color: _isScanning ? Colors.redAccent : const Color(0xFF4A00E0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: (_isScanning ? Colors.redAccent : const Color(0xFF4A00E0)).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                  child: Text(
                    _isScanning ? "STOP SCANNING" : "PULL TRIGGER TO SCAN",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}