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
      version: 1, // Starting fresh at version 1
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // A very lightweight table just for counting barcodes
    await db.execute('''
      CREATE TABLE simple_inventory (
        barcode TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  // --- ACTIONS ---

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
-
  // Read all scanned items to show on the screen
  Future<List<Map<String, dynamic>>> getScannedItems() async {
    final db = await instance.database;
    return await db.query('simple_inventory', orderBy: 'quantity DESC');
  }

  // --- NEW METHOD TO MANUALLY EDIT QUANTITY ---
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
}