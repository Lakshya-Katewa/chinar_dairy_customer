import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum TransactionType { credit, debit }

class Transaction {
  final String id;
  final String customerId;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: TransactionType.values[data['type'] ?? 0],
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'amount': amount,
      'type': type.index,
      'description': description,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}
