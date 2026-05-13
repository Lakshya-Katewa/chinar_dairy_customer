import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final String unit;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.unit,
    this.imageUrl,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DetailedAddress deliveryAddress;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String? notes;
  final String? paymentMethod; // Added payment method
  final String? paymentId; // Added payment ID
  final String? deliverySlot; // Added delivery slot
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.orderDate,
    required this.deliveryDate,
    this.notes,
    this.paymentMethod,
    this.paymentId,
    this.deliverySlot,
    this.deliveredAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress.toMap(),
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'notes': notes,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'deliverySlot': deliverySlot,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Debug print the raw data
      print('🔍 Parsing order ${doc.id}');
      print('📄 Raw data: $data');

      // Parse delivery address with fallback values
      DetailedAddress deliveryAddress;
      try {
        final addressData =
            data['deliveryAddress'] as Map<String, dynamic>? ?? {};
        deliveryAddress = DetailedAddress(
          houseNumber: addressData['houseNumber'] ?? '',
          landmark: addressData['landmark'] ?? '',
          pinCode: addressData['pinCode'] ?? '',
          latitude: (addressData['latitude'] ?? 0.0).toDouble(),
          longitude: (addressData['longitude'] ?? 0.0).toDouble(),
          fullAddress: addressData['fullAddress'] ?? '',
          instructions: addressData['instructions'],
          street: '',
          city: '',
        );
      } catch (e) {
        print('⚠️ Error parsing delivery address: $e');
        // Create a fallback address
        deliveryAddress = DetailedAddress(
          houseNumber: '',
          landmark: '',
          pinCode: '',
          latitude: 0.0,
          longitude: 0.0,
          fullAddress: 'Address not available',
          instructions: null,
          street: '',
          city: '',
        );
      }

      // Parse items with error handling
      List<OrderItem> items = [];
      try {
        final itemsData = data['items'] as List<dynamic>? ?? [];
        items =
            itemsData
                .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
                .toList();
      } catch (e) {
        print('⚠️ Error parsing items: $e');
        items = [];
      }

      final order = Order(
        id: doc.id,
        customerId: data['customerId'] ?? '',
        customerName: data['customerName'] ?? '',
        customerPhone: data['customerPhone'] ?? '',
        items: items,
        totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
        status: _parseOrderStatus(data['status']),
        deliveryAddress: deliveryAddress,
        orderDate:
            (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        deliveryDate:
            (data['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        notes: data['notes'],
        paymentMethod: data['paymentMethod'],
        paymentId: data['paymentId'],
        deliverySlot: data['deliverySlot'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      );

      print('✅ Successfully parsed order: ${order.id}');
      return order;
    } catch (e) {
      print('❌ Error parsing order ${doc.id}: $e');
      rethrow;
    }
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DetailedAddress? deliveryAddress,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? notes,
    String? paymentMethod,
    String? paymentId,
    String? deliverySlot,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
