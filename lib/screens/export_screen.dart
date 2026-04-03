import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _totalItems = 0;
  double _totalInventoryValue = 0.0;
  bool _isLoading = true;

  // Controls which type of export the user selected
  String _selectedExportType = 'ALL';

  @override
  void initState() {
    super.initState();
    _calculateSummary();
  }

  Future<void> _calculateSummary() async {
    final products = await DatabaseHelper.instance.readAllProducts();

    double totalValue = 0;
    for (var p in products) {
      totalValue += (p.costPrice * p.stock);
    }

    setState(() {
      _totalItems = products.length;
      _totalInventoryValue = totalValue;
      _isLoading = false;
    });
  }

  // --- THE "ULTRA THINK" DATA ANALYTICS LOGIC ---
  Future<void> _generateAndShareCsv() async {
    setState(() => _isLoading = true);

    try {
      final loc = AppLocalizations.of(context)!;
      final products = await DatabaseHelper.instance.readAllProducts();
      List<List<dynamic>> csvData = [];
      String fileName = "";

      // 1. COMPLETE INVENTORY
      if (_selectedExportType == 'ALL') {
        fileName = "Inventaire_Complet";
        csvData.add([
          "Barcode", "Name", "Category", "Stock",
          "Cost Price (DZD)", "Selling Price (DZD)", "Profit Margin (DZD)",
          "Total Cost Value (DZD)", "Total Retail Value (DZD)", "Last Updated"
        ]);

        for (var p in products) {
          csvData.add([
            p.barcode, p.name, p.category, p.stock,
            p.costPrice, p.price,
            (p.price - p.costPrice).toStringAsFixed(2), // Profit per item
            (p.costPrice * p.stock).toStringAsFixed(2), // Total capital invested
            (p.price * p.stock).toStringAsFixed(2),     // Expected revenue
            p.lastUpdated,
          ]);
        }
      }

      // 2. LOW STOCK REORDER LIST (Stock <= 10)
      else if (_selectedExportType == 'LOW_STOCK') {
        fileName = "A_Commander_Reorder";
        csvData.add(["Barcode", "Name", "Category", "CURRENT STOCK", "Cost Price (DZD)", "Supplier Order Qty"]);

        for (var p in products.where((p) => p.stock > 0 && p.stock <= 10)) {
          csvData.add([p.barcode, p.name, p.category, p.stock, p.costPrice, ""]); // Empty field for owner to write in
        }
      }

      // 3. CATEGORY FINANCIAL SUMMARY
      else if (_selectedExportType == 'CATEGORIES') {
        fileName = "Resumes_Categories";
        csvData.add(["Category", "Total Unique Items", "Total Items in Stock", "Total Capital Invested (DZD)", "Expected Revenue (DZD)"]);

        // Group data by category
        Map<String, Map<String, dynamic>> categoryStats = {};
        for (var p in products) {
          if (!categoryStats.containsKey(p.category)) {
            categoryStats[p.category] = {"unique": 0, "totalStock": 0, "invested": 0.0, "revenue": 0.0};
          }
          categoryStats[p.category]!["unique"] += 1;
          categoryStats[p.category]!["totalStock"] += p.stock;
          categoryStats[p.category]!["invested"] += (p.costPrice * p.stock);
          categoryStats[p.category]!["revenue"] += (p.price * p.stock);
        }

        categoryStats.forEach((category, stats) {
          csvData.add([
            category,
            stats["unique"],
            stats["totalStock"],
            stats["invested"].toStringAsFixed(2),
            stats["revenue"].toStringAsFixed(2)
          ]);
        });
      }

      // 4. DEAD STOCK (Stock == 0)
      else if (_selectedExportType == 'DEAD_STOCK') {
        fileName = "Stock_Mort";
        csvData.add(["Barcode", "Name", "Category", "Last Price (DZD)", "Last Updated"]);

        for (var p in products.where((p) => p.stock == 0)) {
          csvData.add([p.barcode, p.name, p.category, p.price, p.lastUpdated]);
        }
      }

      // Generate the File
      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().substring(0, 10);
      final path = "${directory.path}/${fileName}_$dateStr.csv";
      final file = File(path);

      await file.writeAsString(csv);

      // Share it
      await Share.shareXFiles(
          [XFile(path)],
          text: 'Mini-Market Export: $fileName ($dateStr)'
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          loc.exportTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- DZD FINANCIAL SUMMARY ---
                  Container(
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
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 64, color: Colors.white),
                              const SizedBox(height: 24),

                              Text(
                                loc.totalItems,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                              ),
                              Text(
                                _totalItems.toString(),
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 24),

                              Text(
                                loc.totalValue,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                              ),
                              // CHANGED TO DZD
                              Text(
                                "${_totalInventoryValue.toStringAsFixed(2)} DZD",
                                style: GoogleFonts.poppins(color: Colors.greenAccent.shade400, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- INTELLIGENT EXPORT TYPE SELECTOR ---
                  Text(
                    "Select Export Type:",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedExportType,
                        dropdownColor: const Color(0xFF4A00E0),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        isExpanded: true,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedExportType = newValue!;
                          });
                        },
                        items: [
                          DropdownMenuItem(value: 'ALL', child: Text(loc.exportAll)),
                          DropdownMenuItem(value: 'LOW_STOCK', child: Text(loc.exportLowStock)),
                          DropdownMenuItem(value: 'CATEGORIES', child: Text(loc.exportCategories)),
                          DropdownMenuItem(value: 'DEAD_STOCK', child: Text(loc.exportDeadStock)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- GENERATE BUTTON ---
                  ElevatedButton.icon(
                    onPressed: _generateAndShareCsv,
                    icon: const Icon(Icons.share, size: 24),
                    label: Text(
                      loc.generateCsv,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A00E0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}