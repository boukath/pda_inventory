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

  Future<void> _processScannedBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    final loc = AppLocalizations.of(context)!;

    // Save to local SQLite
    await SimpleDatabaseHelper.instance.scanBarcode(barcode);
    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${loc.scannedItem}$barcode", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.green,
      ),
    );

    // Re-request focus just in case the SnackBar stole it!
    _focusNode.requestFocus();
  }

  // --- NEW: EDIT QUANTITY DIALOG ---
  Future<void> _showEditQuantityDialog(String barcode, int currentQty) async {
    final TextEditingController qtyController = TextEditingController(text: currentQty.toString());
    final loc = AppLocalizations.of(context)!;

    await showDialog(
        context: context,
        barrierDismissible: false, // Force them to press save or cancel
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Edit Quantity", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
            content: TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              // Force keyboard to only accept numbers
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
                  // Parse the new number they typed
                  int? newQty = int.tryParse(qtyController.text);
                  if (newQty != null) {
                    // Call our new database method
                    await SimpleDatabaseHelper.instance.updateQuantity(barcode, newQty);
                    await _loadData(); // Refresh the screen
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                    }
                  }
                },
                child: Text(loc.save, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );

    // IMPORTANT: Re-request focus after dialog closes so the scanner works again!
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
      // THE PDA KEEPALIVE WRAPPER
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
            backgroundColor: const Color(0xFF4A00E0),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: _scannedItems.isEmpty
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
                  leading: const Icon(Icons.qr_code, color: Color(0xFF4A00E0)),
                  title: Text(item['barcode'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  // --- NEW: TAPPABLE QUANTITY BADGE ---
                  trailing: InkWell(
                    onTap: () => _showEditQuantityDialog(item['barcode'].toString(), item['quantity'] as int),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF4A00E0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4A00E0).withOpacity(0.3))
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("x ${item['quantity']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF4A00E0))),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 16, color: Color(0xFF4A00E0)), // Visual cue that it's editable!
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}