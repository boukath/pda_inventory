import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class PrintLabelsScreen extends StatefulWidget {
  const PrintLabelsScreen({super.key});

  @override
  State<PrintLabelsScreen> createState() => _PrintLabelsScreenState();
}

class _PrintLabelsScreenState extends State<PrintLabelsScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  List<Product> _allProducts = [];
  Product? _selectedProduct;
  final _qtyController = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _loadProducts();
  }

  Future<void> _initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Bluetooth error: $e");
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() => _connected = true);
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() => _connected = false);
          break;
        default:
          break;
      }
    });

    if (mounted) {
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    }
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _allProducts = products;
    });
  }

  void _connectPrinter() {
    if (_selectedDevice != null) {
      bluetooth.connect(_selectedDevice!).catchError((error) {
        setState(() => _connected = false);
      });
    }
  }

  void _disconnectPrinter() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  // --- THE PRINTING LOGIC ---
  void _printLabels() async {
    if (_connected && _selectedProduct != null) {
      int copies = int.tryParse(_qtyController.text) ?? 1;

      for (int i = 0; i < copies; i++) {
        // 1. Store Name (Size 1, Centered)
        bluetooth.printCustom("MINI MARCHE", 1, 1);

        // 2. Product Name (Size 1, Centered)
        bluetooth.printCustom(_selectedProduct!.name.toUpperCase(), 1, 1);

        // 3. Huge Price (Size 3, Centered, Bold)
        bluetooth.printCustom("${_selectedProduct!.price.toStringAsFixed(0)} DZD", 3, 1);

        // 4. The Barcode Lines! (Takes the barcode text and draws the scannable lines)
        bluetooth.printNewLine();
        bluetooth.printQRcode(_selectedProduct!.barcode, 200, 200, 1); // OR use printBarcode if printer supports it natively

        // 5. Feed the paper out
        bluetooth.printNewLine();
        bluetooth.printNewLine();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Printer not connected or product not selected!")),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
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
          loc.printLabels, // Fallback text just in case
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. BLUETOOTH CONNECTION CARD ---
                  _buildGlassContainer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bluetooth, color: _connected ? Colors.greenAccent : Colors.white70, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<BluetoothDevice>(
                                value: _selectedDevice,
                                dropdownColor: const Color(0xFF4A00E0),
                                isExpanded: true,
                                hint: Text(loc.selectPrinter, style: GoogleFonts.poppins(color: Colors.white70)),
                                style: GoogleFonts.poppins(color: Colors.white),
                                items: _devices.map((device) => DropdownMenuItem(
                                  value: device,
                                  child: Text(device.name ?? "Unknown"),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedDevice = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _connected ? null : _connectPrinter,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade400, foregroundColor: Colors.black),
                                child: Text(loc.connect, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _connected ? _disconnectPrinter : null,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade400, foregroundColor: Colors.white),
                                child: Text(loc.disconnect, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- 2. PRODUCT SELECTION ---
                  Text("Select Product", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),

                  // Autocomplete for full Product Objects
                  Autocomplete<Product>(
                    displayStringForOption: (Product option) => option.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Product>.empty();
                      }
                      return _allProducts.where((Product p) {
                        return p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                            p.barcode.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (Product selection) {
                      setState(() {
                        _selectedProduct = selection;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: loc.searchHint,
                          hintStyle: GoogleFonts.poppins(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option.name, style: GoogleFonts.poppins(color: const Color(0xFF4A00E0), fontWeight: FontWeight.bold)),
                                  subtitle: Text("${option.price} DZD", style: GoogleFonts.poppins(color: Colors.black54)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- 3. COPIES & PRINT ---
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.printCopies, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (_connected && _selectedProduct != null) ? _printLabels : null,
                          icon: const Icon(Icons.print, size: 28),
                          label: Text(
                            "PRINT", // Simplified button text
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4A00E0),
                            disabledBackgroundColor: Colors.white30,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to keep UI clean
  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}