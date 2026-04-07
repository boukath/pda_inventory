// File: lib/database/app_db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseHelper {
  static final AppDatabaseHelper instance = AppDatabaseHelper._init();
  static Database? _database;

  AppDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // One single unified database file for the entire app!
    _database = await _initDB('smart_retail_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // <-- Bumped to version 2 for the new dynamic fields
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // <-- Safe upgrade path included
    );
  }

  Future _createDB(Database db, int version) async {
    // TABLE 1: The Temporary Scanner Registry (For Inventory Counts)
    await db.execute('''
      CREATE TABLE scanned_tags (
        epc TEXT PRIMARY KEY,
        scanTime TEXT
      )
    ''');

    // TABLE 2: The Permanent Product Catalog (For Enterprise Details)
    await db.execute('''
      CREATE TABLE enterprise_products (
        epc TEXT PRIMARY KEY, 
        product_type TEXT,
        sku TEXT,
        barcode TEXT,
        product_name TEXT,
        brand_name TEXT,
        category TEXT,
        sub_category TEXT,
        description TEXT,
        
        size TEXT,
        color TEXT,
        gender_dept TEXT,
        season TEXT,
        material TEXT,
        
        batch_lot TEXT,
        production_date TEXT,
        expiration_date TEXT,
        weight_volume TEXT,
        
        supplier_id TEXT,
        supplier_code TEXT,
        cost_price REAL,
        selling_price REAL,
        discount_price REAL,
        tax_rate REAL,
        
        store_location_id TEXT,
        zone_aisle TEXT,
        stock_quantity INTEGER,
        reorder_level INTEGER,
        date_added TEXT,
        
        custom_fields TEXT -- <-- NEW: The magic column for dynamic fields!
      )
    ''');
  }

  // --- HANDLE DATABASE UPGRADES ---
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Safely add the custom_fields column to existing databases without losing data
      await db.execute('ALTER TABLE enterprise_products ADD COLUMN custom_fields TEXT');
    }
  }

  // ==========================================
  // --- INVENTORY SCANNER ACTIONS (Table 1) ---
  // ==========================================

  Future<void> saveScannedEpc(String epc) async {
    final db = await instance.database;
    await db.insert(
      'scanned_tags',
      {
        'epc': epc,
        'scanTime': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore duplicates in the same scan session
    );
  }

  Future<List<Map<String, dynamic>>> getSavedScannedTags() async {
    final db = await instance.database;
    return await db.query('scanned_tags', orderBy: 'scanTime DESC');
  }

  Future<void> clearScannedTags() async {
    final db = await instance.database;
    await db.delete('scanned_tags');
  }

  // ==========================================
  // --- ENTERPRISE PRODUCT ACTIONS (Table 2) ---
  // ==========================================

  Future<void> insertEnterpriseProduct(Map<String, dynamic> productData) async {
    final db = await instance.database;
    await db.insert(
      'enterprise_products',
      productData,
      conflictAlgorithm: ConflictAlgorithm.replace, // Overwrite if the profile is updated
    );
  }

  // --- FETCH ALL ENTERPRISE PRODUCTS ---
  Future<List<Map<String, dynamic>>> getAllEnterpriseProducts() async {
    final db = await instance.database;
    // Order them so the newest additions show up at the top of the list!
    return await db.query('enterprise_products', orderBy: 'date_added DESC');
  }
}