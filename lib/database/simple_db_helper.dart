// File: lib/database/simple_db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SimpleDatabaseHelper {
  static final SimpleDatabaseHelper instance = SimpleDatabaseHelper._init();
  static Database? _database;

  SimpleDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Note: We are using a completely different file name here!
    _database = await _initDB('simple_pda_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // <-- 1. Bumped version to 2 for the Reception update
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // <-- 2. Added upgrade script to safely add the new table
    );
  }

  Future _createDB(Database db, int version) async {
    // A very lightweight table just for counting barcodes (Inventory)
    await db.execute('''
      CREATE TABLE simple_inventory (
        barcode TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL
      )
    ''');

    // Create the new reception log table on fresh installs
    await db.execute('''
      CREATE TABLE simple_reception (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        comment TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // --- NEW: UPGRADE DATABASE ---
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reception table for existing users upgrading from v1 to v2
      // This ensures you don't lose any of your existing simple_inventory data!
      await db.execute('''
        CREATE TABLE simple_reception (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          comment TEXT,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  // ==========================================
  // --- ACTIONS FOR INVENTORY (COUNTING) ---
  // ==========================================

  // Increase quantity or insert new barcode
  Future<void> scanBarcode(String barcode) async {
    final db = await instance.database;

    final result = await db.query(
      'simple_inventory',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (result.isNotEmpty) {
      // It exists, so add 1 to the current quantity
      int currentQty = result.first['quantity'] as int;
      await db.update(
        'simple_inventory',
        {'quantity': currentQty + 1},
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } else {
      // It's new, so insert it with a quantity of 1
      await db.insert('simple_inventory', {
        'barcode': barcode,
        'quantity': 1,
      });
    }
  }

  // Read all scanned items to show on the screen
  Future<List<Map<String, dynamic>>> getScannedItems() async {
    final db = await instance.database;
    return await db.query('simple_inventory', orderBy: 'quantity DESC');
  }

  // Manually edit quantity
  Future<void> updateQuantity(String barcode, int newQuantity) async {
    final db = await instance.database;

    if (newQuantity <= 0) {
      // If they change the quantity to 0, completely delete the item
      await db.delete('simple_inventory', where: 'barcode = ?', whereArgs: [barcode]);
    } else {
      // Otherwise, update the quantity to the exact number they typed
      await db.update(
        'simple_inventory',
        {'quantity': newQuantity},
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    }
  }

  // ==========================================
  // --- ACTIONS FOR RECEPTION (LOGGING) ---
  // ==========================================

  // 1. Save a new reception log from a supplier
  Future<void> saveReceptionLog(String barcode, int quantity, String comment) async {
    final db = await instance.database;
    await db.insert('simple_reception', {
      'barcode': barcode,
      'quantity': quantity,
      'comment': comment,
      // Automatically generate the exact date and time
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 2. Get history of received items to display on the Reception Screen
  Future<List<Map<String, dynamic>>> getReceptionHistory() async {
    final db = await instance.database;
    // Show the newest scans at the top of the list
    return await db.query('simple_reception', orderBy: 'timestamp DESC');
  }
}