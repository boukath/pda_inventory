// File: lib/screens/add_rfid_product_screen.dart

import 'dart:async';
import 'dart:convert'; // <-- NEW: Required for jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_db_helper.dart';
import '../l10n/app_localizations.dart'; // <-- TRANSLATIONS IMPORT

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

  // --- PRODUCT TYPE TOGGLE ---
  String _productType = 'retail';

  // --- NEW: DYNAMIC CUSTOM FIELDS MAP ---
  // This map holds an infinite amount of user-created fields!
  final Map<String, TextEditingController> _customFields = {};

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

    // Clean up dynamic controllers to prevent memory leaks
    _customFields.forEach((key, controller) => controller.dispose());

    super.dispose();
  }

  // --- DYNAMIC FIELD LOGIC ---
  Future<void> _showAddCustomFieldDialog() async {
    TextEditingController fieldNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.addCustomField, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: fieldNameController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.customFieldHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0), foregroundColor: Colors.white),
            onPressed: () {
              String newName = fieldNameController.text.trim();
              if (newName.isNotEmpty && !_customFields.containsKey(newName)) {
                setState(() {
                  _customFields[newName] = TextEditingController();
                });
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.addFieldBtn),
          ),
        ],
      ),
    );
  }

  void _deleteCustomField(String fieldName) {
    setState(() {
      _customFields[fieldName]?.dispose();
      _customFields.remove(fieldName);
    });
  }

  // --- SAVE DATA TO DB ---
  Future<void> _saveProduct() async {
    // 1. Mandatory Checks
    if (_epcController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scanEpcWarning), backgroundColor: Colors.red));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.productNameRequired), backgroundColor: Colors.red));
      return;
    }

    // 2. Package dynamic custom fields into JSON
    Map<String, String> customDataMap = {};
    _customFields.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        customDataMap[key] = controller.text.trim();
      }
    });
    String customFieldsJson = jsonEncode(customDataMap);

    // 3. Prepare the massive Enterprise package
    final productData = {
      'epc': _epcController.text,
      'product_type': _productType,
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

      // The Magic JSON Column!
      'custom_fields': customFieldsJson,
    };

    await AppDatabaseHelper.instance.insertEnterpriseProduct(productData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.productSavedSuccess), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registerRfidProduct, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. HARDWARE SCANNER SECTION
          _buildHardwareCard(context),
          const SizedBox(height: 20),

          // 2. THE NEW TYPE TOGGLE SWITCH
          _buildTypeToggle(context),
          const SizedBox(height: 20),

          // 3. CORE DETAILS
          _buildExpandableSection(
              title: AppLocalizations.of(context)!.coreIdentification,
              icon: CupertinoIcons.barcode_viewfinder,
              children: [
                _buildTextField(_nameController, AppLocalizations.of(context)!.productNameReqLabel),
                _buildTextField(_skuController, AppLocalizations.of(context)!.skuInternalCode),
                _buildTextField(_barcodeController, AppLocalizations.of(context)!.barcodeUpc),
                _buildTextField(_brandController, AppLocalizations.of(context)!.brandName),
                _buildTextField(_categoryController, AppLocalizations.of(context)!.category),
                _buildTextField(_subCategoryController, AppLocalizations.of(context)!.subCategory),
              ]
          ),

          // 4. CONDITIONAL UI: Retail
          if (_productType == 'retail')
            _buildExpandableSection(
                title: AppLocalizations.of(context)!.apparelDetails,
                icon: Icons.checkroom,
                children: [
                  _buildTextField(_sizeController, AppLocalizations.of(context)!.sizeLabel),
                  _buildTextField(_colorController, AppLocalizations.of(context)!.colorLabel),
                  _buildTextField(_genderController, AppLocalizations.of(context)!.genderDept),
                  _buildTextField(_seasonController, AppLocalizations.of(context)!.seasonLabel),
                  _buildTextField(_materialController, AppLocalizations.of(context)!.materialLabel),
                ]
            ),

          // 5. CONDITIONAL UI: Market
          if (_productType == 'market')
            _buildExpandableSection(
                title: AppLocalizations.of(context)!.consumableDetails,
                icon: Icons.local_grocery_store_outlined,
                children: [
                  _buildTextField(_batchController, AppLocalizations.of(context)!.batchLot),
                  _buildTextField(_prodDateController, AppLocalizations.of(context)!.productionDate),
                  _buildTextField(_expDateController, AppLocalizations.of(context)!.expirationDate),
                  _buildTextField(_weightController, AppLocalizations.of(context)!.weightVolume),
                ]
            ),

          // 6. FINANCIAL
          _buildExpandableSection(
              title: AppLocalizations.of(context)!.pricingSuppliers,
              icon: CupertinoIcons.money_dollar_circle,
              children: [
                _buildTextField(_sellingPriceController, AppLocalizations.of(context)!.sellingPriceMsrp, isNumber: true),
                _buildTextField(_costPriceController, AppLocalizations.of(context)!.costPrice, isNumber: true),
                _buildTextField(_supplierCodeController, AppLocalizations.of(context)!.supplierItemCode),
              ]
          ),

          // 7. INVENTORY
          _buildExpandableSection(
              title: AppLocalizations.of(context)!.inventoryLocation,
              icon: CupertinoIcons.building_2_fill,
              children: [
                _buildTextField(_stockController, AppLocalizations.of(context)!.currentStockQty, isNumber: true),
                _buildTextField(_zoneController, AppLocalizations.of(context)!.zoneAisle),
              ]
          ),

          // 8. THE NEW DYNAMIC CUSTOM FIELDS SECTION
          _buildDynamicFieldsSection(context),

          const SizedBox(height: 30),

          // SAVE BUTTON
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.saveEnterpriseProduct, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _saveProduct,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDynamicFieldsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.post_add, color: Color(0xFF4A00E0)),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.customFieldsTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            // Loop through map to draw existing dynamic fields
            ..._customFields.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key, // The custom name they typed!
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                      onPressed: () => _deleteCustomField(entry.key), // Deletes the field
                    )
                  ],
                ),
              );
            }),

            // Add Field Button
            Center(
              child: TextButton.icon(
                onPressed: _showAddCustomFieldDialog,
                icon: const Icon(Icons.add, color: Color(0xFF4A00E0)),
                label: Text(AppLocalizations.of(context)!.addCustomField, style: GoogleFonts.poppins(color: const Color(0xFF4A00E0), fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
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
            child: Text(AppLocalizations.of(context)!.retailApparel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _productType == 'retail' ? Colors.white : Colors.black87)),
          ),
          'market': Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(AppLocalizations.of(context)!.marketGrocery, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _productType == 'market' ? Colors.white : Colors.black87)),
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

  Widget _buildHardwareCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF4A00E0), width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.wifi_tethering, size: 40, color: _isScanning ? Colors.red : const Color(0xFF4A00E0)),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.hardwareTagLink, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _epcController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.scannedEpcCode,
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
                    _isScanning ? AppLocalizations.of(context)!.stopScanning : AppLocalizations.of(context)!.scanRfidLabel,
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
        initiallyExpanded: true,
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