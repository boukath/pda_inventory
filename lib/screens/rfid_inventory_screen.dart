// File: lib/screens/rfid_inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class RfidInventoryScreen extends StatefulWidget {
  const RfidInventoryScreen({super.key});

  @override
  State<RfidInventoryScreen> createState() => _RfidInventoryScreenState();
}

class _RfidInventoryScreenState extends State<RfidInventoryScreen> {
  bool _isLoading = true;
  List<Product> _products = [];

  // Summary Counters
  int _totalItems = 0;
  int _totalStock = 0;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    // Fetch ALL products from the database
    final List<Product> products = await DatabaseHelper.instance.getProducts();

    int totalStock = 0;
    for (var p in products) {
      totalStock += p.stock;
    }

    setState(() {
      _products = products;
      _totalItems = products.length;
      _totalStock = totalStock;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Current Inventory', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : Column(
        children: [
          _buildDashboard(),
          Expanded(
            child: _products.isEmpty
                ? Center(
              child: Text(
                'No inventory found in database.',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildInventoryCard(_products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP DASHBOARD WIDGET ---
  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Items', _totalItems, const Color(0xFF4A00E0)),
          _buildStatColumn('Total Stock', _totalStock, Colors.green),
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
  Widget _buildInventoryCard(Product product) {
    // Change color based on whether the item is in stock or empty
    final bool hasStock = product.stock > 0;
    final Color cardColor = hasStock ? const Color(0xFF4A00E0) : Colors.red;
    final IconData icon = hasStock ? CupertinoIcons.cube_box_fill : CupertinoIcons.cube_box;

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
                  Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(product.barcode, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('In Stock', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(
                    '${product.stock}',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: cardColor)
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}