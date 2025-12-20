import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String customerId;
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final String unit;
  final DateTime? orderDate;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.unit,
    this.orderDate,
    this.imageUrl,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      price: (data['price'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      orderDate: data['orderDate'] != null 
          ? (data['orderDate'] as Timestamp).toDate() 
          : null,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'orderDate': orderDate != null ? Timestamp.fromDate(orderDate!) : null,
      'imageUrl': imageUrl,
    };
  }
}
