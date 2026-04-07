// File: lib/screens/add_rfid_product_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_db_helper.dart';

class AddRfidProductScreen extends StatefulWidget {
  const AddRfidProductScreen({super.key});

  @override
  State<AddRfidProductScreen> createState() => _AddRfidProductScreenState();
}

class _AddRfidProductScreenState extends State<AddRfidProductScreen> {
  // --- HARDWARE SCANNER SETUP ---
  static const EventChannel _rfidChannel = EventChannel('com.pda_inventory/rfid_events');
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');
  StreamSubscription? _rfidSubscription;
  bool _isScanning = false;

  // --- NEW: PRODUCT TYPE TOGGLE ---
  String _productType = 'retail'; // Defaults to 'retail'. The other option is 'market'.

  // --- FORM CONTROLLERS ---
  final TextEditingController _epcController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Apparel (Retail)
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();

  // Grocery (Market)
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _prodDateController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Financial & Inventory
  final TextEditingController _supplierIdController = TextEditingController();
  final TextEditingController _supplierCodeController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _reorderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupRfidScanner();
  }

  void _setupRfidScanner() {
    _rfidSubscription = _rfidChannel.receiveBroadcastStream().listen((dynamic event) {
      final String scannedEpc = event.toString();
      setState(() {
        _epcController.text = scannedEpc;
      });
      _stopScanning();
    });
  }

  Future<void> _startScanning() async {
    setState(() => _isScanning = true);
    try { await _methodChannel.invokeMethod('startScan'); } catch (e) { setState(() => _isScanning = false); }
  }

  Future<void> _stopScanning() async {
    setState(() => _isScanning = false);
    try { await _methodChannel.invokeMethod('stopScan'); } catch (e) { /* Handle error quietly */ }
  }

  @override
  void dispose() {
    _stopScanning();
    _rfidSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_epcController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please scan an EPC tag first!"), backgroundColor: Colors.red));
      return;
    }

    final productData = {
      'epc': _epcController.text,
      'product_type': _productType, // <-- NEW: Saves the toggle switch state!
      'sku': _skuController.text,
      'barcode': _barcodeController.text,
      'product_name': _nameController.text,
      'brand_name': _brandController.text,
      'category': _categoryController.text,
      'sub_category': _subCategoryController.text,
      'description': _descController.text,

      'size': _productType == 'retail' ? _sizeController.text : null,
      'color': _productType == 'retail' ? _colorController.text : null,
      'gender_dept': _productType == 'retail' ? _genderController.text : null,
      'season': _productType == 'retail' ? _seasonController.text : null,
      'material': _productType == 'retail' ? _materialController.text : null,

      'batch_lot': _productType == 'market' ? _batchController.text : null,
      'production_date': _productType == 'market' ? _prodDateController.text : null,
      'expiration_date': _productType == 'market' ? _expDateController.text : null,
      'weight_volume': _productType == 'market' ? _weightController.text : null,

      'supplier_id': _supplierIdController.text,
      'supplier_code': _supplierCodeController.text,
      'cost_price': double.tryParse(_costPriceController.text) ?? 0.0,
      'selling_price': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'discount_price': double.tryParse(_discountController.text) ?? 0.0,
      'tax_rate': double.tryParse(_taxController.text) ?? 0.0,

      'store_location_id': _locationController.text,
      'zone_aisle': _zoneController.text,
      'stock_quantity': int.tryParse(_stockController.text) ?? 0,
      'reorder_level': int.tryParse(_reorderController.text) ?? 0,
      'date_added': DateTime.now().toIso8601String(),
    };

    await AppDatabaseHelper.instance.insertEnterpriseProduct(productData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Successfully Saved!"), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Register RFID Product", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. HARDWARE SCANNER SECTION
          _buildHardwareCard(),
          const SizedBox(height: 20),

          // 2. THE NEW TYPE TOGGLE SWITCH
          _buildTypeToggle(),
          const SizedBox(height: 20),

          // 3. CORE DETAILS (Always Visible)
          _buildExpandableSection(
              title: "Core Identification",
              icon: CupertinoIcons.barcode_viewfinder,
              children: [
                _buildTextField(_nameController, "Product Name (Required)"),
                _buildTextField(_skuController, "SKU (Internal Code)"),
                _buildTextField(_barcodeController, "Barcode (UPC/EAN)"),
                _buildTextField(_brandController, "Brand Name"),
                _buildTextField(_categoryController, "Category"),
                _buildTextField(_subCategoryController, "Sub-Category"),
              ]
          ),

          // 4. CONDITIONAL UI: Only shows if 'retail' is selected
          if (_productType == 'retail')
            _buildExpandableSection(
                title: "Apparel Details (Retail)",
                icon: Icons.checkroom,
                children: [
                  _buildTextField(_sizeController, "Size (S, M, 32x34)"),
                  _buildTextField(_colorController, "Color"),
                  _buildTextField(_genderController, "Gender / Dept"),
                  _buildTextField(_seasonController, "Season (SS26)"),
                  _buildTextField(_materialController, "Material (100% Cotton)"),
                ]
            ),

          // 5. CONDITIONAL UI: Only shows if 'market' is selected
          if (_productType == 'market')
            _buildExpandableSection(
                title: "Consumable Details (Market)",
                icon: Icons.local_grocery_store_outlined,
                children: [
                  _buildTextField(_batchController, "Batch / Lot Number"),
                  _buildTextField(_prodDateController, "Production Date (YYYY-MM-DD)"),
                  _buildTextField(_expDateController, "Expiration Date (YYYY-MM-DD)"),
                  _buildTextField(_weightController, "Weight / Volume (e.g. 500g)"),
                ]
            ),

          // 6. FINANCIAL (Always Visible)
          _buildExpandableSection(
              title: "Pricing & Suppliers",
              icon: CupertinoIcons.money_dollar_circle,
              children: [
                _buildTextField(_sellingPriceController, "Selling Price (MSRP)", isNumber: true),
                _buildTextField(_costPriceController, "Cost Price", isNumber: true),
                _buildTextField(_supplierCodeController, "Supplier Item Code"),
              ]
          ),

          // 7. INVENTORY (Always Visible)
          _buildExpandableSection(
              title: "Inventory & Location",
              icon: CupertinoIcons.building_2_fill,
              children: [
                _buildTextField(_stockController, "Current Stock Quantity", isNumber: true),
                _buildTextField(_zoneController, "Zone / Aisle (e.g. Aisle 4)"),
              ]
          ),

          const SizedBox(height: 30),

          // SAVE BUTTON
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text("SAVE ENTERPRISE PRODUCT", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _saveProduct,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTypeToggle() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(8),
      child: CupertinoSlidingSegmentedControl<String>(
        backgroundColor: Colors.grey[200]!,
        thumbColor: const Color(0xFF4A00E0),
        groupValue: _productType,
        children: {
          'retail': Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("👔 Retail (Apparel)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _productType == 'retail' ? Colors.white : Colors.black87)),
          ),
          'market': Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("🛒 Market (Grocery)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _productType == 'market' ? Colors.white : Colors.black87)),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() { _productType = value; });
          }
        },
      ),
    );
  }

  Widget _buildHardwareCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF4A00E0), width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.wifi_tethering, size: 40, color: _isScanning ? Colors.red : const Color(0xFF4A00E0)),
            const SizedBox(height: 10),
            Text("Hardware Tag Link", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _epcController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Scanned EPC Code",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(CupertinoIcons.tag_solid),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : const Color(0xFF4A00E0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isScanning ? _stopScanning : _startScanning,
                child: Text(
                    _isScanning ? "STOP SCANNING" : "SCAN RFID LABEL",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true, // Auto-expand by default so it's easy to see!
        leading: Icon(icon, color: const Color(0xFF4A00E0)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}