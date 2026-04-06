// File: lib/models/product.dart

class Product {
  final int? id;
  final String barcode;
  final String name;
  final double price; // Selling price
  final double costPrice; // Buying price
  final String category;
  int stock;
  final String lastUpdated; // When was this last scanned/updated?

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.category,
    this.stock = 0,
    required this.lastUpdated,
  });

  // --- NEW: copyWith method for RFID inventory updates ---
  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    double? price,
    double? costPrice,
    String? category,
    int? stock,
    String? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  // -----------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'category': category,
      'stock': stock,
      'lastUpdated': lastUpdated,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      price: map['price'],
      costPrice: map['costPrice'],
      category: map['category'],
      stock: map['stock'],
      lastUpdated: map['lastUpdated'],
    );
  }
}