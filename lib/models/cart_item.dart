import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class CartItem {
  final String id;
  final String customerId;
  final String productId;
  final String productName;
  final double price;
  final double quantity;
  final String unit;
  final DateTime? orderDate;
  final DateTime createdAt;

  CartItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    this.orderDate,
    required this.createdAt,
  });

  factory CartItem.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      orderDate: data['orderDate'] != null
          ? (data['orderDate'] as firestore.Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'orderDate': orderDate != null
          ? firestore.Timestamp.fromDate(orderDate!)
          : null,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }

  double get totalPrice => price * quantity;
}
