// File: lib/screens/simple_inventory_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/simple_db_helper.dart';
import '../l10n/app_localizations.dart';

class SimpleInventoryScreen extends StatefulWidget {
  const SimpleInventoryScreen({super.key});

  @override
  State<SimpleInventoryScreen> createState() => _SimpleInventoryScreenState();
}

class _SimpleInventoryScreenState extends State<SimpleInventoryScreen> {
  // --- SCANNER VARIABLES ---
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  Timer? _scanTimer;

  List<Map<String, dynamic>> _scannedItems = [];

  // --- NEW: THE MODE TOGGLE VARIABLE ---
  // true = Count Mode (+1 to DB), false = Check Mode (Read Only)
  bool _isCountMode = true;

  @override
  void initState() {
    super.initState();
    // Force focus immediately upon entering the screen
    _focusNode.requestFocus();
    _loadData();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await SimpleDatabaseHelper.instance.getScannedItems();
    setState(() {
      _scannedItems = data;
    });
  }

  // --- UPDATED: SCAN PROCESSOR ---
  Future<void> _processScannedBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    if (_isCountMode) {
      // MODE A: COUNT MODE (+1)
      final loc = AppLocalizations.of(context)!;

      await SimpleDatabaseHelper.instance.scanBarcode(barcode);
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${loc.scannedItem}$barcode", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.green.shade600, // Strong success color
        ),
      );

      _focusNode.requestFocus();

    } else {
      // MODE B: CHECK MODE (READ ONLY)
      // Look for the item in our current memory list
      final existingItemIndex = _scannedItems.indexWhere((item) => item['barcode'].toString() == barcode);

      int currentQty = 0;
      if (existingItemIndex != -1) {
        currentQty = _scannedItems[existingItemIndex]['quantity'] as int;
      }

      if (!mounted) return;

      // Show the massive check dialog
      _showCheckModeDialog(barcode, currentQty);
    }
  }

  // --- NEW: CHECK MODE DIALOG ---
  // A large, highly visible popup for checking items without modifying the database.
  void _showCheckModeDialog(String barcode, int currentQty) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.orange.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.orange.shade700, width: 4),
            ),
            title: Center(
              child: Text("INFO CHECK", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: Colors.orange.shade900, fontSize: 24)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 60, color: Colors.orange),
                const SizedBox(height: 16),
                Text(barcode, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Text("Scanned Quantity", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                      Text(
                          currentQty.toString(),
                          style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: currentQty == 0 ? Colors.red : Colors.green)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _focusNode.requestFocus(); // Give scanner focus back!
                  },
                  child: Text("OK", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              ),
            ],
          );
        }
    ).then((_) => _focusNode.requestFocus());
  }

  // --- EDIT QUANTITY DIALOG ---
  Future<void> _showEditQuantityDialog(String barcode, int currentQty) async {
    final TextEditingController qtyController = TextEditingController(text: currentQty.toString());
    final loc = AppLocalizations.of(context)!;

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Edit Quantity", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
            content: TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "New Quantity (0 to delete)",
                prefixIcon: const Icon(Icons.edit, color: Color(0xFF4A00E0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0), foregroundColor: Colors.white),
                onPressed: () async {
                  int? newQty = int.tryParse(qtyController.text);
                  if (newQty != null) {
                    await SimpleDatabaseHelper.instance.updateQuantity(barcode, newQty);
                    await _loadData();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(loc.save, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );

    _focusNode.requestFocus();
  }

  // --- UPDATED: THE GIANT TOGGLE WIDGET ---
  Widget _buildGiantToggle() {
    // 1. Get the localizations!
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // COUNT MODE BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isCountMode = true);
                _focusNode.requestFocus();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: _isCountMode ? const Color(0xFF4A00E0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: _isCountMode
                      ? [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    loc.toggleCount, // <-- CHANGED HERE
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isCountMode ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // CHECK MODE BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isCountMode = false);
                _focusNode.requestFocus();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: !_isCountMode ? Colors.orange.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: !_isCountMode
                      ? [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    loc.toggleCheck, // <-- CHANGED HERE
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: !_isCountMode ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // The current active color theme for the app bar
    final Color activeThemeColor = _isCountMode ? const Color(0xFF4A00E0) : Colors.orange.shade700;

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
      child: GestureDetector(
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.inventory, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            // Animate the app bar color so the user knows immediately what mode they are in
            backgroundColor: activeThemeColor,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // 1. Render the new Toggle UI at the top
              _buildGiantToggle(),

              // 2. Render the List View (or empty state)
              Expanded(
                child: _scannedItems.isEmpty
                    ? Center(
                  child: Text(
                      loc.readyToScan,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)
                  ),
                )
                    : ListView.builder(
                  itemCount: _scannedItems.length,
                  itemBuilder: (context, index) {
                    final item = _scannedItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.qr_code, color: activeThemeColor),
                        title: Text(item['barcode'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        trailing: InkWell(
                          onTap: () => _showEditQuantityDialog(item['barcode'].toString(), item['quantity'] as int),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                                color: activeThemeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: activeThemeColor.withOpacity(0.3))
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("x ${item['quantity']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: activeThemeColor)),
                                const SizedBox(width: 8),
                                Icon(Icons.edit, size: 16, color: activeThemeColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}