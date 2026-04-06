// File: lib/screens/simple_orders_screen.dart
import 'dart:io'; // <-- Added for File creation
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart'; // <-- Added to save the CSV temporarily
import 'package:share_plus/share_plus.dart'; // <-- Added to share via WhatsApp/Email
import 'package:shared_preferences/shared_preferences.dart'; // <-- NEW: Added to save checkmarks permanently!

import '../database/simple_db_helper.dart';
import '../l10n/app_localizations.dart';

class SimpleOrdersScreen extends StatefulWidget {
  const SimpleOrdersScreen({super.key});

  @override
  State<SimpleOrdersScreen> createState() => _SimpleOrdersScreenState();
}

class _SimpleOrdersScreenState extends State<SimpleOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  SharedPreferences? _prefs; // <-- We will store the local memory instance here

  @override
  void initState() {
    super.initState();
    _initAndLoad(); // <-- Changed to initialize preferences first!
  }

  // --- NEW: Initialize SharedPreferences BEFORE loading the orders ---
  Future<void> _initAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    final data = await SimpleDatabaseHelper.instance.getOrdersWithItems();

    // Make data modifiable so we can track Checkbox state
    final List<Map<String, dynamic>> modifiableData = data.map((orderData) {
      final order = Map<String, dynamic>.from(orderData['order']);
      final orderId = order['id']; // Get the unique ID for this order

      final items = (orderData['items'] as List).map((item) {
        final modifiableItem = Map<String, dynamic>.from(item);
        final barcode = modifiableItem['barcode'];

        // --- NEW: Ask SharedPreferences if this specific barcode was checked in this specific order ---
        // If it doesn't exist yet, it defaults to false.
        final bool savedState = _prefs?.getBool('check_${orderId}_$barcode') ?? false;

        modifiableItem['isChecked'] = savedState;
        return modifiableItem;
      }).toList();

      return {
        'order': order,
        'items': items,
      };
    }).toList();

    setState(() {
      _orders = modifiableData;
    });
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // --- EXPORT AND SHARE METHOD ---
  Future<void> _exportAndShareCSV() async {
    if (_orders.isEmpty) return;

    final loc = AppLocalizations.of(context)!;

    // 1. Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.exporting), duration: const Duration(seconds: 1)),
    );

    try {
      // 2. Build the CSV Content
      StringBuffer csvData = StringBuffer();

      // Add Localized Headers: Barcode, Qty, Date
      csvData.writeln('"${loc.barcode}","${loc.qty}","${loc.date}"');

      // Loop through all orders and add rows
      for (var orderData in _orders) {
        final order = orderData['order'];
        final List<Map<String, dynamic>> items = orderData['items'];
        final String dateStr = _formatDate(order['timestamp']);

        for (var item in items) {
          csvData.writeln('"${item['barcode']}","${item['quantity']}","$dateStr"');
        }
      }

      // 3. Save to a temporary file on the device
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/orders_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData.toString());

      // 4. Open the Native Share Menu
      await Share.shareXFiles(
        [XFile(filePath)],
        text: loc.generateCsv,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background for contrast
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
        title: Text(loc.bon, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (_orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: loc.exportCsv,
              onPressed: _exportAndShareCSV,
            ),
        ],
      ),
      body: _orders.isEmpty
          ? Center(
        child: Text(
          loc.noOrdersFound,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final orderData = _orders[index];
          final orderMetadata = orderData['order'];
          final List<Map<String, dynamic>> items = orderData['items'];

          return _buildPremiumOrderCard(orderMetadata, items, loc);
        },
      ),
    );
  }

  Widget _buildPremiumOrderCard(Map<String, dynamic> order, List<Map<String, dynamic>> items, AppLocalizations loc) {
    // Check if ALL items in this specific order are checked off
    bool allChecked = items.isNotEmpty && items.every((item) => item['isChecked'] == true);

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        // Add a green border if the whole order is done
        side: BorderSide(color: allChecked ? Colors.green : Colors.transparent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // --- TOP HEADER (Date & Time) ---
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // Turn header Green if all checked, otherwise default purple/blue
                  colors: allChecked
                      ? [Colors.green.shade600, Colors.green.shade400]
                      : [const Color(0xFF4A00E0), const Color(0xFF00B4DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(allChecked ? Icons.check_circle : Icons.event_note, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(order['timestamp']),
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "#${order['id']}", // Order ID
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

            // --- PREMIUM TABLE (Barcode & Qty) ---
            Container(
              color: Colors.white,
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columnSpacing: 10, // Reduced spacing to fit the checkbox
                horizontalMargin: 12,
                columns: [
                  // New Checkbox Column header
                  const DataColumn(label: Text('')),
                  DataColumn(
                    label: Text(loc.barcode, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(loc.qty, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E0045))),
                  ),
                ],
                rows: items.map((item) {
                  final isChecked = item['isChecked'] ?? false;

                  return DataRow(
                    // Change row background color to very light green if checked
                    color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                      return isChecked ? Colors.green.withOpacity(0.1) : null;
                    }),
                    cells: [
                      // --- 1. THE CHECKBOX CELL ---
                      DataCell(
                        Checkbox(
                          value: isChecked,
                          activeColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (bool? value) {
                            final newValue = value ?? false;
                            setState(() {
                              item['isChecked'] = newValue;
                            });
                            // --- NEW: Save immediately to local device storage! ---
                            _prefs?.setBool('check_${order['id']}_${item['barcode']}', newValue);
                          },
                        ),
                      ),
                      // --- 2. THE BARCODE CELL ---
                      DataCell(
                        GestureDetector(
                          // Allow tapping the barcode itself to check/uncheck it easily
                          onTap: () {
                            final newValue = !isChecked;
                            setState(() {
                              item['isChecked'] = newValue;
                            });
                            // --- NEW: Save immediately to local device storage! ---
                            _prefs?.setBool('check_${order['id']}_${item['barcode']}', newValue);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: 16, color: isChecked ? Colors.green.shade600 : Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                  item['barcode'].toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: isChecked ? Colors.grey : Colors.black87,
                                    // Add a strikethrough line if it is checked!
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- 3. THE QUANTITY CELL ---
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isChecked ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                              "+ ${item['quantity']}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isChecked ? Colors.grey : Colors.green.shade800,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                              )
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}