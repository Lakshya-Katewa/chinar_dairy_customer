import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductUnit { liter, kg, piece }
enum ProductType { oneTimeOnly, general, subscription } // 0, 1, 2

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final ProductUnit unit;
  final String category;
  final String? imageUrl;
  final bool isActive;
  final int stock;
  final ProductType type;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    this.imageUrl,
    required this.isActive,
    required this.stock,
    required this.type,
    required this.createdAt,
  });

  String get unitText {
    switch (unit) {
      case ProductUnit.liter:
        return 'L';
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.piece:
        return 'piece';
    }
  }

  bool get canSubscribe => type == ProductType.subscription;
  bool get isOneTimeOnly => type == ProductType.oneTimeOnly;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      unit: _parseUnit(data['unit']),
      category: _parseCategory(data['type']),
      imageUrl: data['imageUrl'],
      isActive: true,
      stock: (data['quantity'] ?? 0).toInt(),
      type: _parseProductType(data['type']),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  static ProductUnit _parseUnit(dynamic unitValue) {
    if (unitValue is int) {
      switch (unitValue) {
        case 0: return ProductUnit.liter;
        case 1: return ProductUnit.kg;
        case 2: return ProductUnit.piece;
        default: return ProductUnit.liter;
      }
    }
    return ProductUnit.liter;
  }

  static String _parseCategory(dynamic typeValue) {
    if (typeValue is int) {
      switch (typeValue) {
        case 0: return 'Dairy';
        case 1: return 'Beverages';
        case 2: return 'Milk Products';
        default: return 'General';
      }
    }
    return 'General';
  }

  static ProductType _parseProductType(dynamic typeValue) {
    if (typeValue is int) {
      switch (typeValue) {
        case 0: return ProductType.oneTimeOnly;
        case 1: return ProductType.general;
        case 2: return ProductType.subscription;
        default: return ProductType.general;
      }
    }
    return ProductType.general;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit.index,
      'type': type.index,
      'imageUrl': imageUrl,
      'quantity': stock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
