// File: lib/screens/simple_reception_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/simple_db_helper.dart';
import '../l10n/app_localizations.dart';

class SimpleReceptionScreen extends StatefulWidget {
  const SimpleReceptionScreen({super.key});

  @override
  State<SimpleReceptionScreen> createState() => _SimpleReceptionScreenState();
}

class _SimpleReceptionScreenState extends State<SimpleReceptionScreen> {
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  Timer? _scanTimer;

  List<Map<String, dynamic>> _receivedItems = [];

  // UX Trick: We keep the last entered supplier name in memory
  // so the user doesn't have to type it 100 times for the same delivery!
  String _lastSupplierName = '';

  @override
  void initState() {
    super.initState();
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
    final data = await SimpleDatabaseHelper.instance.getReceptionHistory();
    setState(() {
      _receivedItems = data;
    });
  }

  // Triggered when the PDA scanner reads a barcode
  void _processScannedBarcode(String barcode) {
    if (barcode.isEmpty) return;
    _showReceiveDialog(barcode);
  }

  // --- NEW: MANUAL BARCODE ENTRY DIALOG ---
  // Useful if the PDA scanner fails to read a damaged barcode
  void _showManualBarcodeDialog() {
    final manualController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            "Manual Entry",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))
        ),
        content: TextField(
          controller: manualController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: loc.barcode,
            prefixIcon: const Icon(Icons.keyboard),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _focusNode.requestFocus();
            },
            child: Text(loc.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final barcode = manualController.text.trim();
              Navigator.pop(context);
              if (barcode.isNotEmpty) {
                _processScannedBarcode(barcode);
              } else {
                _focusNode.requestFocus();
              }
            },
            child: Text(loc.save, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // The dialog where the user enters the details
  void _showReceiveDialog(String barcode) {
    final quantityController = TextEditingController(text: "1");
    // Pre-fill the comment with the last known supplier to save typing time
    final commentController = TextEditingController(text: _lastSupplierName);

    // Call localizations for the dialog
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false, // Force them to finish the action
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            loc.receiveProductTitle, // <-- Localized
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${loc.barcode}: $barcode", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), // <-- Localized
              const SizedBox(height: 16),
              // Quantity Field
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.quantityReceived, // <-- Localized
                  prefixIcon: const Icon(Icons.add_box_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Comment / Supplier Field
              TextField(
                controller: commentController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: loc.supplierComment, // <-- Localized
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _focusNode.requestFocus(); // Re-focus scanner
              },
              child: Text(loc.cancel, style: GoogleFonts.poppins(color: Colors.grey)), // <-- Localized
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A00E0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final qty = int.tryParse(quantityController.text) ?? 1;
                final comment = commentController.text.trim();

                // Save the supplier name in memory for the next scan
                _lastSupplierName = comment;

                // Save to database
                await SimpleDatabaseHelper.instance.saveReceptionLog(barcode, qty, comment);

                if (mounted) {
                  Navigator.pop(context);
                  _loadData(); // Refresh list
                  _focusNode.requestFocus(); // Ready for next scan!
                }
              },
              child: Text(loc.save, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), // <-- Localized
            ),
          ],
        );
      },
    );
  }

  // Helper to format the ISO date into a readable string
  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Call localizations for the main screen
    final loc = AppLocalizations.of(context)!;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
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
      // --- NEW: GESTURE DETECTOR WRAPPER ---
      // This ensures tapping anywhere regains scanner focus
      child: GestureDetector(
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E0045),
            foregroundColor: Colors.white,
            title: Text(loc.receivingLogTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), // <-- Localized
          ),
          body: Container(
            color: const Color(0xFFF5F7FA), // Light background for contrast
            child: _receivedItems.isEmpty
                ? Center(
              child: Text(
                loc.readyToReceiveHint, // <-- Localized
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _receivedItems.length,
              itemBuilder: (context, index) {
                final item = _receivedItems[index];

                // Handle empty supplier names safely
                final String comment = item['comment'] ?? '';
                final String displaySupplier = comment.isNotEmpty ? comment : loc.supplierNone;

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1),
                      child: const Icon(Icons.inventory_2, color: Color(0xFF4A00E0)),
                    ),
                    title: Text(item['barcode'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // <-- Localized Supplier Prefix and Name
                        Text("${loc.supplierPrefix}$displaySupplier", style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                        Text(_formatDate(item['timestamp'].toString()), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        "+ ${item['quantity']}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // --- NEW: SCAN FLOATING ACTION BUTTON ---
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF4A00E0),
            foregroundColor: Colors.white,
            elevation: 8,
            onPressed: () {
              // Open manual entry if physical button doesn't work
              _showManualBarcodeDialog();
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
        ),
      ),
    );
  }
}