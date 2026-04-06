// File: lib/screens/rfid_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

// A simple class to hold our comparison logic
class ReviewItem {
  final String barcode;
  final String name;
  final int expectedQty;
  final int scannedQty;
  final Product? productRef;

  ReviewItem({
    required this.barcode,
    required this.name,
    required this.expectedQty,
    required this.scannedQty,
    this.productRef,
  });

  // Determine the status of the item
  String get status {
    if (productRef == null) return 'unknown';
    if (expectedQty == scannedQty) return 'match';
    if (scannedQty < expectedQty) return 'missing';
    return 'overstock'; // scannedQty > expectedQty
  }

  int get variance => scannedQty - expectedQty;
}

class RfidReviewScreen extends StatefulWidget {
  final Map<String, int> scannedCounts;
  final Map<String, Product?> productCache;

  const RfidReviewScreen({
    super.key,
    required this.scannedCounts,
    required this.productCache,
  });

  @override
  State<RfidReviewScreen> createState() => _RfidReviewScreenState();
}

class _RfidReviewScreenState extends State<RfidReviewScreen> {
  bool _isLoading = true;
  List<ReviewItem> _reviewItems = [];

  // Summary Counters
  int _totalMatched = 0;
  int _totalMissing = 0;
  int _totalOverstock = 0;
  int _totalUnknown = 0;

  @override
  void initState() {
    super.initState();
    _reconcileInventory();
  }

  Future<void> _reconcileInventory() async {
    // 1. Fetch ALL products from the database to see what we *should* have
    final List<Product> allDbProducts = await DatabaseHelper.instance.getProducts();

    // Convert to a Map for extremely fast lookups
    final Map<String, Product> dbMap = {
      for (var p in allDbProducts) p.barcode: p
    };

    List<ReviewItem> items = [];

    // 2. Loop through everything we actually scanned
    widget.scannedCounts.forEach((barcode, scannedQty) {
      if (dbMap.containsKey(barcode)) {
        // We know this product!
        final product = dbMap[barcode]!;
        items.add(ReviewItem(
          barcode: barcode,
          name: product.name,
          expectedQty: product.stock, // <-- Changed to 'stock'
          scannedQty: scannedQty,
          productRef: product,
        ));
        // Remove it from the map so we know what's left over
        dbMap.remove(barcode);
      } else {
        // Unknown product not in DB
        items.add(ReviewItem(
          barcode: barcode,
          name: 'Unknown Tag',
          expectedQty: 0,
          scannedQty: scannedQty,
          productRef: null,
        ));
      }
    });

    // 3. Anything left in dbMap was NEVER SCANNED! (100% missing)
    // Note: In a real app with 10,000 items, you might only want to do this
    // for products assigned to the specific "Zone" the user was scanning.
    dbMap.forEach((barcode, product) {
      if (product.stock > 0) { // <-- Changed to 'stock'
        items.add(ReviewItem(
          barcode: barcode,
          name: product.name,
          expectedQty: product.stock, // <-- Changed to 'stock'
          scannedQty: 0, // We found zero!
          productRef: product,
        ));
      }
    });

    // 4. Calculate Summary Dashboard Numbers
    for (var item in items) {
      if (item.status == 'match') _totalMatched++;
      else if (item.status == 'missing') _totalMissing++;
      else if (item.status == 'overstock') _totalOverstock++;
      else if (item.status == 'unknown') _totalUnknown++;
    }

    // Sort items so Missing and Overstock appear at the top (they need attention!)
    items.sort((a, b) {
      if (a.status == 'missing' && b.status != 'missing') return -1;
      if (b.status == 'missing' && a.status != 'missing') return 1;
      return 0;
    });

    setState(() {
      _reviewItems = items;
      _isLoading = false;
    });
  }

  // --- THE COMMIT FUNCTION ---
  Future<void> _commitToDatabase() async {
    setState(() => _isLoading = true);

    // Update the database for all known items
    for (var item in _reviewItems) {
      if (item.productRef != null && item.variance != 0) {
        // The quantity changed, let's update it in the database
        Product updatedProduct = item.productRef!.copyWith(
          stock: item.scannedQty, // <-- Changed to 'stock' to match your model
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);
      }
    }

    if (!mounted) return;

    // Show success and pop back to home
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inventory Successfully Updated!"),
          backgroundColor: Colors.green,
        )
    );
    Navigator.popUntil(context, (route) => route.isFirst); // Go all the way to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Reconciliation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : Column(
        children: [
          _buildDashboard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviewItems.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(_reviewItems[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: Text(
              'COMMIT INVENTORY',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
            ),
            onPressed: _isLoading ? null : _commitToDatabase,
          ),
        ),
      ),
    );
  }

  // --- TOP DASHBOARD WIDGET ---
  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Match', _totalMatched, Colors.green),
          _buildStatColumn('Missing', _totalMissing, Colors.red),
          _buildStatColumn('Overstock', _totalOverstock, Colors.orange),
          _buildStatColumn('Unknown', _totalUnknown, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- INDIVIDUAL ITEM CARD WIDGET ---
  Widget _buildReviewCard(ReviewItem item) {
    Color cardColor;
    IconData icon;

    switch (item.status) {
      case 'match':
        cardColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'missing':
        cardColor = Colors.red;
        icon = Icons.error;
        break;
      case 'overstock':
        cardColor = Colors.orange;
        icon = Icons.add_circle;
        break;
      default: // unknown
        cardColor = Colors.grey;
        icon = CupertinoIcons.question_circle_fill;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardColor.withOpacity(0.3), width: 1)
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: cardColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(item.barcode, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Expected: ${item.expectedQty}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(
                    'Found: ${item.scannedQty}',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: cardColor)
                ),
                if (item.variance != 0 && item.status != 'unknown')
                  Text(
                      '${item.variance > 0 ? '+' : ''}${item.variance}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: cardColor)
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}