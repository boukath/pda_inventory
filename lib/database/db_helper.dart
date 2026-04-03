import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('minimarket_inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // I changed the version to 2 just in case you already ran the app on an emulator!
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        costPrice REAL NOT NULL,
        category TEXT NOT NULL,
        stock INTEGER NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');
  }

  // --- DATABASE ACTIONS ---

  // 1. Save a new product
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert('products', product.toMap());
    return Product(
      id: id,
      barcode: product.barcode,
      name: product.name,
      price: product.price,
      costPrice: product.costPrice,
      category: product.category,
      stock: product.stock,
      lastUpdated: product.lastUpdated,
    );
  }

  // 2. Read all products (Useful for CSV export and inventory list)
  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  // 3. Find a product by its barcode (Crucial for the PDA scanner!)
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      columns: ['id', 'barcode', 'name', 'price', 'costPrice', 'category', 'stock', 'lastUpdated'],
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null; // Product not found
    }
  }

  // 4. Update a product (e.g., changing the stock count)
  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // 5. Get a list of unique categories for the Autocomplete feature
  Future<List<String>> getUniqueCategories() async {
    final db = await instance.database;
    // SELECT DISTINCT grabs categories without repeating duplicates
    final result = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != "" ORDER BY category ASC'
    );

    // Convert the raw SQL data into a simple List of Strings
    return result.map((row) => row['category'] as String).toList();
  }

  // 6. Check if a barcode or name already exists
  Future<bool> checkDuplicate(String barcode, String name) async {
    final db = await instance.database;

    // We ask the database to find any row that matches the barcode OR the name
    final result = await db.query(
      'products',
      where: 'barcode = ? OR name = ?',
      whereArgs: [barcode, name],
    );

    // If the result is NOT empty, it means a duplicate exists (returns true)
    return result.isNotEmpty;
  }

}