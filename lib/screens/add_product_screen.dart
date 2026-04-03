import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();

  // We will store the Autocomplete's controller here so we can read its value
  TextEditingController? _categoryAutoController;

  // This list will hold the categories we fetch from the database
  List<String> _existingCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Fetch memory when the screen loads!
  }

  // Go to the database and grab the unique categories
  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getUniqueCategories();
    setState(() {
      _existingCategories = categories;
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    // 1. Check if the text fields are filled out
    if (_formKey.currentState!.validate()) {

      final barcode = _barcodeController.text.trim();
      final name = _nameController.text.trim();

      // 2. CHECK FOR DUPLICATES BEFORE DOING ANYTHING ELSE!
      final isDuplicate = await DatabaseHelper.instance.checkDuplicate(barcode, name);

      if (isDuplicate) {
        // If it's a duplicate, show a red Error message and STOP the function.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorDuplicate,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: Colors.redAccent.shade700, // Red for error
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return; // This 'return' immediately kicks us out of the save function!
      }

      // 3. If it's NOT a duplicate, proceed with saving as normal
      final categoryText = _categoryAutoController?.text.trim() ?? '';

      final newProduct = Product(
        barcode: barcode,
        name: name,
        price: double.tryParse(_priceController.text) ?? 0.0,
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        category: categoryText,
        stock: int.tryParse(_stockController.text) ?? 0,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.createProduct(newProduct);

      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.success,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        _barcodeController.clear();
        _nameController.clear();
        _priceController.clear();
        _costPriceController.clear();
        _categoryAutoController?.clear();
        _stockController.clear();
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
          loc.addProduct,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGlassTextField(
                      controller: _barcodeController,
                      label: loc.barcode,
                      icon: Icons.qr_code_scanner,
                      isNumber: false,
                    ),
                    const SizedBox(height: 16),
                    _buildGlassTextField(
                      controller: _nameController,
                      label: loc.productName,
                      icon: Icons.shopping_bag_outlined,
                      isNumber: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassTextField(
                            controller: _costPriceController,
                            label: loc.costPrice,
                            icon: Icons.attach_money,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGlassTextField(
                            controller: _priceController,
                            label: loc.sellingPrice,
                            icon: Icons.sell_outlined,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      // We use crossAxisAlignment to keep the heights aligned when dropdown shows
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          // OUR NEW SMART AUTOCOMPLETE WIDGET!
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              // Filter existing categories by what the user is typing
                              return _existingCategories.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            // The visual dropdown menu
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.4, // Match width roughly
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95), // Frosted glass dropdown
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        )
                                      ],
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(
                                              option,
                                              style: GoogleFonts.poppins(
                                                  color: const Color(0xFF4A00E0),
                                                  fontWeight: FontWeight.w600
                                              )
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            // The actual text field you type in
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // Link the internal controller so we can save its data later!
                              _categoryAutoController = controller;
                              return _buildGlassTextField(
                                controller: controller,
                                focusNode: focusNode,
                                label: loc.category,
                                icon: Icons.category_outlined,
                                isNumber: false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGlassTextField(
                            controller: _stockController,
                            label: loc.stock,
                            icon: Icons.inventory_2_outlined,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A00E0),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 10,
                      ),
                      child: Text(
                        loc.save,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE GLASS TEXT FIELD ---
  // Notice we added FocusNode so the Autocomplete menu knows when to appear!
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isNumber,
    FocusNode? focusNode,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: Colors.white70),
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorStyle: GoogleFonts.poppins(color: Colors.redAccent.shade100),
          ),
        ),
      ),
    );
  }
}