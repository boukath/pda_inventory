// File: lib/screens/enterprise_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_db_helper.dart';

class EnterpriseCatalogScreen extends StatefulWidget {
  const EnterpriseCatalogScreen({super.key});

  @override
  State<EnterpriseCatalogScreen> createState() => _EnterpriseCatalogScreenState();
}

class _EnterpriseCatalogScreenState extends State<EnterpriseCatalogScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _catalogItems = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final items = await AppDatabaseHelper.instance.getAllEnterpriseProducts();
    setState(() {
      _catalogItems = items;
      _isLoading = false;
    });
  }

  // --- THE DETAILED SLIDE-UP SHEET ---
  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    final bool isRetail = product['product_type'] == 'retail';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              // Header
              Center(
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(isRetail ? Icons.checkroom : Icons.local_grocery_store, size: 40, color: const Color(0xFF4A00E0)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['product_name'] ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(product['brand_name'] ?? 'No Brand', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Smart Detail List (Only shows fields that are NOT empty!)
              _buildSectionTitle("Hardware Link"),
              _buildDetailRow("EPC Chip", product['epc']),

              _buildSectionTitle("Core Details"),
              _buildDetailRow("SKU", product['sku']),
              _buildDetailRow("Barcode", product['barcode']),
              _buildDetailRow("Category", product['category']),
              _buildDetailRow("Sub-Category", product['sub_category']),
              _buildDetailRow("Description", product['description']),

              if (isRetail) ...[
                _buildSectionTitle("Apparel Specs"),
                _buildDetailRow("Size", product['size']),
                _buildDetailRow("Color", product['color']),
                _buildDetailRow("Gender", product['gender_dept']),
                _buildDetailRow("Season", product['season']),
                _buildDetailRow("Material", product['material']),
              ],

              if (!isRetail) ...[
                _buildSectionTitle("Grocery Specs"),
                _buildDetailRow("Batch/Lot", product['batch_lot']),
                _buildDetailRow("Production Date", product['production_date']),
                _buildDetailRow("Expiration Date", product['expiration_date']),
                _buildDetailRow("Weight/Volume", product['weight_volume']),
              ],

              _buildSectionTitle("Financials"),
              _buildDetailRow("Selling Price", "\$${product['selling_price']}"),
              _buildDetailRow("Cost Price", "\$${product['cost_price']}"),
              _buildDetailRow("Supplier ID", product['supplier_id']),

              _buildSectionTitle("Inventory Levels"),
              _buildDetailRow("In Stock", "${product['stock_quantity']}"),
              _buildDetailRow("Reorder Level", "${product['reorder_level']}"),
              _buildDetailRow("Location/Zone", "${product['store_location_id']} - ${product['zone_aisle']}"),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Enterprise Catalog", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : _catalogItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _catalogItems.length,
        itemBuilder: (context, index) {
          final item = _catalogItems[index];
          return _buildSummaryCard(item);
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.book, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Catalog is Empty", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          Text("Use 'Register Product' to add items.", style: GoogleFonts.poppins(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> product) {
    final bool isRetail = product['product_type'] == 'retail';
    final int stock = product['stock_quantity'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showProductDetails(context, product), // Opens the Bottom Sheet!
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1),
                radius: 28,
                child: Icon(isRetail ? Icons.checkroom : Icons.local_grocery_store, color: const Color(0xFF4A00E0)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['product_name'] ?? 'Unknown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(product['sku'] ?? 'No SKU', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          "EPC: ${product['epc'].toString().length > 10 ? product['epc'].toString().substring(0, 10) + '...' : product['epc']}",
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("\$${product['selling_price'] ?? '0.0'}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text("Stock: $stock", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: stock > 0 ? const Color(0xFF4A00E0) : Colors.red)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to draw section headers in the bottom sheet
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A00E0), letterSpacing: 1.2),
      ),
    );
  }

  // Helper widget to draw rows. It automatically hides if the data is empty!
  Widget _buildDetailRow(String label, dynamic value) {
    final valStr = value?.toString() ?? '';
    // If the string is empty, or it's a price that defaults to "$0.0", hide the row.
    if (valStr.isEmpty || valStr == "\$0.0") return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(valStr, style: GoogleFonts.poppins(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}