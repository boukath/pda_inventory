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
import '../database/app_db_helper.dart';

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  State<RfidScreen> createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> with SingleTickerProviderStateMixin {
  static const EventChannel _rfidChannel = EventChannel('com.pda_inventory/rfid_events');
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');

  StreamSubscription? _rfidSubscription;

  final Set<String> _uniquePhysicalTags = {};
  final Map<String, Product?> _productCache = {};
  final Map<String, int> _inventoryCounts = {};

  bool _isScanning = false;

  // --- NEW: Hardware Warmup State ---
  bool _isHardwareReady = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  // --- NEW: Audio Silence Detector Variables ---
  Timer? _tagTimeoutTimer;
  bool _isAudioPlaying = false;

  // --- PREMIUM FEATURE: Hardware Power Tracking ---
  double _currentPower = 30.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _audioPlayer.setVolume(1.0);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // 1. DELAY HARDWARE BOOT COMMANDS (To keep UI smooth)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _methodChannel.invokeMethod('connectHardware');
        _methodChannel.invokeMethod('setLocatorTarget', {'targetEpc': null});
        _startListeningToHardware();
      }
    });

    // 2. HARDWARE WARM-UP TIMER
    // The physical radio takes ~1-1.5 seconds to fully power on and sync.
    // We lock the UI during this time so the user knows to wait a brief moment!
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isHardwareReady = true;
        });
      }
    });
  }

  void _startListeningToHardware() {
    _rfidSubscription = _rfidChannel.receiveBroadcastStream().listen((dynamic event) {
      String data = event.toString().trim();

      if (data == 'STATUS:START') {
        HapticFeedback.lightImpact();
        if (mounted) setState(() => _isScanning = true);
        return;
      } else if (data == 'STATUS:STOP') {
        _stopAudioLoop();
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      if (data.startsWith('TAG:')) {
        if (!_isScanning) {
          if (mounted) setState(() => _isScanning = true);
        }

        if (!_isAudioPlaying) {
          _audioPlayer.play(AssetSource('sounds/beep.mp3'));
          _isAudioPlaying = true;
        }

        _tagTimeoutTimer?.cancel();
        _tagTimeoutTimer = Timer(const Duration(milliseconds: 250), () {
          _stopAudioLoop();
        });

        String scannedTag = data.replaceAll('TAG:', '');
        if (scannedTag.isNotEmpty) {
          _processScannedTag(scannedTag);
        }
      }
    }, onError: (dynamic error) {
      debugPrint('RFID Stream Error: ${error.message}');
    });
  }

  void _stopAudioLoop() {
    _tagTimeoutTimer?.cancel();
    if (_isAudioPlaying) {
      _audioPlayer.pause();
      _isAudioPlaying = false;
    }
  }

  @override
  void dispose() {
    _methodChannel.invokeMethod('disconnectHardware');
    _rfidSubscription?.cancel();
    _pulseController.dispose();
    _stopAudioLoop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _processScannedTag(String tag) {
    if (_uniquePhysicalTags.contains(tag)) return;

    setState(() {
      _uniquePhysicalTags.add(tag);
      _inventoryCounts[tag] = (_inventoryCounts[tag] ?? 0) + 1;
    });

    if (!_productCache.containsKey(tag)) {
      AppDatabaseHelper.instance.getEnterpriseProductByEpc(tag).then((enterpriseData) {
        if (enterpriseData != null) {
          final product = Product(
            barcode: enterpriseData['epc'] ?? tag,
            name: enterpriseData['product_name'] ?? 'Unknown',
            price: (enterpriseData['selling_price'] ?? 0).toDouble(),
            costPrice: (enterpriseData['cost_price'] ?? 0).toDouble(),
            category: enterpriseData['category'] ?? '',
            stock: enterpriseData['stock_quantity'] ?? 0,
            lastUpdated: enterpriseData['date_added'] ?? DateTime.now().toIso8601String(),
          );
          if (mounted) setState(() => _productCache[tag] = product);
        } else {
          DatabaseHelper.instance.getProductByBarcode(tag).then((product) {
            if (mounted) {
              setState(() {
                _productCache[tag] = product;
              });
            }
          });
        }
      });
    }
  }

  void _toggleScanning() {
    // Prevent software scanning if the hardware is still warming up
    if (!_isHardwareReady) return;

    HapticFeedback.lightImpact();
    if (_isScanning) {
      _methodChannel.invokeMethod('stopScan');
      _stopAudioLoop();
      setState(() => _isScanning = false);
    } else {
      _methodChannel.invokeMethod('startScan');
      setState(() => _isScanning = true);
    }
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
    _methodChannel.invokeMethod('stopScan');
    _stopAudioLoop();

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
                      scannedEpcs: _uniquePhysicalTags.toList(),
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

  void _showPremiumPowerSlider() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setSheetState) {
              // --- FIXED: Wrapped in ClipRRect to safely constrain the blur effect
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 50),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.4))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "Scanner Range",
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                            ),
                            Text(
                                "${_currentPower.toInt()} dBm",
                                style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF4A00E0), fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            "Slide to adjust physical read distance. Lower power helps find single items, max power reads through walls.",
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13, height: 1.4)
                        ),
                        const SizedBox(height: 32),

                        LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              const double minPower = 5.0;
                              const double maxPower = 30.0;
                              const double range = maxPower - minPower;

                              final double percent = (_currentPower - minPower) / range;

                              return GestureDetector(
                                // --- FIXED: Changed to onHorizontalDragUpdate ---
                                onHorizontalDragUpdate: (details) {
                                  double deltaPercent = details.primaryDelta! / width;
                                  double newPercent = (percent + deltaPercent).clamp(0.0, 1.0);
                                  double newPower = minPower + (newPercent * range);

                                  if (newPower.toInt() != _currentPower.toInt()) {
                                    HapticFeedback.lightImpact();
                                  }

                                  setSheetState(() => _currentPower = newPower);
                                  setState(() => _currentPower = newPower);
                                },
                                onPanEnd: (details) {
                                  _methodChannel.invokeMethod('setTxPower', {"power": _currentPower.toInt()});
                                  HapticFeedback.mediumImpact();
                                },
                                child: Container(
                                  height: 75,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 50),
                                        // --- FIXED: Changed lower clamp to 0.0 to prevent layout bounds error
                                        width: (width * percent).clamp(0.0, width),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [Color(0xFF6A11CB), Color(0xFF4A00E0)]
                                          ),
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            CupertinoIcons.antenna_radiowaves_left_right,
                                            color: percent > 0.15 ? Colors.white : Colors.grey[600],
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
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
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.white, size: 28),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showPremiumPowerSlider();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                                  // --- FIXED: Clamped value to prevent negative opacity crashes ---
                                  color: Colors.greenAccent.withOpacity((1.0 - _pulseController.value).clamp(0.0, 1.0)),
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
                          // --- NEW: Hardware visual feedback colors ---
                          color: !_isHardwareReady
                              ? Colors.grey.shade400
                              : (_isScanning ? Colors.greenAccent : Colors.redAccent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          // --- NEW: Hardware visual feedback icons ---
                          !_isHardwareReady
                              ? CupertinoIcons.hourglass
                              : (_isScanning ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid),
                          color: const Color(0xFF1E0045),
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // --- NEW: Dynamic Warm-Up Text ---
                Text(
                  !_isHardwareReady
                      ? "Warming up scanner..."
                      : (_isScanning ? AppLocalizations.of(context)!.scanningActive : AppLocalizations.of(context)!.pressToStartScanning),
                  style: GoogleFonts.poppins(
                      color: !_isHardwareReady
                          ? Colors.amber
                          : (_isScanning ? Colors.greenAccent : Colors.white70),
                      fontWeight: FontWeight.w600
                  ),
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
        decoration: const BoxDecoration(color: Colors.white),
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