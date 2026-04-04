import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class InventoryScreen extends StatefulWidget {
  // 1. Added the optional initialBarcode variable
  final String? initialBarcode;

  // 2. Updated the constructor to accept it
  const InventoryScreen({super.key, this.initialBarcode});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _newStockController = TextEditingController();

  Product? _scannedProduct;

  // Data lists
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];

  // We split the filters so you can check "Low Stock" AND a specific category!
  String _selectedStatus = 'All'; // 'All', 'Low Stock', 'Out of Stock'
  String _selectedCategory = 'All Categories';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // 3. Pre-fill the search field if the PDA scanner sent one over!
    if (widget.initialBarcode != null) {
      _searchController.text = widget.initialBarcode!;
      // Instantly trigger the search so the Edit Card pops up immediately!
      _searchBarcode(widget.initialBarcode!);
    }

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newStockController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- 1. Fetch products AND categories from Database ---
  Future<void> _loadData() async {
    final products = await DatabaseHelper.instance.readAllProducts();
    final categories = await DatabaseHelper.instance.getUniqueCategories();

    setState(() {
      _allProducts = products;
      _categories = categories;
      _applyFilters();
    });
  }

  // --- 2. Unified Filter Logic ---
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // A. Text Search Match
        final matchesText = product.name.toLowerCase().contains(query) ||
            product.barcode.toLowerCase().contains(query);
        if (!matchesText) return false;

        // B. Status Match (The top chips)
        if (_selectedStatus == 'Low Stock') {
          if (product.stock == 0 || product.stock > 10) return false;
        } else if (_selectedStatus == 'Out of Stock') {
          if (product.stock > 0) return false;
        }

        // C. Category Match (The dropdown sheet)
        if (_selectedCategory != 'All Categories') {
          if (product.category != _selectedCategory) return false;
        }

        return true;
      }).toList();
    });
  }

  // --- 3. Triggered when typing (Debounced) ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  // --- Scanner exact match (PDA Trigger) ---
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
    _applyFilters();
  }

  void _openEditCard(Product product) {
    setState(() {
      _scannedProduct = product;
      _newStockController.text = product.stock.toString();
    });
  }

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

        _loadData();
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
                // TOP SECTION
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            onChanged: _onSearchChanged,
                            onSubmitted: _searchBarcode,
                            decoration: InputDecoration(
                              hintText: loc.searchHint,
                              hintStyle: GoogleFonts.poppins(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
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

                      const SizedBox(height: 16),

                      // --- OVERFLOW PROTECTED STATUS CHIPS ---
                      // Wrap ensures if the screen is tiny, they drop to the next line!
                      Wrap(
                        spacing: 8.0, // Space between chips horizontally
                        runSpacing: 8.0, // Space between chips vertically if wrapped
                        children: [
                          _buildStatusChip('All', loc.filterAll, Icons.apps),
                          _buildStatusChip('Low Stock', loc.filterLowStock, Icons.warning_amber_rounded),
                          _buildStatusChip('Out of Stock', loc.filterOutStock, Icons.error_outline),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- ANIMATED CATEGORY SELECTOR BUTTON ---
                      GestureDetector(
                        onTap: () => _showCategoryBottomSheet(loc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.category_outlined, color: Colors.white70, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedCategory == 'All Categories' ? loc.filterAll : _selectedCategory,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),

                      // --- EDIT CARD ---
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
                      loc.noProductsFound,
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

  // --- REUSABLE STATUS CHIP (Top Row) ---
  Widget _buildStatusChip(String filterValue, String displayLabel, IconData icon) {
    final isSelected = _selectedStatus == filterValue;

    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min, // Important for Wrap
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black87 : Colors.white70),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.black87 : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedStatus = filterValue;
          });
          _applyFilters();
        },
        backgroundColor: Colors.white.withOpacity(0.1),
        selectedColor: Colors.greenAccent.shade400,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.greenAccent.shade400 : Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // --- PRO BOTTOM SHEET FOR 100+ CATEGORIES ---
  void _showCategoryBottomSheet(AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows the sheet to be taller!
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // Takes up 60% of screen
          decoration: const BoxDecoration(
            color: Color(0xFF1E0045), // Matches your theme
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Little grab handle at the top
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                "Select Category",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Scrollable list of all your categories
              Expanded(
                child: ListView(
                  children: [
                    _buildBottomSheetItem('All Categories', loc.filterAll),
                    ..._categories.map((c) => _buildBottomSheetItem(c, c)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM SHEET LIST TILE ---
  Widget _buildBottomSheetItem(String value, String displayLabel) {
    final isSelected = _selectedCategory == value;
    return ListTile(
      title: Text(
        displayLabel,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.greenAccent.shade400 : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: Colors.greenAccent.shade400) : null,
      onTap: () {
        setState(() {
          _selectedCategory = value;
        });
        _applyFilters();
        Navigator.pop(context); // Close the sheet automatically!
      },
    );
  }

  // --- PRO 2026 GLASS LIST TILE ---
  Widget _buildListTile(Product product) {
    Color badgeColor;
    if (product.stock == 0) {
      badgeColor = Colors.redAccent.shade400;
    } else if (product.stock <= 10) {
      badgeColor = Colors.orangeAccent.shade400;
    } else {
      badgeColor = Colors.greenAccent.shade400;
    }

    return GestureDetector(
      onTap: () => _openEditCard(product),
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
                          "${product.category} • ${product.price.toStringAsFixed(2)} DZD",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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

  // --- REUSABLE PRODUCT INFO CARD ---
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