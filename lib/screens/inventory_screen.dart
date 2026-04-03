import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _newStockController = TextEditingController();

  Product? _scannedProduct;

  // New lists to hold our database data
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAllProducts(); // Fetch everything when screen opens
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newStockController.dispose();
    super.dispose();
  }

  // --- 1. Fetch all products from Database ---
  Future<void> _loadAllProducts() async {
    final products = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products; // Initially, show everything
    });
  }

  // --- 2. Live filter as the user types ---
  void _filterList(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _allProducts);
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final nameLower = product.name.toLowerCase();
        final barcodeLower = product.barcode.toLowerCase();
        final searchLower = query.toLowerCase();
        // Check if the search text matches the name OR the barcode
        return nameLower.contains(searchLower) || barcodeLower.contains(searchLower);
      }).toList();
    });
  }

  // --- 3. Scanner exact match (PDA Trigger) ---
  Future<void> _searchBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    final product = await DatabaseHelper.instance.getProductByBarcode(barcode.trim());

    if (product != null) {
      _openEditCard(product);
    } else {
      setState(() => _scannedProduct = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productNotFound),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    _searchController.clear();
    _filterList(''); // Reset the list
  }

  // --- 4. Open the Edit Card (Used by Scanner AND Tap) ---
  void _openEditCard(Product product) {
    setState(() {
      _scannedProduct = product;
      _newStockController.text = product.stock.toString();
    });
  }

  // --- 5. Save the new stock ---
  Future<void> _updateStock() async {
    if (_scannedProduct != null) {
      final newStock = int.tryParse(_newStockController.text) ?? _scannedProduct!.stock;

      _scannedProduct!.stock = newStock;
      await DatabaseHelper.instance.updateProduct(_scannedProduct!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _scannedProduct = null;
        });

        // Refresh the main list to show the new stock count!
        _loadAllProducts();
        _searchController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          loc.inventory,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          // Premium Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E0045), Color(0xFF4A00E0), Color(0xFF00B4DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // TOP SECTION: Search Bar & Edit Card
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // --- SEARCH BAR ---
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                            autofocus: true,
                            onChanged: _filterList, // Filters instantly as you type!
                            onSubmitted: _searchBarcode, // Triggers when scanner fires
                            decoration: InputDecoration(
                              // Using our new translated word!
                              hintText: loc.searchHint,
                              hintStyle: GoogleFonts.poppins(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterList('');
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // --- EDIT CARD (Pops up if item is tapped or scanned) ---
                      if (_scannedProduct != null) ...[
                        const SizedBox(height: 20),
                        _buildProductCard(loc),
                      ]
                    ],
                  ),
                ),

                // BOTTOM SECTION: The Master List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                    child: Text(
                      "No products found.",
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildListTile(product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PRO 2026 GLASS LIST TILE ---
  Widget _buildListTile(Product product) {
    // Determine Stock Badge Color
    Color badgeColor;
    if (product.stock == 0) {
      badgeColor = Colors.redAccent.shade400; // Out of stock!
    } else if (product.stock <= 10) {
      badgeColor = Colors.orangeAccent.shade400; // Running low
    } else {
      badgeColor = Colors.greenAccent.shade400; // Healthy stock
    }

    return GestureDetector(
      onTap: () => _openEditCard(product), // Tap to edit!
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                children: [
                  // Category Icon Background
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 16),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${product.category} • \$${product.price.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Glowing Stock Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          product.stock.toString(),
                          style: GoogleFonts.poppins(color: badgeColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- REUSABLE PRODUCT INFO CARD (Kept exactly as you had it, just integrated!) ---
  Widget _buildProductCard(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _scannedProduct!.category.toUpperCase(),
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    ),
                    // Add a close button to dismiss the card
                    GestureDetector(
                      onTap: () => setState(() => _scannedProduct = null),
                      child: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _scannedProduct!.name,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.newStock,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _newStockController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      loc.updateStock,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}