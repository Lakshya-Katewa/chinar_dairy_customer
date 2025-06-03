import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum SubscriptionType { monthly, weekly, alternateDay }

class Subscription {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String productId;
  final String productName;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double quantity;
  final double pricePerUnit;
  final String areaCode;
  final String address;

  Subscription({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.productId,
    required this.productName,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.quantity,
    required this.pricePerUnit,
    required this.areaCode,
    required this.address,
  });

  factory Subscription.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: SubscriptionType.values[data['type'] ?? 0],
      startDate: (data['startDate'] as firestore.Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as firestore.Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      quantity: (data['quantity'] ?? 0).toDouble(),
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      areaCode: data['areaCode'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'productId': productId,
      'productName': productName,
      'type': type.index,
      'startDate': firestore.Timestamp.fromDate(startDate),
      'endDate': endDate != null ? firestore.Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'areaCode': areaCode,
      'address': address,
    };
  }

  String get typeText {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Monthly';
      case SubscriptionType.weekly:
        return 'Weekly';
      case SubscriptionType.alternateDay:
        return 'Alternate Day';
    }
  }

  int get deliveryCount {
    switch (type) {
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.weekly:
        return 7;
      case SubscriptionType.alternateDay:
        return 15;
    }
  }

  bool shouldDeliverToday() {
    final today = DateTime.now();
    final daysDifference = today.difference(startDate).inDays;

    if (daysDifference < 0 || !isActive) return false;

    switch (type) {
      case SubscriptionType.monthly:
        return daysDifference < 30;
      case SubscriptionType.weekly:
        return daysDifference < 7;
      case SubscriptionType.alternateDay:
        return daysDifference < 30 && daysDifference % 2 == 0;
    }
  }
}
