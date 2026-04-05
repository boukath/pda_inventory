// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BoitexScan';

  @override
  String get home => 'Home';

  @override
  String get addProduct => 'Add Product';

  @override
  String get inventory => 'Inventory Count';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get barcode => 'Barcode';

  @override
  String get productName => 'Product Name';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get category => 'Category';

  @override
  String get stock => 'Current Stock';

  @override
  String get save => 'Save';

  @override
  String get success => 'Success!';

  @override
  String get errorDuplicate =>
      'A product with this barcode or name already exists!';

  @override
  String get productNotFound => 'Product not found!';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get newStock => 'New Stock Count';

  @override
  String get searchHint => 'Scan Barcode or Type Name...';

  @override
  String get exportTitle => 'Export Data';

  @override
  String get totalItems => 'Total Unique Items';

  @override
  String get totalValue => 'Total Inventory Value';

  @override
  String get generateCsv => 'Generate & Share CSV';

  @override
  String get exporting => 'Generating file...';

  @override
  String get exportAll => 'Complete Inventory';

  @override
  String get exportLowStock => 'Reorder List (Low Stock)';

  @override
  String get exportCategories => 'Category Financial Summary';

  @override
  String get exportDeadStock => 'Dead Stock (0 Inventory)';

  @override
  String get printLabels => 'Print Labels';

  @override
  String get selectPrinter => 'Select Printer';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get printCopies => 'Number of Copies';

  @override
  String get printBtn => 'PRINT LABELS';

  @override
  String get filterAll => 'All';

  @override
  String get filterLowStock => 'Low Stock';

  @override
  String get filterOutStock => 'Out of Stock';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get simpleMenuTitle => 'Scan Dashboard';

  @override
  String get reception => 'Receiving';

  @override
  String get bon => 'Orders / Vouchers';

  @override
  String get comingSoon => 'Coming Soon!';

  @override
  String get readyToScan => 'Ready to scan...\nPoint PDA at barcode.';

  @override
  String get developerMode => 'Developer Mode';

  @override
  String get enterAdminPin => 'Enter Admin PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get cancel => 'Cancel';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get scannedItem => 'Scanned: ';

  @override
  String get toggleCount => 'COUNT (+1)';

  @override
  String get toggleCheck => 'CHECK (INFO)';

  @override
  String get receiveProductTitle => 'Receive Product';

  @override
  String get quantityReceived => 'Quantity Received';

  @override
  String get supplierComment => 'Supplier / Comment';

  @override
  String get receivingLogTitle => 'Receiving Log';

  @override
  String get readyToReceiveHint =>
      'Ready to receive.\nScan a product to begin.';

  @override
  String get supplierPrefix => 'Supplier: ';

  @override
  String get supplierNone => 'None';

  @override
  String get finalizeAndSaveOrder => 'Finalize & Save Order';

  @override
  String get orderSavedSuccess => 'Order Saved Successfully!';

  @override
  String get noOrdersFound =>
      'No orders found.\nSave an inventory session first!';

  @override
  String get qty => 'Qty';

  @override
  String get manualEntryTitle => 'Manual Entry';

  @override
  String get date => 'Date';
}
